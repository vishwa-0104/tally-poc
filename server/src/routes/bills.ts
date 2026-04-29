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
    'tallyXml', 'tallyMapping', 'roundOffAmount', 'syncError', 'billType',
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

// POST /api/bills/parse — AI parse a bill image/PDF (Anthropic key stays server-side)
billsRouter.post('/bills/parse', async (req, res) => {
  const { base64, mediaType, billType, companyId } = req.body as {
    base64: string; mediaType: string; billType?: string; companyId?: string
  }
  const prompt = billType === 'misc' ? MISC_PARSE_PROMPT : PARSE_PROMPT

  const apiKey = process.env.ANTHROPIC_API_KEY

  // Return mock data if no API key configured (dev mode — skip quota)
  if (!apiKey) {
    await new Promise((r) => setTimeout(r, 2000))
    res.json(MOCK_PARSED_BILL())
    return
  }

  const ALLOWED_MODELS = ['claude-haiku-4-5-20251001', 'claude-sonnet-4-6', 'claude-opus-4-7']
  let model = 'claude-haiku-4-5-20251001'

  // Quota enforcement (real AI mode only)
  if (companyId) {
    if (!(await canAccessCompany(req.auth, companyId))) {
      res.status(403).json({ error: 'Forbidden' }); return
    }
    const company = await prisma.company.findUnique({
      where: { id: companyId },
      select: { parseBlocked: true, parseBillsLimit: true, parseBillsUsed: true, subscriptionExpiresAt: true, parseModel: true },
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
    if (company.parseModel && ALLOWED_MODELS.includes(company.parseModel)) {
      model = company.parseModel
    }
  }

  const contentBlock = mediaType === 'application/pdf'
    ? { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: base64 } }
    : { type: 'image',    source: { type: 'base64', media_type: mediaType,          data: base64 } }

  let response: Response
  try {
    response = await fetch('https://api.anthropic.com/v1/messages', {
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
        messages: [{ role: 'user', content: [
          { type: 'text', text: prompt, cache_control: { type: 'ephemeral' } },
          contentBlock,
        ]}],
      }),
    })
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Network error'
    res.status(503).json({ error: 'Could not reach Anthropic API. Check internet connectivity.', details: msg })
    return
  }

  if (!response.ok) {
    const err = await response.json().catch(() => ({}))
    if (companyId) {
      prisma.parseUsageLog.create({
        data: { companyId, model, inputTokens: 0, outputTokens: 0, cacheRead: 0, cacheWrite: 0, success: false },
      }).catch(() => {})
    }
    res.status(response.status).json({ error: 'AI API error', details: err })
    return
  }

  const data = await response.json() as {
    content: Array<{ type: string; text: string }>
    usage: { input_tokens: number; output_tokens: number; cache_read_input_tokens?: number; cache_creation_input_tokens?: number }
  }
  const text = data.content.find((b) => b.type === 'text')?.text ?? ''
  const usage = data.usage ?? {}

  try {
    const fenced = text.match(/```json\s*([\s\S]*?)```/)
    const jsonStr = fenced ? fenced[1] : text.slice(text.indexOf('{'), text.lastIndexOf('}') + 1)
    const parsed = JSON.parse(jsonStr)

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
      lineItems: (parsed.lineItems ?? []).map((item: Record<string, unknown>) => ({
        ...item,
        hsnCode: item.hsnCode ?? '',
        discountPercent: item.discountPercent ?? null,
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

const PARSE_PROMPT = `You are extracting structured data from an Indian GST purchase bill (may be handwritten or printed).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1 — Identify the parties
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- VENDOR / SELLER: the business that ISSUED the bill (name/logo at the top, labels like "From", "Supplier", "Sold by").
- BUYER: the business that RECEIVED the bill (labels like "Bill to", "Sold to", "Consignee").

GSTIN rules:
- vendorGstin: GSTIN of the VENDOR near their name/address, or under "GSTIN", "GST No", "Supplier GSTIN", "Our GSTIN".
- buyerGstin: GSTIN of the BUYER in the "Bill to" section, or under "Buyer GSTIN", "Your GSTIN", "Recipient GSTIN".
- Ambiguous GSTIN → assign to vendorGstin.
- Valid Indian GSTIN: 15 chars — 2-digit state code + 10-char PAN + entity type + Z + check digit.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 2 — Identify the bill's calculation pattern
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Indian GST bills use one of two patterns:

PATTERN A — Per-line discount + GST:
  Each line item has its own Qty, Unit Price, Discount %, Line Amount, GST %.
  Taxable amount per line = Qty × UnitPrice × (1 − Discount%/100)
  Subtotal (taxable value) = sum of all per-line taxable amounts.
  GST is applied per line or on the subtotal total.

PATTERN B — Invoice-level discount + GST:
  Lines show Qty, Unit Price, Gross Amount (= Qty × UnitPrice) with no per-line discount.
  A single discount is deducted from the gross total at the bottom of the bill.
  Subtotal (taxable value) = Gross Total − Invoice Discount.
  GST (CGST+SGST or IGST) is applied on the subtotal.
  Round-off (if any) is applied after tax to reach the final payable amount.

PATTERN C — Mixed (per-line + invoice-level discount):
  Some lines have individual discounts AND there is also an invoice-level discount at the bottom.
  Treat as Pattern B for invoiceDiscountAmount — extract the invoice-level discount amount.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 3 — Extract values
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▸ lineItem.amount — ALWAYS the tax-exclusive (pre-GST) amount for that line:
  • Pattern A: amount = Qty × unitPrice × (1 − discountPercent/100)
  • Pattern B (no per-line discount): amount = Qty × unitPrice × (subtotal / grossTotal)
    where grossTotal = sum of all (Qty × unitPrice) across lines
    and subtotal is the taxable value read from the bill.
    If there is no discount at all: amount = Qty × unitPrice.
  ⚠ NEVER include GST in lineItem.amount. The amount must be tax-exclusive.

▸ lineItem.unit — determine using this exact priority order:
  1. Dedicated column: a separate column in the line-items table for the unit of measure — may have any header ("Unit", "UOM", "U/M", "Pack", "Packing", etc.) or no header. Use the cell value for that row.
  2. Alongside quantity: a unit written directly next to the quantity value in the qty cell (e.g. "33 pc", "216 PCS", "10 Kg", "5 Bags").
  3. Inside description/name: if and only if no value was found in steps 1–2, look inside the item description or product name for a unit abbreviation (e.g. "Sugar 5 Kg Bag" → "Kg", "Ariel 1 Ltr" → "Ltr", "Pipe 200mm pkt" → "Pkt"). Extract only the unit word, not the quantity or rest of the name.
  4. Smart inference: if no unit is found anywhere on the bill for this line, infer the most appropriate standard unit from the product type or name:
     - Liquids / oils / beverages → "Ltr" or "Ml"
     - Grains / flour / sugar / powder by weight → "Kg"
     - Tablets / capsules / medicines → "Strip" or "Box"
     - Pipes / rods / bars / tubes → "Pc"
     - Packets / pouches / sachets → "Pkt"
     - Cartons / cases / bundles → "Ctn"
     - General items with no clear type → "blank"

▸ lineItem.discountPercent — per-line discount % only. Use null for Pattern B (discount is invoice-level).

▸ subtotal — read the "Taxable Value", "Net Amount before Tax", or "Taxable Amount" printed on the bill.
  This is the total of all tax-exclusive line amounts after any discount.
  VERIFY: sum of all lineItem.amount values should equal subtotal (within ±1 due to rounding).

▸ cgstAmount — read from labels "CGST", "C.GST", "Central GST", "Central Tax". Use 0 if not present.
▸ sgstAmount — read from labels "SGST", "S.GST", "State GST", "State Tax", "UTGST". Use 0 if not present.
▸ igstAmount — read from label "IGST". Use 0 if not present.
▸ roundOffAmount — read from "Round Off", "Rounding", "Rounded". Use null if not present.
▸ totalAmount — the final grand total payable (bottom-line number on the bill).
▸ invoiceDiscountAmount — the invoice-level (overall) discount deducted from the gross total:
  • Pattern A only (all discounts are per-line): set to null.
  • Pattern B or C (discount on overall/total amount exists): read the discount amount from the bill footer (labels like "Discount", "Trade Discount", "Special Discount", "Less Discount"). Use the rupee amount, not the percentage.
  • If no invoice-level discount is present: null.

VERIFY before outputting:
  subtotal + cgstAmount + sgstAmount + igstAmount + (roundOffAmount ?? 0) ≈ totalAmount
  Note: invoiceDiscountAmount is NOT added back here. subtotal is already the post-discount
  taxable value (for Pattern B/C: subtotal = grossTotal − invoiceDiscountAmount). The discount
  is embedded in subtotal, not a separate addend. If the equation does not balance, re-check
  that subtotal is the net-of-discount figure, not the gross total.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 4 — Output ONLY a valid JSON object
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Schema:
{
  "vendorName": string,
  "vendorGstin": string | null,
  "buyerGstin": string | null,
  "billNumber": string,
  "billDate": "YYYY-MM-DD",
  "lineItems": [
    {
      "description": string,
      "hsnCode": string | null,
      "quantity": number,
      "unit": string,           ← see unit rules below
      "unitPrice": number,
      "discountPercent": number | null,
      "gstRate": number,
      "amount": number          ← tax-exclusive, after any discount
    }
  ],
  "subtotal": number,           ← total taxable value (sum of line amounts, before GST)
  "cgstAmount": number,
  "sgstAmount": number,
  "igstAmount": number,
  "totalAmount": number,        ← final grand total including all taxes and round-off
  "roundOffAmount": number | null,
  "invoiceDiscountAmount": number | null  ← invoice-level discount amount; null if only per-line discounts or no discount
}

CRITICAL numeric rules:
- A dot (.) between digits is ALWAYS a decimal point — never drop it (e.g. "1.50" → 1.50, NOT 150).
- Commas are thousand separators (e.g. "1,450.50" → 1450.50).
- Do not round or truncate any value; copy numbers exactly as printed.
- If a field is not present on the bill, use null (not 0 for optional fields).

End your response with the JSON object wrapped in \`\`\`json ... \`\`\`.`


const MISC_PARSE_PROMPT = `You are extracting structured data from an Indian GST expense/misc bill (purchases not directly related to primary business inventory — e.g. stationery, printer, repairs, office supplies).

Extract the following fields and return ONLY a valid JSON object wrapped in \`\`\`json ... \`\`\`.

Rules:
- vendorName: name of the supplier
- vendorGstin: supplier GSTIN (15 chars) or null
- buyerGstin: buyer GSTIN or null
- billNumber: invoice/bill number
- billDate: "YYYY-MM-DD"
- lineItems: one entry per expense line on the bill. Each entry has:
  - description: expense item name (e.g. "Printer Paper A4", "HP Toner Cartridge")
  - amount: the pre-tax amount for this line (number). If tax is only at bill level, distribute proportionally.
  - quantity: 1 (default — not important for expense bills)
  - unit: "Nos" (default)
  - unitPrice: same as amount
  - hsnCode: "" (empty string)
  - gstRate: 0 (default — tax is captured at bill level)
  - discountPercent: null
- subtotal: total pre-tax amount (sum of all lineItem amounts)
- cgstAmount: CGST total (number, 0 if not present)
- sgstAmount: SGST total (number, 0 if not present)
- igstAmount: IGST total (number, 0 if not present)
- totalAmount: final grand total payable
- roundOffAmount: round off amount or null
- invoiceDiscountAmount: null

CRITICAL: subtotal + cgstAmount + sgstAmount + igstAmount + (roundOffAmount ?? 0) ≈ totalAmount

Schema:
{
  "vendorName": string,
  "vendorGstin": string | null,
  "buyerGstin": string | null,
  "billNumber": string,
  "billDate": "YYYY-MM-DD",
  "lineItems": [
    {
      "description": string,
      "amount": number,
      "quantity": 1,
      "unit": "Nos",
      "unitPrice": number,
      "hsnCode": "",
      "gstRate": 0,
      "discountPercent": null
    }
  ],
  "subtotal": number,
  "cgstAmount": number,
  "sgstAmount": number,
  "igstAmount": number,
  "totalAmount": number,
  "roundOffAmount": number | null,
  "invoiceDiscountAmount": null
}`

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

