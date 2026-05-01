import { Router } from 'express'
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

const GEMINI_MODELS    = ['gemini-flash-latest', 'gemini-3.1-flash', 'gemini-2.0-flash']
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

  // Return mock data if no API key configured (dev mode — skip quota)
  if (!apiKey) {
    await new Promise((r) => setTimeout(r, 2000))
    res.json(MOCK_PARSED_BILL())
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
      usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number }
    }
    text  = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    usage = {
      input_tokens:  geminiData.usageMetadata?.promptTokenCount    ?? 0,
      output_tokens: geminiData.usageMetadata?.candidatesTokenCount ?? 0,
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
- Verify: (qty × unitPrice) - lineItem.discountAmount ≈ lineItem.amount.
- lineItem.unit: read from bill (Ltr/Kg/Pc/Pkt/Strip/Ctn/Nos). Default: "blank".

EXTRA CHARGES
- Some bills include additional charges outside the main item table (freight, insurance, loading, unloading, rakhsawa, auto charges, handling, cartage, octroi, etc.).
- These typically appear after the line items and before the GST row.
- Extract each such charge into extraCharges with its description and amount (pre-tax value).
- Do NOT include GST rows (CGST/SGST/IGST) or round-off in extraCharges.
- If no extra charges exist, return [].
- subtotal = sum of lineItem amounts ONLY (do not include extra charges in subtotal).

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

EXTRA CHARGES
- Some bills include additional charges outside the main item table (freight, insurance, loading, unloading, rakhsawa, auto charges, handling, cartage, octroi, etc.).
- These typically appear after the line items and before the GST row.
- Extract each such charge into extraCharges with its description and amount (pre-tax value).
- Do NOT include GST rows (CGST/SGST/IGST) or round-off in extraCharges.
- If no extra charges exist, return [].
- subtotal = sum of lineItem amounts ONLY (do not include extra charges in subtotal).

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

function MOCK_PARSED_BILL() {
  return {
    vendorName: 'Agro Products Ltd',
    vendorGstin: '07AAGCA1234B1Z5',
    billNumber: 'APL/2025/' + Math.floor(Math.random() * 9000 + 1000),
    billDate: new Date().toISOString().split('T')[0],
    subtotal: 29600,
    cgstAmount: 800,
    sgstAmount: 800,
    igstAmount: 0,
    totalAmount: 31200,
    lineItems: [
      { description: 'Wheat Flour 50kg', hsnCode: '1101', quantity: 20, unit: 'BAG', unitPrice: 1400, gstRate: 0, amount: 28000 },
      { description: 'Semolina 50kg',    hsnCode: '1103', quantity: 4,  unit: 'BAG', unitPrice: 800,  gstRate: 5, amount: 3360  },
    ],
  }
}

