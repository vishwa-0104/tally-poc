import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { requireAuth, canAccessCompany } from '../middleware/auth'

export const billsRouter = Router()

billsRouter.use(requireAuth)

// GET /api/companies/:companyId/bills
billsRouter.get('/companies/:companyId/bills', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.companyId))) { res.status(403).json({ error: 'Forbidden' }); return }

  const bills = await prisma.bill.findMany({
    where: { companyId: req.params.companyId },
    include: { lineItems: true },
    orderBy: { createdAt: 'desc' },
  })

  res.json(bills.map(normalizeBill))
})

// GET /api/bills/:id
billsRouter.get('/bills/:id', async (req, res) => {
  const bill = await prisma.bill.findUnique({ where: { id: req.params.id }, include: { lineItems: true } })
  if (!bill) { res.status(404).json({ error: 'Not found' }); return }
  if (!(await canAccessCompany(req.auth, bill.companyId))) { res.status(403).json({ error: 'Forbidden' }); return }
  res.json(normalizeBill(bill))
})

// POST /api/companies/:companyId/bills
billsRouter.post('/companies/:companyId/bills', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.companyId))) { res.status(403).json({ error: 'Forbidden' }); return }

  const { lineItems, ...billData } = req.body

  const bill = await prisma.bill.create({
    data: {
      ...billData,
      companyId: req.params.companyId,
      status: (billData.status as string)?.toUpperCase() ?? 'PARSED',
      lineItems: { create: lineItems ?? [] },
    },
    include: { lineItems: true },
  })

  res.status(201).json(normalizeBill(bill))
})

// PUT /api/bills/:id
billsRouter.put('/bills/:id', async (req, res) => {
  const existing = await prisma.bill.findUnique({ where: { id: req.params.id } })
  if (!existing) { res.status(404).json({ error: 'Not found' }); return }
  if (!(await canAccessCompany(req.auth, existing.companyId))) { res.status(403).json({ error: 'Forbidden' }); return }

  const { lineItems, ...body } = req.body

  // Only pick schema-updatable fields — never pass id/companyId/createdAt/updatedAt to Prisma
  const updatable = [
    'billNumber', 'vendorName', 'vendorGstin', 'buyerGstin', 'billDate',
    'subtotal', 'cgstAmount', 'sgstAmount', 'igstAmount', 'totalAmount',
    'imageUrl', 'originalData', 'isEdited', 'rawAiJson',
    'tallyXml', 'tallyMapping', 'roundOffAmount', 'invoiceDiscountAmount', 'syncError', 'billType', 'extraCharges',
  ] as const
  const safeData: Record<string, unknown> = {}
  for (const key of updatable) {
    if (key in body) safeData[key] = body[key]
  }
  safeData.status   = (body.status as string)?.toUpperCase() ?? existing.status
  if (body.syncedAt) safeData.syncedAt = new Date(body.syncedAt as string)

  console.log(`[PUT /bills/${req.params.id}] status=${safeData.status} lineItems=${lineItems?.length ?? 'none'}`)

  const bill = await prisma.bill.update({
    where: { id: req.params.id },
    data: {
      ...safeData,
      ...(lineItems && {
        lineItems: {
          deleteMany: {},
          // Strip both `id` (lineItem PK) and `billId` (FK set by Prisma via the
          // nesting relation — passing it explicitly causes an "Unknown argument" error).
          create: lineItems.map(({ id: _id, billId: _billId, ...item }: { id?: string; billId?: string } & Record<string, unknown>) => item),
        },
      }),
    },
    include: { lineItems: true },
  })

  console.log(`[PUT /bills/${req.params.id}] saved status=${bill.status}`)
  res.json(normalizeBill(bill))
})

// DELETE /api/bills/:id
billsRouter.delete('/bills/:id', async (req, res) => {
  const existing = await prisma.bill.findUnique({ where: { id: req.params.id } })
  if (!existing) { res.status(404).json({ error: 'Not found' }); return }
  if (!(await canAccessCompany(req.auth, existing.companyId))) { res.status(403).json({ error: 'Forbidden' }); return }

  await prisma.bill.delete({ where: { id: req.params.id } })
  res.status(204).send()
})

const GEMINI_MODELS    = ['gemini-flash-latest', 'gemini-flash-lite-latest', 'gemini-3.1-flash', 'gemini-2.0-flash']
const ANTHROPIC_MODELS = ['claude-haiku-4-5-20251001', 'claude-sonnet-4-6', 'claude-opus-4-7']

// POST /api/bills/parse — AI parse a bill image/PDF
billsRouter.post('/bills/parse', async (req, res) => {
  const { base64, mediaType, billType, companyId } = req.body as {
    base64: string; mediaType: string; billType?: string; companyId?: string
  }
  let parseService = 'gemini'
  let model        = 'gemini-flash-latest'

  // Quota enforcement
  if (companyId) {
    if (!(await canAccessCompany(req.auth, companyId))) {
      res.status(403).json({ error: 'Forbidden' }); return
    }
    const company = await prisma.company.findUnique({
      where: { id: companyId },
      select: { parseBlocked: true, parseBillsLimit: true, parseBillsUsed: true, subscriptionExpiresAt: true, parseService: true, parseModel: true },
    })
    if (!company) { res.status(404).json({ error: 'Company not found' }); return }

    if (company.parseBlocked) {
      res.status(403).json({ error: 'PARSE_BLOCKED', message: 'Bill parsing has been disabled for your account. Please contact your administrator.' }); return
    }
    if (company.subscriptionExpiresAt && company.subscriptionExpiresAt < new Date()) {
      res.status(402).json({ error: 'SUBSCRIPTION_EXPIRED', message: 'Your subscription has expired. Please contact your administrator to renew.' }); return
    }
    if (company.parseBillsUsed >= company.parseBillsLimit) {
      res.status(429).json({ error: 'PARSE_LIMIT_EXCEEDED', limit: company.parseBillsLimit, used: company.parseBillsUsed, message: `Your parse limit of ${company.parseBillsLimit} bills has been reached this month. Please contact your administrator to upgrade your plan.` }); return
    }

    parseService = company.parseService ?? 'gemini'
    const dbModel = company.parseModel ?? ''
    // Use DB model only when it matches the configured service
    if (parseService === 'gemini' && GEMINI_MODELS.includes(dbModel))            model = dbModel
    else if (parseService === 'anthropic' && ANTHROPIC_MODELS.includes(dbModel)) model = dbModel
    else model = parseService === 'anthropic' ? 'claude-haiku-4-5-20251001' : 'gemini-flash-latest'
  }

  const isMiscBill = billType === 'misc'
  const prompt = parseService === 'gemini'
    ? (isMiscBill ? GEMINI_MISC_PARSE_PROMPT : GEMINI_PARSE_PROMPT)
    : (isMiscBill ? MISC_PARSE_PROMPT        : PARSE_PROMPT)

  const apiKey = parseService === 'anthropic'
    ? process.env.ANTHROPIC_API_KEY
    : process.env.GEMINI_API_KEY

  if (!apiKey) {
    res.status(503).json({
      error: 'SERVICE_UNAVAILABLE',
      message: 'We\'re sorry for the inconvenience. The bill parsing service is currently unavailable. Please try again later or contact support.',
    })
    return
  }

  interface ParsedUsage {
    input_tokens: number
    output_tokens: number
    cache_read_input_tokens?: number
    cache_creation_input_tokens?: number
  }

  let text: string
  let usage: ParsedUsage
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let rawUsage: any = null

  if (parseService === 'gemini') {
    let geminiRes: Response
    try {
      geminiRes = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            system_instruction: { parts: [{ text: prompt }] },
            contents: [{ role: 'user', parts: [{ inline_data: { mime_type: mediaType, data: base64 } }] }],
            generationConfig: { maxOutputTokens: 8192, responseMimeType: 'application/json' },
          }),
        }
      )
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Network error'
      res.status(503).json({ error: 'Could not reach Gemini API. Check internet connectivity.', details: msg })
      return
    }

    if (!geminiRes.ok) {
      const err = await geminiRes.json().catch(() => ({}))
      if (companyId) {
        prisma.parseUsageLog.create({
          data: { companyId, model, inputTokens: 0, outputTokens: 0, cacheRead: 0, cacheWrite: 0, success: false },
        }).catch(() => {})
      }
      res.status(geminiRes.status).json({ error: 'Gemini API error', details: err })
      return
    }

    const geminiData = await geminiRes.json() as {
      candidates: Array<{ content: { parts: Array<{ text: string }> } }>
      usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number; thoughtsTokenCount?: number }
      modelVersion?: string
    }
    const thinkingTokens = geminiData.usageMetadata?.thoughtsTokenCount ?? 0
    console.log(">>>>>>>>>>>>>>>>>>>>>>>")
    console.log(
      `[Gemini] model=${geminiData.modelVersion ?? model}`,
      `| input=${geminiData.usageMetadata?.promptTokenCount ?? 0}`,
      `| output=${geminiData.usageMetadata?.candidatesTokenCount ?? 0}`,
      `| thinking=${thinkingTokens}`,
      `| total=${(geminiData.usageMetadata?.promptTokenCount ?? 0) + (geminiData.usageMetadata?.candidatesTokenCount ?? 0) + thinkingTokens}`,
    )
    console.log(">>>>>>>>>>>>>>>>>>>>>>>")
    rawUsage = geminiData.usageMetadata ?? null
    text  = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    usage = {
      input_tokens:  geminiData.usageMetadata?.promptTokenCount    ?? 0,
      output_tokens: (geminiData.usageMetadata?.candidatesTokenCount ?? 0) + thinkingTokens,
    }
  } else {
    // Anthropic
    const contentBlock = mediaType === 'application/pdf'
      ? { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: base64 } }
      : { type: 'image',    source: { type: 'base64', media_type: mediaType,          data: base64 } }

    let anthropicRes: Response
    try {
      anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-beta': 'prompt-caching-2024-07-31',
        },
        body: JSON.stringify({
          model,
          max_tokens: 2000,
          system: [{ type: 'text', text: prompt, cache_control: { type: 'ephemeral' } }],
          messages: [{ role: 'user', content: [contentBlock] }],
        }),
      })
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Network error'
      res.status(503).json({ error: 'Could not reach Anthropic API. Check internet connectivity.', details: msg })
      return
    }

    if (!anthropicRes.ok) {
      const err = await anthropicRes.json().catch(() => ({}))
      if (companyId) {
        prisma.parseUsageLog.create({
          data: { companyId, model, inputTokens: 0, outputTokens: 0, cacheRead: 0, cacheWrite: 0, success: false },
        }).catch(() => {})
      }
      res.status(anthropicRes.status).json({ error: 'AI API error', details: err })
      return
    }

    const anthropicData = await anthropicRes.json() as {
      content: Array<{ type: string; text: string }>
      usage: { input_tokens: number; output_tokens: number; cache_read_input_tokens?: number; cache_creation_input_tokens?: number }
    }
    rawUsage = anthropicData.usage ?? null
    text  = anthropicData.content.find((b) => b.type === 'text')?.text ?? ''
    usage = anthropicData.usage ?? {}
  }

  try {
    // Gemini with responseMimeType returns raw JSON; Claude wraps in ```json``` fences.
    // Try direct parse first, fall back to fence extraction.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let parsed: any
    try {
      parsed = JSON.parse(text.trim())
    } catch {
      const fenced = text.match(/```json\s*([\s\S]*?)```/)
      const jsonStr = fenced ? fenced[1] : text.slice(text.indexOf('{'), text.lastIndexOf('}') + 1)
      parsed = JSON.parse(jsonStr)
    }

    // Correct sign of roundOffAmount:
    //   expected = totalAmount + invoiceDiscount − (subtotal + taxes)
    // Discount is on the credit side (like party), so it must be added back.
    // Bills print round-off as absolute; the AI may return +0.50 when direction is negative.
    let roundOffAmount: number | null = parsed.roundOffAmount ?? null
    if (roundOffAmount != null && roundOffAmount !== 0) {
      const base     = (parsed.subtotal ?? 0) + (parsed.cgstAmount ?? 0) + (parsed.sgstAmount ?? 0) + (parsed.igstAmount ?? 0)
      const expected = parseFloat(((parsed.totalAmount ?? 0) + (parsed.invoiceDiscountAmount ?? 0) - base).toFixed(2))
      // Use computed value only when it matches the AI magnitude (within ±0.05)
      if (Math.abs(Math.abs(expected) - Math.abs(roundOffAmount)) < 0.05) {
        roundOffAmount = expected
      }
    }

    // Increment parse counter and log usage after successful AI parse
    if (companyId) {
      await prisma.company.update({
        where: { id: companyId },
        data: { parseBillsUsed: { increment: 1 } },
      }).catch(() => {})
      prisma.parseUsageLog.create({
        data: {
          companyId,
          model,
          inputTokens:  usage.input_tokens ?? 0,
          outputTokens: usage.output_tokens ?? 0,
          cacheRead:    usage.cache_read_input_tokens ?? 0,
          cacheWrite:   usage.cache_creation_input_tokens ?? 0,
          success: true,
          rawUsage,
        },
      }).catch(() => {})
    }

    res.json({
      ...parsed,
      roundOffAmount,
      invoiceDiscountAmount: parsed.invoiceDiscountAmount ?? null,
      extraCharges: (parsed.extraCharges ?? []).map((ec: Record<string, unknown>) => ({
        description: ec.description ?? '',
        amount: Number(ec.amount ?? 0),
      })),
      lineItems: (parsed.lineItems ?? []).map((item: Record<string, unknown>) => ({
        ...item,
        hsnCode: item.hsnCode ?? '',
        discountPercent: item.discountPercent ?? null,
        discountAmount: item.discountAmount ?? null,
      })),
    })
  } catch {
    res.status(500).json({ error: 'Failed to parse AI response as JSON', raw: text })
  }
})

// POST /api/bank/parse — parse bank statement image/PDF via AI
billsRouter.post('/bank/parse', async (req, res) => {
  const { base64, mediaType, companyId: bodyCompanyId } = req.body as {
    base64: string; mediaType: string; companyId?: string
  }

  // Resolve companyId: trust body if provided, otherwise look up from the auth'd user's linked company
  let companyId: string | null = bodyCompanyId || null
  if (!companyId && req.auth.role !== 'ADMIN') {
    const link = await prisma.userCompany.findFirst({
      where:  { userId: req.auth.userId },
      select: { companyId: true },
    })
    companyId = link?.companyId ?? null
  }

  const geminiKey    = process.env.GEMINI_API_KEY
  const anthropicKey = process.env.ANTHROPIC_API_KEY

  if (!geminiKey && !anthropicKey) {
    res.json(MOCK_BANK_STATEMENT())
    return
  }

  // Respect the model/service configured per company in admin panel
  let parseService = geminiKey ? 'gemini' : 'anthropic'
  let model        = parseService === 'gemini' ? 'gemini-flash-latest' : 'claude-haiku-4-5-20251001'
  if (companyId) {
    const company = await prisma.company.findUnique({
      where:  { id: companyId },
      select: { parseService: true, parseModel: true },
    })
    if (company) {
      parseService = company.parseService ?? parseService
      const dbModel = company.parseModel ?? ''
      if (parseService === 'gemini' && GEMINI_MODELS.includes(dbModel))            model = dbModel
      else if (parseService === 'anthropic' && ANTHROPIC_MODELS.includes(dbModel)) model = dbModel
      else model = parseService === 'anthropic' ? 'claude-haiku-4-5-20251001' : 'gemini-flash-latest'
    }
  }

  const apiKey = parseService === 'anthropic' ? anthropicKey! : geminiKey!
  const prompt = parseService === 'anthropic' ? BANK_PARSE_PROMPT_ANTHROPIC : BANK_PARSE_PROMPT_GEMINI

  interface ParsedUsage {
    input_tokens: number; output_tokens: number
    cache_read_input_tokens?: number; cache_creation_input_tokens?: number
  }

  let text: string
  let usage: ParsedUsage
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let rawUsage: any = null

  console.log(`[BankParse] companyId=${companyId ?? 'none'} model=${model} mediaType=${mediaType}`)

  if (parseService === 'gemini') {
    const r = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: prompt }] },
          contents: [{ role: 'user', parts: [{ inline_data: { mime_type: mediaType, data: base64 } }] }],
          generationConfig: { maxOutputTokens: 8192, responseMimeType: 'application/json' },
        }),
      },
    )
    if (!r.ok) {
      if (companyId) prisma.parseUsageLog.create({
        data: { companyId, model, inputTokens: 0, outputTokens: 0, cacheRead: 0, cacheWrite: 0, success: false },
      }).catch((e) => console.error('[BankParse] usage log error:', e))
      res.status(r.status).json({ error: 'Gemini API error' }); return
    }
    const d = await r.json() as {
      candidates: Array<{ content: { parts: Array<{ text: string }> } }>
      usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number; thoughtsTokenCount?: number }
    }
    const thinkingTokens = d.usageMetadata?.thoughtsTokenCount ?? 0
    rawUsage = d.usageMetadata ?? null
    text  = d.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    usage = {
      input_tokens:  d.usageMetadata?.promptTokenCount ?? 0,
      output_tokens: (d.usageMetadata?.candidatesTokenCount ?? 0) + thinkingTokens,
    }
    console.log(`[BankParse] Gemini | input=${usage.input_tokens} output=${usage.output_tokens} thinking=${thinkingTokens}`)
  } else {
    const contentBlock = mediaType === 'application/pdf'
      ? { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: base64 } }
      : { type: 'image',    source: { type: 'base64', media_type: mediaType,          data: base64 } }
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
      body: JSON.stringify({ model, max_tokens: 4096, system: prompt, messages: [{ role: 'user', content: [contentBlock] }] }),
    })
    if (!r.ok) {
      if (companyId) prisma.parseUsageLog.create({
        data: { companyId, model, inputTokens: 0, outputTokens: 0, cacheRead: 0, cacheWrite: 0, success: false },
      }).catch((e) => console.error('[BankParse] usage log error:', e))
      res.status(r.status).json({ error: 'Anthropic API error' }); return
    }
    const d = await r.json() as {
      content: Array<{ type: string; text: string }>
      usage: ParsedUsage
    }
    rawUsage = d.usage ?? null
    text  = d.content.find((b) => b.type === 'text')?.text ?? ''
    usage = d.usage ?? { input_tokens: 0, output_tokens: 0 }
    console.log(`[BankParse] Anthropic | input=${usage.input_tokens} output=${usage.output_tokens} cacheRead=${usage.cache_read_input_tokens ?? 0}`)
  }

  try {
    let parsed: Record<string, unknown>
    try { parsed = JSON.parse(text.trim()) }
    catch {
      const fenced = text.match(/```json\s*([\s\S]*?)```/)
      const jsonStr = fenced ? fenced[1] : text.slice(text.indexOf('{'), text.lastIndexOf('}') + 1)
      parsed = JSON.parse(jsonStr)
    }
    if (companyId) {
      await prisma.parseUsageLog.create({
        data: {
          companyId,
          model,
          inputTokens:  usage.input_tokens ?? 0,
          outputTokens: usage.output_tokens ?? 0,
          cacheRead:    usage.cache_read_input_tokens ?? 0,
          cacheWrite:   usage.cache_creation_input_tokens ?? 0,
          success:      true,
          rawUsage,
        },
      })
      console.log(`[BankParse] usage logged — companyId=${companyId} success=true`)
    } else {
      console.warn('[BankParse] no companyId — usage not logged')
    }
    res.json(parsed)
  } catch {
    res.status(500).json({ error: 'Failed to parse AI response', raw: text })
  }
})

const BANK_PARSE_PROMPT_GEMINI = `Extract all transactions from this bank statement and return ONLY a raw JSON object — no markdown, no code fences.

Field conventions:
- "debit": amount from the bank statement's CREDIT column (money received / deposited into account). null if not a deposit.
- "credit": amount from the bank statement's DEBIT column (money withdrawn / paid from account). null if not a withdrawal.

Return this exact JSON structure:
{
  "bankName": string,
  "accountNumber": string | null,
  "transactions": [
    {
      "date": "YYYY-MM-DD",
      "description": string,
      "debit": number | null,
      "credit": number | null,
      "balance": number | null
    }
  ]
}

Rules:
- Dates must be in YYYY-MM-DD format.
- Numbers must not include commas (e.g., 1450.50 not 1,450.50).
- Preserve original transaction descriptions exactly as shown in the statement.
- Skip header/footer rows that are not actual transactions.`

const BANK_PARSE_PROMPT_ANTHROPIC = `Extract all transactions from this bank statement and return a single JSON object wrapped in \`\`\`json ... \`\`\`.

Field conventions:
- "debit": amount from the bank statement's CREDIT column (money received / deposited into account). null if not a deposit.
- "credit": amount from the bank statement's DEBIT column (money withdrawn / paid from account). null if not a withdrawal.

\`\`\`json
{
  "bankName": string,
  "accountNumber": string | null,
  "transactions": [{ "date": "YYYY-MM-DD", "description": string, "debit": number | null, "credit": number | null, "balance": number | null }]
}
\`\`\`

Rules: Dates in YYYY-MM-DD. Numbers without commas. Preserve descriptions exactly. Skip header/footer rows.`

// POST /api/reconcile/analyze — AI-powered reconciliation summary (text-only)
billsRouter.post('/reconcile/analyze', async (req, res) => {
  const { companyId: bodyCompanyId, bankName, booksName, missingFromBooks, extraInBooks } = req.body as {
    companyId?: string
    bankName: string
    booksName: string
    missingFromBooks: Array<{ date: string; description: string; debit: number | null; credit: number | null }>
    extraInBooks:     Array<{ date: string; description: string; debit: number | null; credit: number | null }>
  }

  let companyId: string | null = bodyCompanyId || null
  if (!companyId && req.auth.role !== 'ADMIN') {
    const link = await prisma.userCompany.findFirst({
      where:  { userId: req.auth.userId },
      select: { companyId: true },
    })
    companyId = link?.companyId ?? null
  }

  const geminiKey    = process.env.GEMINI_API_KEY
  const anthropicKey = process.env.ANTHROPIC_API_KEY

  if (!geminiKey && !anthropicKey) {
    res.json({ summary: MOCK_RECONCILE_SUMMARY(bankName, booksName, missingFromBooks.length, extraInBooks.length) })
    return
  }

  let parseService = geminiKey ? 'gemini' : 'anthropic'
  let model        = parseService === 'gemini' ? 'gemini-flash-latest' : 'claude-haiku-4-5-20251001'
  if (companyId) {
    const company = await prisma.company.findUnique({
      where:  { id: companyId },
      select: { parseService: true, parseModel: true },
    })
    if (company) {
      parseService = company.parseService ?? parseService
      const dbModel = company.parseModel ?? ''
      if (parseService === 'gemini' && GEMINI_MODELS.includes(dbModel))            model = dbModel
      else if (parseService === 'anthropic' && ANTHROPIC_MODELS.includes(dbModel)) model = dbModel
      else model = parseService === 'anthropic' ? 'claude-haiku-4-5-20251001' : 'gemini-flash-latest'
    }
  }

  const apiKey = parseService === 'anthropic' ? anthropicKey! : geminiKey!

  const fmtRows = (rows: typeof missingFromBooks) =>
    rows.map((r, i) =>
      `  ${i + 1}. ${r.date} | ${r.description} | Received: ${r.debit ?? 0} | Paid: ${r.credit ?? 0}`
    ).join('\n')

  const promptText = `You are an accounting assistant. A company has compared their bank statement ("${bankName}") against their books ("${booksName}"). Analyze the discrepancies and provide a clear, concise reconciliation summary.

MISSING FROM BOOKS (${missingFromBooks.length} entries — present in bank but absent in books):
${missingFromBooks.length > 0 ? fmtRows(missingFromBooks) : '  None'}

EXTRA IN BOOKS (${extraInBooks.length} entries — present in books but absent in bank statement):
${extraInBooks.length > 0 ? fmtRows(extraInBooks) : '  None'}

Please provide:
1. A brief overview of the discrepancy (1-2 sentences)
2. The net amount missing from books (sum of received and paid for missing entries)
3. The net amount extra in books (sum of received and paid for extra entries)
4. What journal entries or corrections would be needed to reconcile the books with the bank
5. Any patterns you notice (e.g., duplicate entries, missed transactions, timing differences)
6. A final verdict: is this a minor or major discrepancy?

Be concise and practical. Use plain language. Format with clear section headings.`

  interface ParsedUsage { input_tokens: number; output_tokens: number; cache_read_input_tokens?: number; cache_creation_input_tokens?: number }
  let text: string
  let usage: ParsedUsage
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let rawUsage: any = null

  console.log(`[ReconcileAnalyze] companyId=${companyId ?? 'none'} model=${model}`)

  if (parseService === 'gemini') {
    const r = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: 'You are a helpful accounting assistant.' }] },
          contents: [{ role: 'user', parts: [{ text: promptText }] }],
          generationConfig: { maxOutputTokens: 2048 },
        }),
      },
    )
    if (!r.ok) {
      if (companyId) prisma.parseUsageLog.create({
        data: { companyId, model, inputTokens: 0, outputTokens: 0, cacheRead: 0, cacheWrite: 0, success: false },
      }).catch((e) => console.error('[ReconcileAnalyze] usage log error:', e))
      res.status(r.status).json({ error: 'Gemini API error' }); return
    }
    const d = await r.json() as {
      candidates: Array<{ content: { parts: Array<{ text: string }> } }>
      usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number; thoughtsTokenCount?: number }
    }
    const thinkingTokens = d.usageMetadata?.thoughtsTokenCount ?? 0
    rawUsage = d.usageMetadata ?? null
    text  = d.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    usage = { input_tokens: d.usageMetadata?.promptTokenCount ?? 0, output_tokens: (d.usageMetadata?.candidatesTokenCount ?? 0) + thinkingTokens }
  } else {
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
      body: JSON.stringify({ model, max_tokens: 2048, messages: [{ role: 'user', content: promptText }] }),
    })
    if (!r.ok) {
      if (companyId) prisma.parseUsageLog.create({
        data: { companyId, model, inputTokens: 0, outputTokens: 0, cacheRead: 0, cacheWrite: 0, success: false },
      }).catch((e) => console.error('[ReconcileAnalyze] usage log error:', e))
      res.status(r.status).json({ error: 'Anthropic API error' }); return
    }
    const d = await r.json() as { content: Array<{ type: string; text: string }>; usage: ParsedUsage }
    rawUsage = d.usage ?? null
    text  = d.content.find((b) => b.type === 'text')?.text ?? ''
    usage = d.usage ?? { input_tokens: 0, output_tokens: 0 }
  }

  if (companyId) {
    await prisma.parseUsageLog.create({
      data: {
        companyId,
        model,
        inputTokens:  usage.input_tokens ?? 0,
        outputTokens: usage.output_tokens ?? 0,
        cacheRead:    usage.cache_read_input_tokens ?? 0,
        cacheWrite:   usage.cache_creation_input_tokens ?? 0,
        success:      true,
        rawUsage,
      },
    }).catch((e) => console.error('[ReconcileAnalyze] usage log error:', e))
  }

  res.json({ summary: text })
})

function MOCK_RECONCILE_SUMMARY(bankName: string, booksName: string, missing: number, extra: number) {
  return `**Reconciliation Overview**
Comparing "${bankName}" (bank) against "${booksName}" (books) reveals ${missing} entries missing from books and ${extra} extra entries in books.

**Missing from Books (${missing} entries)**
These transactions appear in the bank statement but have not been recorded in the books. Total net impact requires recording these entries to bring books in line with the bank.

**Extra in Books (${extra} entries)**
These entries exist in the books but are absent from the bank statement. They may represent timing differences (cheques not yet cleared) or erroneous entries that need to be reversed.

**Recommended Corrections**
- For missing entries: create the corresponding journal entries in the books matching the bank dates and amounts.
- For extra entries: verify if these are outstanding cheques/transfers. If not, pass a reversal entry.

**Verdict**
${missing + extra === 0 ? 'Books are fully reconciled.' : missing + extra <= 5 ? 'Minor discrepancy — can be resolved quickly.' : 'Significant discrepancy — requires careful review before closing.'}`
}

// POST /api/cfo-suggestions — AI-generated CFO report from the company's
// full YTD KPI set: the 9 ratios (DSO/DIO/DPO/CCC/Current/Quick/ROCE/ROE/
// Debt-Equity) plus Performance-tab KPIs (sales, monthly trend, margins,
// cash position, top items/debtors, slow-moving stock, debtor balances —
// always YTD, see generateCfoSuggestions in Dashboard.tsx). Same
// dual-provider pattern as /reconcile/analyze above: Gemini Flash by
// default, per-company override, Anthropic fallback, mock fallback if
// neither key is configured.
//
// The AI only produces NARRATIVE text (executive summary, key action items,
// section commentaries, top risks) — never restates numbers. Tables
// (monthly sales, top items, top debtors, debtor balances, slow stock) are
// rendered client-side directly from the same kpis payload we send here, to
// avoid the model drifting/hallucinating on anything tabular.
const cfoSuggestionsBody = z.object({
  companyId: z.string().optional(),
  ratios: z.object({
    dso:          z.number().nullable(),
    dio:          z.number().nullable(),
    dpo:          z.number().nullable(),
    ccc:          z.number().nullable(),
    currentRatio: z.number().nullable(),
    quickRatio:   z.number().nullable(),
    roce:         z.number().nullable(),
    roe:          z.number().nullable(),
    debtEquity:   z.number().nullable(),
  }),
  kpis: z.object({
    totalSales:     z.number(),
    monthlySales:   z.array(z.object({ label: z.string(), amount: z.number() })),
    grossMargin:    z.number().nullable(),
    grossMarginPct: z.number().nullable(),
    ebitda:         z.number().nullable(),
    ebitdaPct:      z.number().nullable(),
    netProfit:      z.number().nullable(),
    netProfitPct:   z.number().nullable(),
    cashInHand:     z.number().nullable(),
    bankBalance:    z.number().nullable(),
    receivables:    z.number().nullable(),
    payables:       z.number().nullable(),
    topItems:       z.array(z.object({ name: z.string(), qty: z.number(), unit: z.string(), amount: z.number() })),
    topDebtors:     z.array(z.object({ name: z.string(), amount: z.number() })),
    slowStock:      z.array(z.object({ name: z.string(), lastSaleDate: z.string(), daysSince: z.number() })),
    debtorBalances: z.array(z.object({ name: z.string(), balance: z.number() })),
  }),
})

const cfoReportSchema = z.object({
  executiveSummary:           z.string(),
  keyActionItems:             z.array(z.string()).min(2).max(6),
  monthlySalesCommentary:     z.string(),
  marginTrendCommentary:      z.string(),
  workingCapitalCommentary:   z.string(),
  liquidityCommentary:        z.string(),
  cashPositionCommentary:     z.string(),
  capitalEfficiencyCommentary: z.string(),
  debtorPaymentCommentary:    z.string(),
  slowMovingCommentary:       z.string(),
  topRisks: z.array(z.object({
    title:    z.string(),
    body:     z.string(),
    severity: z.enum(['High', 'Medium', 'Low']),
  })).min(1).max(3),
})

billsRouter.post('/cfo-suggestions', async (req, res) => {
  const parsed = cfoSuggestionsBody.safeParse(req.body)
  if (!parsed.success) { res.status(400).json({ error: 'Invalid input' }); return }
  const { ratios, kpis } = parsed.data

  let companyId: string | null = parsed.data.companyId || null
  if (!companyId && req.auth.role !== 'ADMIN') {
    const link = await prisma.userCompany.findFirst({
      where:  { userId: req.auth.userId },
      select: { companyId: true },
    })
    companyId = link?.companyId ?? null
  }
  if (companyId && req.auth.role !== 'ADMIN' && !(await canAccessCompany(req.auth, companyId))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }

  const geminiKey    = process.env.GEMINI_API_KEY
  const anthropicKey = process.env.ANTHROPIC_API_KEY

  if (!geminiKey && !anthropicKey) {
    res.json(MOCK_CFO_REPORT())
    return
  }

  let parseService = geminiKey ? 'gemini' : 'anthropic'
  let model        = parseService === 'gemini' ? 'gemini-flash-latest' : 'claude-haiku-4-5-20251001'
  if (companyId) {
    const company = await prisma.company.findUnique({
      where:  { id: companyId },
      select: { parseService: true, parseModel: true },
    })
    if (company) {
      parseService = company.parseService ?? parseService
      const dbModel = company.parseModel ?? ''
      if (parseService === 'gemini' && GEMINI_MODELS.includes(dbModel))            model = dbModel
      else if (parseService === 'anthropic' && ANTHROPIC_MODELS.includes(dbModel)) model = dbModel
      else model = parseService === 'anthropic' ? 'claude-haiku-4-5-20251001' : 'gemini-flash-latest'
    }
  }

  const apiKey = parseService === 'anthropic' ? anthropicKey! : geminiKey!

  const fmt = (n: number | null | undefined, suffix = '') =>
    n == null ? 'not available' : `${n.toLocaleString('en-IN', { maximumFractionDigits: 1 })}${suffix}`

  const monthlySalesLines = kpis.monthlySales.length
    ? kpis.monthlySales.map(m => `  - ${m.label}: ${fmt(m.amount)}`).join('\n')
    : '  (no monthly data available)'
  const topItemsLines = kpis.topItems.length
    ? kpis.topItems.slice(0, 10).map(i => `  - ${i.name}: qty ${i.qty} ${i.unit}, ${fmt(i.amount)}`).join('\n')
    : '  (none)'
  const topDebtorsLines = kpis.topDebtors.length
    ? kpis.topDebtors.slice(0, 5).map(d => `  - ${d.name}: ${fmt(d.amount)} in sales YTD`).join('\n')
    : '  (none)'
  const debtorBalancesLines = kpis.debtorBalances.length
    ? kpis.debtorBalances.slice(0, 5).map(d => `  - ${d.name}: ${fmt(d.balance)} outstanding`).join('\n')
    : '  (none)'
  const slowStock90 = kpis.slowStock.filter(s => s.daysSince > 90)
  const slowStockLines = slowStock90.length
    ? slowStock90.slice(0, 15).map(s => `  - ${s.name}: ${s.daysSince} days since last sale`).join('\n')
    : '  (none over 90 days)'

  const promptText = `You are a CFO advisor reviewing a company's Year-to-Date (YTD) financial data. Based ONLY on the data below, produce a structured executive report. Do NOT restate the tables verbatim (they're already shown to the reader separately) — your job is to interpret them: trends, causes, comparisons, and what to do next. Reference specific numbers only when making a point, formatted in Indian units (₹3.2L, ₹1.2Cr).

RATIOS (YTD):
- DSO (Days Sales Outstanding): ${fmt(ratios.dso, ' days')}
- DIO (Days Inventory Outstanding): ${fmt(ratios.dio, ' days')}
- DPO (Days Payables Outstanding): ${fmt(ratios.dpo, ' days')}
- CCC (Cash Conversion Cycle, = DSO + DIO - DPO): ${fmt(ratios.ccc, ' days')}
- Current Ratio: ${fmt(ratios.currentRatio)}
- Quick Ratio: ${fmt(ratios.quickRatio)}
- ROCE: ${fmt(ratios.roce, '%')}
- ROE: ${fmt(ratios.roe, '%')}
- Debt/Equity: ${fmt(ratios.debtEquity)}

SALES & PROFITABILITY (YTD):
- Total Sales: ${fmt(kpis.totalSales)}
- Gross Margin: ${fmt(kpis.grossMargin)} (${fmt(kpis.grossMarginPct, '%')})
- EBITDA: ${fmt(kpis.ebitda)} (${fmt(kpis.ebitdaPct, '%')})
- Net Profit: ${fmt(kpis.netProfit)} (${fmt(kpis.netProfitPct, '%')})

MONTHLY SALES (YTD, Apr-to-date):
${monthlySalesLines}

CASH POSITION:
- Cash in Hand: ${fmt(kpis.cashInHand)}
- Bank Balance: ${fmt(kpis.bankBalance)}
- Receivables: ${fmt(kpis.receivables)}
- Payables: ${fmt(kpis.payables)}

TOP PERFORMING ITEMS (by sales value, YTD):
${topItemsLines}

TOP 5 DEBTORS BY SALES VALUE (YTD):
${topDebtorsLines}

TOP 5 OUTSTANDING DEBTOR BALANCES (as of now):
${debtorBalancesLines}

SLOW-MOVING STOCK (no sale in 90+ days):
${slowStockLines}

Respond with JSON ONLY (no markdown fences, no commentary) matching exactly this shape:
{
  "executiveSummary": "2-4 sentence overview of YTD performance",
  "keyActionItems": ["2-6 items for management, each formatted as 'Short Title: one to two sentence explanation of the action and why it matters'"],
  "monthlySalesCommentary": "1-3 sentences on the month-on-month trend — accelerating, seasonal, declining, why",
  "marginTrendCommentary": "1-3 sentences: is EBITDA/margin improving or declining, and why",
  "workingCapitalCommentary": "1-3 sentences analyzing CCC and whether working capital is balanced (a very high or negative CCC is worth flagging)",
  "liquidityCommentary": "1-3 sentences comparing Current vs Quick Ratio — is there enough short-term liquidity to cover current liabilities",
  "cashPositionCommentary": "1-2 sentences on Cash in Hand vs Bank Balance health",
  "capitalEfficiencyCommentary": "1-3 sentences on ROCE/ROE — how efficiently is capital generating returns",
  "debtorPaymentCommentary": "1-3 sentences comparing the top-5-by-sales list against the top-5-outstanding-balances list — are the biggest buyers paying on time, or are big revenue contributors also big overdue risks",
  "slowMovingCommentary": "1-3 sentences on the impact of the 90+ day slow stock list and what inventory action to prioritize",
  "topRisks": [{ "title": "short title", "body": "1-2 sentences", "severity": "High"|"Medium"|"Low" }] — exactly the 3 biggest financial risks visible in this data, ranked most severe first (fewer than 3 only if there genuinely aren't that many distinct risks)
}
If a section's underlying data is "not available" or empty, say so briefly rather than guessing a number.`

  interface ParsedUsage { input_tokens: number; output_tokens: number; cache_read_input_tokens?: number; cache_creation_input_tokens?: number }
  let text: string
  let usage: ParsedUsage
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let rawUsage: any = null

  console.log(`[CfoSuggestions] companyId=${companyId ?? 'none'} model=${model}`)

  try {
    if (parseService === 'gemini') {
      const r = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            system_instruction: { parts: [{ text: 'You are a helpful CFO advisor. You always respond with valid JSON only.' }] },
            contents: [{ role: 'user', parts: [{ text: promptText }] }],
            generationConfig: { maxOutputTokens: 4096, responseMimeType: 'application/json' },
          }),
        },
      )
      if (!r.ok) throw new Error(`Gemini API error ${r.status}`)
      const d = await r.json() as {
        candidates: Array<{ content: { parts: Array<{ text: string }> } }>
        usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number; thoughtsTokenCount?: number }
      }
      const thinkingTokens = d.usageMetadata?.thoughtsTokenCount ?? 0
      rawUsage = d.usageMetadata ?? null
      text  = d.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
      usage = { input_tokens: d.usageMetadata?.promptTokenCount ?? 0, output_tokens: (d.usageMetadata?.candidatesTokenCount ?? 0) + thinkingTokens }
    } else {
      const r = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
        body: JSON.stringify({ model, max_tokens: 4096, messages: [{ role: 'user', content: promptText }] }),
      })
      if (!r.ok) throw new Error(`Anthropic API error ${r.status}`)
      const d = await r.json() as { content: Array<{ type: string; text: string }>; usage: ParsedUsage }
      rawUsage = d.usage ?? null
      text  = d.content.find((b) => b.type === 'text')?.text ?? ''
      usage = d.usage ?? { input_tokens: 0, output_tokens: 0 }
    }

    const cleaned = text.trim().replace(/^```json\s*/i, '').replace(/^```\s*/, '').replace(/```\s*$/, '')
    const report = cfoReportSchema.parse(JSON.parse(cleaned))

    if (companyId) {
      prisma.parseUsageLog.create({
        data: {
          companyId, model,
          inputTokens:  usage.input_tokens ?? 0,
          outputTokens: usage.output_tokens ?? 0,
          cacheRead:    usage.cache_read_input_tokens ?? 0,
          cacheWrite:   usage.cache_creation_input_tokens ?? 0,
          success:      true,
          rawUsage,
        },
      }).catch((e) => console.error('[CfoSuggestions] usage log error:', e))
    }

    res.json(report)
  } catch (e) {
    console.error('[CfoSuggestions] failed, falling back to mock:', e)
    if (companyId) {
      prisma.parseUsageLog.create({
        data: { companyId, model, inputTokens: 0, outputTokens: 0, cacheRead: 0, cacheWrite: 0, success: false },
      }).catch((err) => console.error('[CfoSuggestions] usage log error:', err))
    }
    res.json(MOCK_CFO_REPORT())
  }
})

function MOCK_CFO_REPORT() {
  return {
    executiveSummary: 'Demo data — configure GEMINI_API_KEY or ANTHROPIC_API_KEY to get a real AI-generated report from your actual YTD figures.',
    keyActionItems: [
      'Follow Up on Overdue Receivables: Receivables aged above 60 days should be prioritized for collection to free up working capital.',
      'Review Slow-Moving Stock: Consider discounting or returning items to vendors that have not sold in over 90 days.',
      'Monitor EBITDA Margin Trend: Track the month-over-month margin trend to catch cost or pricing drift early.',
    ],
    monthlySalesCommentary: 'Demo: sales have trended upward over the last few months with one seasonal dip.',
    marginTrendCommentary: 'Demo: EBITDA margin improved slightly this year, driven by lower procurement costs.',
    workingCapitalCommentary: 'Demo: Cash Conversion Cycle suggests working capital is reasonably balanced, with inventory days the largest component.',
    liquidityCommentary: 'Demo: Current Ratio is healthy, but Quick Ratio is tighter — short-term liquidity excluding inventory is worth monitoring.',
    cashPositionCommentary: 'Demo: Bank balance comfortably exceeds cash-in-hand, indicating most funds are held in accounts rather than as cash on premises.',
    capitalEfficiencyCommentary: 'Demo: ROCE and ROE both point to reasonably efficient use of capital, though there is room to improve asset turnover.',
    debtorPaymentCommentary: 'Demo: some of the largest customers by sales value also carry large outstanding balances — worth reviewing payment terms with them.',
    slowMovingCommentary: 'Demo: a handful of items have not sold in over 90 days, tying up working capital that could be redeployed.',
    topRisks: [
      { title: 'Receivables Aging Risk', body: 'Outstanding receivables above 60 days have increased, tying up working capital.', severity: 'High' as const },
      { title: 'Inventory Overstocking', body: 'Several stock items have not moved in 90+ days.', severity: 'Medium' as const },
      { title: 'Customer Concentration', body: 'A large share of sales comes from a small number of customers.', severity: 'Medium' as const },
    ],
  }
}

function MOCK_BANK_STATEMENT() {
  return {
    bankName: 'State Bank of India',
    accountNumber: '1234567890',
    transactions: [
      { id: 'mock_1', date: new Date().toISOString().split('T')[0], description: 'NEFT - SUPPLIER PAYMENT', debit: null, credit: 50000, balance: 150000 },
      { id: 'mock_2', date: new Date().toISOString().split('T')[0], description: 'CASH DEPOSIT', debit: 25000, credit: null, balance: 175000 },
      { id: 'mock_3', date: new Date().toISOString().split('T')[0], description: 'CHEQUE CLEARING 001234', debit: null, credit: 15000, balance: 160000 },
    ],
  }
}

// Lowercase status to match frontend enum
function normalizeBill(bill: Record<string, unknown> & { status: string; lineItems?: unknown[] }) {
  return { ...bill, status: bill.status.toLowerCase() }
}

const GEMINI_PARSE_PROMPT = `Extract structured data from an Indian GST purchase bill (printed or handwritten) and return ONLY a raw JSON object — no markdown, no code fences, no explanation.

PARTIES
- vendorName/vendorGstin: the business that ISSUED the bill (top of bill, "From"/"Supplier"/"Sold by"). GSTIN is 15 chars near their name.
- buyerGstin: GSTIN in the "Bill to"/"Consignee" section. If ambiguous, assign to vendorGstin.

DISCOUNT PATTERN & MULTI-COLUMN LOGIC
- Pattern A (per-line): each line has Discount%. amount = Qty × unitPrice × (1 − disc%/100).
- Pattern B (invoice-level): lines show gross amounts, one discount deducted at bottom. amount = Qty × unitPrice × (subtotal / grossTotal).
- MULTI-COLUMN RULE: If an invoice has multiple discount columns (e.g., 'Payment Discount', 'Special Discount', 'Cash Disc'), lineItem.discountAmount MUST be the SUM of all these values for that specific line.

FIELD RULES
- lineItem.amount: This is the "Value Before Tax" or "Taxable Value" printed on the bill. NEVER include GST.
- lineItem.unitPrice: The original/gross rate per unit before any deductions.
- lineItem.discountAmount: The total ₹ value deducted from the line item. If multiple discount columns exist, sum them.
- lineItem.gstRate: The COMBINED GST percentage (CGST% + SGST% or IGST%).
- Verify: (qty × unitPrice) - lineItem.discountAmount === lineItem.amount.
- lineItem.unit: read from bill (Ltr/Kg/Pc/Pkt/Strip/Ctn/Nos/NOP). Default: "blank".

QUANTITY DISAMBIGUATIO
- Some bills (paint, chemical, liquid, packed goods) show multiple quantity-like columns: NOP (Number of Packages), "Qty Lt/Kg" (total volume/weight), Pack or Pack Size (volume per unit).
- STEP 1: Read the rate directly from the bill's "Rate" column — this is the original printed price per unit (e.g. ₹/Ltr, ₹/Kg, ₹/Can, ₹/Pkt, ₹/Strip, ₹/Ctn, ₹/NOP) BEFORE any discount. Store this as lineItem.unitPrice.
- STEP 2: The correct quantity is whichever candidate value satisfies: quantity = (lineItem.amount + lineItem.discountAmount) / lineItem.unitPrice
- IMPORTANT: Always use the rate read from the bill's Rate column in the denominator — never a derived or back-calculated price.
- Test each candidate (NOP, Qty Lt/Kg, Pack count, etc.) against this equation and use the one that matches.
- Set lineItem.unit to match the chosen quantity (e.g. "Nos"/"Drum"/"Can" for NOP; "Lt"/"Kg" for volume qty).
- in case of Berger Paints India Limited, Qty is always the NOP (Number of Packages) column, even if a "Qty Lt/Kg" column exists. This is an exception to the above rules based on observed billing patterns.

EXTRA CHARGES
- Some bills include additional charges outside the main item table (freight, insurance, loading, unloading, rakhsawa, auto charges, handling, cartage, octroi, etc.).
- These typically appear after the line items and before the GST row.
- Extract each such charge into extraCharges with its description and amount (pre-tax value).
- Do NOT include GST rows (CGST/SGST/IGST) or round-off in extraCharges.
- create input tags for these extra charges entry seperatly for all charges (pre-tax value) mentioned in the bill and do not club them together as one entry in extraCharges array. 
- If no extra charges exist, return [].

VERIFICATION & HIERARCHY
- The "Value Before Tax" printed on the invoice is the absolute truth for lineItem.amount.
- subtotal + sum(extraCharges.amount) + cgstAmount + sgstAmount + igstAmount + (roundOffAmount ?? 0) ≈ totalAmount.

NUMERIC RULES: dot = decimal (1.50 not 150), comma = thousands separator (1,450.50 → 1450.50). Copy numbers exactly. Missing optional fields → null.

Return this exact JSON structure:
{
  "vendorName": string,
  "vendorGstin": string | null,
  "buyerGstin": string | null,
  "billNumber": string,
  "billDate": "YYYY-MM-DD",
  "lineItems": [{ "description": string, "hsnCode": string | null, "quantity": number, "unit": string, "unitPrice": number, "discountPercent": number | null, "discountAmount": number | null, "gstRate": number, "amount": number }],
  "extraCharges": [{ "description": string, "amount": number }],
  "subtotal": number,
  "cgstAmount": number,
  "sgstAmount": number,
  "igstAmount": number,
  "totalAmount": number,
  "roundOffAmount": number | null,
  "invoiceDiscountAmount": number | null
}`

const GEMINI_MISC_PARSE_PROMPT = `Extract structured data from an Indian GST expense/misc bill (stationery, repairs, services, office supplies) and return ONLY a raw JSON object — no markdown, no code fences, no explanation.

- vendorName/vendorGstin: supplier name and 15-char GSTIN (or null).
- buyerGstin: buyer GSTIN from "Bill to" section or null.
- billNumber, billDate ("YYYY-MM-DD").
- lineItems: one per expense line. description = item name. amount = pre-tax amount (distribute proportionally if only bill-level tax shown). quantity=1, unit="Nos", unitPrice=amount, hsnCode="", gstRate=0, discountPercent=null.
- subtotal: sum of all lineItem amounts (pre-tax).
- cgstAmount/sgstAmount/igstAmount: from bill labels, 0 if absent.
- totalAmount: final grand total.
- roundOffAmount: null if absent.
- invoiceDiscountAmount: null.

VERIFY: subtotal + cgstAmount + sgstAmount + igstAmount + (roundOffAmount ?? 0) ≈ totalAmount

Return this exact JSON structure:
{
  "vendorName": string, "vendorGstin": string | null, "buyerGstin": string | null,
  "billNumber": string, "billDate": "YYYY-MM-DD",
  "lineItems": [{ "description": string, "amount": number, "quantity": 1, "unit": "Nos", "unitPrice": number, "hsnCode": "", "gstRate": 0, "discountPercent": null }],
  "subtotal": number, "cgstAmount": number, "sgstAmount": number, "igstAmount": number,
  "totalAmount": number, "roundOffAmount": number | null, "invoiceDiscountAmount": null
}`

const PARSE_PROMPT = `Extract structured data from an Indian GST purchase bill (printed or handwritten) and return a single JSON object wrapped in \`\`\`json ... \`\`\`.

PARTIES
- vendorName/vendorGstin: the business that ISSUED the bill (top of bill, "From"/"Supplier"/"Sold by"). GSTIN is 15 chars near their name.
- buyerGstin: GSTIN in the "Bill to"/"Consignee" section. If ambiguous, assign to vendorGstin.

DISCOUNT PATTERN & MULTI-COLUMN LOGIC
- Pattern A (per-line): each line has Discount%. amount = Qty × unitPrice × (1 − disc%/100).
- Pattern B (invoice-level): lines show gross amounts, one discount deducted at bottom. amount = Qty × unitPrice × (subtotal / grossTotal).
- MULTI-COLUMN RULE: If an invoice has multiple discount columns (e.g., 'Payment Discount', 'Special Discount', 'Cash Disc'), lineItem.discountAmount MUST be the SUM of all these values for that specific line. 

FIELD RULES
- lineItem.amount: This is the "Value Before Tax" or "Taxable Value" printed on the bill.  NEVER include GST.
- lineItem.unitPrice: The original/gross rate per unit before any deductions.
- lineItem.discountAmount: The total ₹ value deducted from the line item. If multiple discount columns exist, sum them.
- lineItem.gstRate: The COMBINED GST percentage (CGST% + SGST% or IGST%).
- Verify: (qty × unitPrice) - lineItem.discountAmount ≈ lineItem.amount.
- lineItem.unit: read from bill (Ltr/Kg/Pc/Pkt/Strip/Ctn/Nos).  Default: "blank".

TAX TYPE RULE (IGST vs CGST/SGST — mutually exclusive)
const interstate = bill has supplier and buyer in different states (state codes in GSTIN differ) → IGST applies.
- IGST applies to interstate supply; CGST+SGST applies to intra-state supply. A single bill NEVER has both non-zero.
- If the bill shows IGST amounts (even if CGST/SGST columns exist but show 0): set igstAmount = total IGST, cgstAmount = 0, sgstAmount = 0.
- If the bill shows CGST and SGST amounts (even if an IGST column exists but shows 0): set cgstAmount and sgstAmount to their values, igstAmount = 0.
- Columns printed as 0 mean absent — do NOT copy those 0s into cgstAmount/sgstAmount when IGST is the actual tax charged.
- lineItem.gstRate should equal the rate actually charged: IGST% for interstate, or CGST%+SGST% for intra-state.

QUANTITY DISAMBIGUATIO
- Some bills (paint, chemical, liquid, packed goods) show multiple quantity-like columns: NOP (Number of Packages), "Qty Lt/Kg" (total volume/weight), Pack or Pack Size (volume per unit).
- STEP 1: Read the rate directly from the bill's "Rate" column — this is the original printed price per unit (e.g. ₹/Ltr, ₹/Kg, ₹/Can, ₹/Pkt, ₹/Strip, ₹/Ctn, ₹/NOP) BEFORE any discount. Store this as lineItem.unitPrice.
- STEP 2: The correct quantity is whichever candidate value satisfies: quantity = (lineItem.amount + lineItem.discountAmount) / lineItem.unitPrice
- IMPORTANT: Always use the rate read from the bill's Rate column in the denominator — never a derived or back-calculated price.
- Test each candidate (NOP, Qty Lt/Kg, Pack count, etc.) against this equation and use the one that matches.
- Set lineItem.unit to match the chosen quantity (e.g. "Nos"/"Drum"/"Can" for NOP; "Lt"/"Kg" for volume qty).
- in case of Berger Paints India Limited, Qty is always the NOP (Number of Packages) column, even if a "Qty Lt/Kg" column exists. This is an exception to the above rules based on observed billing patterns.

EXTRA CHARGES
- Some bills include additional charges outside the main item table (freight, insurance, loading, unloading, rakhsawa, auto charges, handling, cartage, octroi, etc.).
- These typically appear after the line items and before the GST row.
- Extract each such charge into extraCharges with its description and amount (pre-tax value).
- Do NOT include GST rows (CGST/SGST/IGST) or round-off in extraCharges.
- create input tags for these extra charges entry seperatly for all charges (pre-tax value) mentioned in the bill and do not club them together as one entry in extraCharges array. 
- If no extra charges exist, return [].


VERIFICATION & HIERARCHY
- The "Value Before Tax" printed on the invoice is the absolute truth for lineItem.amount.
- subtotal + sum(extraCharges.amount) + cgstAmount + sgstAmount + igstAmount + (roundOffAmount ?? 0) ≈ totalAmount.

NUMERIC RULES: dot = decimal (1.50 not 150), comma = thousands separator (1,450.50 → 1450.50). Copy numbers exactly. Missing optional fields → null.

OUTPUT schema:
\`\`\`json
{
  "vendorName": string,
  "vendorGstin": string | null,
  "buyerGstin": string | null,
  "billNumber": string,
  "billDate": "YYYY-MM-DD",
  "lineItems": [{ "description": string, "hsnCode": string | null, "quantity": number, "unit": string, "unitPrice": number, "discountPercent": number | null, "discountAmount": number | null, "gstRate": number, "amount": number }],
  "extraCharges": [{ "description": string, "amount": number }],
  "subtotal": number,
  "cgstAmount": number,
  "sgstAmount": number,
  "igstAmount": number,
  "totalAmount": number,
  "roundOffAmount": number | null,
  "invoiceDiscountAmount": number | null
}
\`\`\``;


const MISC_PARSE_PROMPT = `Extract structured data from an Indian GST expense/misc bill (stationery, repairs, services, office supplies) and return a single JSON object wrapped in \`\`\`json ... \`\`\`.

- vendorName/vendorGstin: supplier name and 15-char GSTIN (or null).
- buyerGstin: buyer GSTIN from "Bill to" section or null.
- billNumber, billDate ("YYYY-MM-DD").
- lineItems: one per expense line. description = item name. amount = pre-tax amount (distribute proportionally if only bill-level tax shown). quantity=1, unit="Nos", unitPrice=amount, hsnCode="", gstRate=0, discountPercent=null.
- subtotal: sum of all lineItem amounts (pre-tax).
- cgstAmount/sgstAmount/igstAmount: from bill labels, 0 if absent.
- totalAmount: final grand total.
- roundOffAmount: null if absent.
- invoiceDiscountAmount: null.

VERIFY: subtotal + cgstAmount + sgstAmount + igstAmount + (roundOffAmount ?? 0) ≈ totalAmount

\`\`\`json
{
  "vendorName": string, "vendorGstin": string | null, "buyerGstin": string | null,
  "billNumber": string, "billDate": "YYYY-MM-DD",
  "lineItems": [{ "description": string, "amount": number, "quantity": 1, "unit": "Nos", "unitPrice": number, "hsnCode": "", "gstRate": 0, "discountPercent": null }],
  "subtotal": number, "cgstAmount": number, "sgstAmount": number, "igstAmount": number,
  "totalAmount": number, "roundOffAmount": number | null, "invoiceDiscountAmount": null
}
\`\`\``


