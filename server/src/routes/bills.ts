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
      lineItems: (parsed.lineItems ?? []).map((item: Record<string, unknown>) => ({
        ...item,
        hsnCode: item.hsnCode ?? '',
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

const PARSE_PROMPT = `You are extracting data from a purchase bill (may be handwritten or printed).

STEP 1 — Identify the parties on the bill:
- VENDOR / SELLER / SUPPLIER: the business that ISSUED the bill. Look for headings like "From", "Sold by", "Supplier", "Issued by", or the company name/logo at the TOP of the bill.
- BUYER / BILL TO / SHIP TO: the business that RECEIVED the bill (our company). Look for "Bill to", "Sold to", "Buyer", "Consignee".

GSTIN rules — a bill may contain multiple GSTINs. Identify each by its label and position:
- vendorGstin: the GSTIN belonging to the VENDOR/SELLER (the one who raised the bill). It usually appears near the vendor name/address at the top, or under labels like "GSTIN", "GST No", "Supplier GSTIN", "Our GSTIN".
- buyerGstin: the GSTIN belonging to the BUYER (our company). It usually appears in the "Bill to" / "Ship to" section, or under labels like "Buyer GSTIN", "Your GSTIN", "Recipient GSTIN".
- If a GSTIN's role is ambiguous (no clear label), assign it to vendorGstin.
- A valid Indian GSTIN is 15 characters: 2-digit state code + 10-char PAN + 1 entity + 1 Z + 1 check digit.

STEP 2 — Locate and read these values verbatim from the bill, character by character:
- Each line item: description, HSN code, quantity, unit, unit price, GST rate, line total
- Subtotal (taxable value / amount before tax)
- CGST amount — look for labels like "CGST", "C.GST", "Central Tax"
- SGST amount — look for labels like "SGST", "S.GST", "State Tax"
- IGST amount — look for label "IGST"; use 0 if not present
- Grand total / Total amount payable — the final bottom-line number on the bill

STEP 3 — Output ONLY a valid JSON object using the schema below.

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
      "gstRate": number,
      "amount": number
    }
  ],
  "subtotal": number,
  "cgstAmount": number,
  "sgstAmount": number,
  "igstAmount": number,
  "totalAmount": number
}

CRITICAL numeric rules:
- A dot (.) between digits is ALWAYS a decimal point — never drop it (e.g. "1.50" → 1.50, NOT 150).
- Commas are thousand separators (e.g. "1,450.50" → 1450.50).
- Do not round, truncate, or multiply any value.
- If a field is not found set it to null.

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
