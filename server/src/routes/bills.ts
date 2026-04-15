import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { requireAuth } from '../middleware/auth'

export const billsRouter = Router()

billsRouter.use(requireAuth)

function canAccessCompany(req: Express.Request, companyId: string) {
  return req.auth.role === 'ADMIN' || req.auth.companyId === companyId
}

// GET /api/companies/:companyId/bills
billsRouter.get('/companies/:companyId/bills', async (req, res) => {
  if (!canAccessCompany(req, req.params.companyId)) { res.status(403).json({ error: 'Forbidden' }); return }

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
  if (!canAccessCompany(req, bill.companyId)) { res.status(403).json({ error: 'Forbidden' }); return }
  res.json(normalizeBill(bill))
})

// POST /api/companies/:companyId/bills
billsRouter.post('/companies/:companyId/bills', async (req, res) => {
  if (!canAccessCompany(req, req.params.companyId)) { res.status(403).json({ error: 'Forbidden' }); return }

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
  if (!canAccessCompany(req, existing.companyId)) { res.status(403).json({ error: 'Forbidden' }); return }

  const { lineItems, ...billData } = req.body

  const bill = await prisma.bill.update({
    where: { id: req.params.id },
    data: {
      ...billData,
      status: (billData.status as string)?.toUpperCase() ?? existing.status,
      ...(lineItems && {
        lineItems: {
          deleteMany: {},
          create: lineItems.map(({ id: _id, ...item }: { id?: string } & Record<string, unknown>) => item),
        },
      }),
    },
    include: { lineItems: true },
  })

  res.json(normalizeBill(bill))
})

// DELETE /api/bills/:id
billsRouter.delete('/bills/:id', async (req, res) => {
  const existing = await prisma.bill.findUnique({ where: { id: req.params.id } })
  if (!existing) { res.status(404).json({ error: 'Not found' }); return }
  if (!canAccessCompany(req, existing.companyId)) { res.status(403).json({ error: 'Forbidden' }); return }

  await prisma.bill.delete({ where: { id: req.params.id } })
  res.status(204).send()
})

// POST /api/bills/parse — AI parse a bill image/PDF (Anthropic key stays server-side)
billsRouter.post('/bills/parse', async (req, res) => {
  const { base64, mediaType } = req.body as { base64: string; mediaType: string }

  const apiKey = process.env.ANTHROPIC_API_KEY

  // Return mock data if no API key configured
  if (!apiKey) {
    await new Promise((r) => setTimeout(r, 2000))
    res.json(MOCK_PARSED_BILL())
    return
  }

  const contentBlock = mediaType === 'application/pdf'
    ? { type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: base64 } }
    : { type: 'image',    source: { type: 'base64', media_type: mediaType,          data: base64 } }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-6',
      max_tokens: 2000,
      messages: [{ role: 'user', content: [contentBlock, { type: 'text', text: PARSE_PROMPT }] }],
    }),
  })

  if (!response.ok) {
    const err = await response.json().catch(() => ({}))
    res.status(response.status).json({ error: 'AI API error', details: err })
    return
  }

  const data = await response.json() as { content: Array<{ type: string; text: string }> }
  const text = data.content.find((b) => b.type === 'text')?.text ?? ''

  try {
    const fenced = text.match(/```json\s*([\s\S]*?)```/)
    const jsonStr = fenced ? fenced[1] : text.slice(text.indexOf('{'), text.lastIndexOf('}') + 1)
    const parsed = JSON.parse(jsonStr)
    res.json({
      ...parsed,
      roundOffAmount: parsed.roundOffAmount ?? null,
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

▸ lineItem.discountPercent — per-line discount % only. Use null for Pattern B (discount is invoice-level).

▸ subtotal — read the "Taxable Value", "Net Amount before Tax", or "Taxable Amount" printed on the bill.
  This is the total of all tax-exclusive line amounts after any discount.
  VERIFY: sum of all lineItem.amount values should equal subtotal (within ±1 due to rounding).

▸ cgstAmount — read from labels "CGST", "C.GST", "Central GST", "Central Tax". Use 0 if not present.
▸ sgstAmount — read from labels "SGST", "S.GST", "State GST", "State Tax", "UTGST". Use 0 if not present.
▸ igstAmount — read from label "IGST". Use 0 if not present.
▸ roundOffAmount — read from "Round Off", "Rounding", "Rounded". Use null if not present.
▸ totalAmount — the final grand total payable (bottom-line number on the bill).

VERIFY before outputting:
  subtotal + cgstAmount + sgstAmount + igstAmount + (roundOffAmount ?? 0) ≈ totalAmount
  If this does not hold, re-check your subtotal and tax amounts.

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
      "unit": string,
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
  "roundOffAmount": number | null
}

CRITICAL numeric rules:
- A dot (.) between digits is ALWAYS a decimal point — never drop it (e.g. "1.50" → 1.50, NOT 150).
- Commas are thousand separators (e.g. "1,450.50" → 1450.50).
- Do not round or truncate any value; copy numbers exactly as printed.
- If a field is not present on the bill, use null (not 0 for optional fields).

End your response with the JSON object wrapped in \`\`\`json ... \`\`\`.`

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

// Workaround: Express.Request type needs auth in this file too
import type Express from 'express'
