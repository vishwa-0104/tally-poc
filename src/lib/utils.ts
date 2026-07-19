import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount)
}

export function formatDate(date: string): string {
  if (!date) return ''
  const d = new Date(date)
  if (isNaN(d.getTime())) return date
  return d.toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

export function getInitials(name: string): string {
  return name
    .split(' ')
    .map((w) => w[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

export function buildTallyDate(dateStr: string): string {
  if (!dateStr) return ''
  // Strip time component from ISO strings like "2025-01-15T00:00:00.000Z"
  const s = dateStr.trim().split('T')[0]
  // DD-MM-YYYY or DD/MM/YYYY → YYYYMMDD
  const dmy = s.match(/^(\d{2})[-/](\d{2})[-/](\d{4})$/)
  if (dmy) return `${dmy[3]}${dmy[2]}${dmy[1]}`
  // YYYY-MM-DD or YYYY/MM/DD → remove separators
  return s.replace(/[-/]/g, '')
}

interface LineItemParam {
  description: string
  hsnCode?: string | null
  quantity: number
  unit: string
  unitPrice: number
  discountPercent?: number | null
  discountAmount?: number | null
  gstRate: number
  amount: number
  tallyStockItem?: string | null
  ledger?: string | null
}

export function decodeHtmlEntities(str: string): string {
  return str
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#39;/g, "'")
}

function escapeXml(str: string): string {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
}

/**
 * Build a TallyPrime-compatible purchase voucher XML.
 *
 * Structure mirrors the actual TallyPrime XML export format:
 *   VOUCHER
 *     ALLINVENTORYENTRIES.LIST  (one per line item, at voucher level)
 *       BATCHALLOCATIONS.LIST       (godown / batch)
 *       ACCOUNTINGALLOCATIONS.LIST  (purchase ledger per item)
 *     LEDGERENTRIES.LIST  (party / vendor — credit)
 *     LEDGERENTRIES.LIST  (CGST / SGST / IGST — debit)
 *     LEDGERENTRIES.LIST  (Round Off — if applicable)
 *
 * Key fields:
 *   DATE          = voucher entry date
 *   REFERENCEDATE = supplier's invoice date
 *   REFERENCE     = supplier's invoice number (Ti/25-26/446)
 */
export function buildTallyXml(params: {
  vendorLedger?: string
  purchaseLedger?: string
  cgstEntries?: { ledger: string; amount: number }[]
  sgstEntries?: { ledger: string; amount: number }[]
  igstEntries?: { ledger: string; amount: number }[]
  billNumber: string        // supplier invoice number → REFERENCE
  billDate: string          // supplier invoice date  → REFERENCEDATE
  voucherDate?: string      // our entry date         → DATE (defaults to billDate)
  voucherNumber?: string    // Tally voucher number   → VOUCHERNUMBER (auto-assigned if omitted)
  totalAmount: number
  subtotal: number
  roundOffAmount?: number   // positive = debit round-off (e.g. 0.50), negative = credit
  roundOffLedger?: string   // defaults to 'Round Off'
  invoiceDiscountAmount?: number | null
  discountLedger?: string
  tallyCompany?: string
  voucherType?: string
  godown?: string
  lineItems?: LineItemParam[]
  miscLedgerItems?: { description: string; amount: number; ledger?: string }[]
  extraCharges?: { description: string; amount: number; ledger?: string }[]
  narration?: string
  includeItemDiscount?: boolean
  isReturn?: boolean   // true for Debit Note — flips all debit/credit signs in XML
}): string {
  const esc = escapeXml
  // Avoid floating-point noise like -90.00000000001
  const amt = (n: number) => parseFloat(n.toFixed(2))

  // Sign helpers: for a Debit Note every debit/credit polarity inverts.
  const flip      = params.isReturn ?? false
  const debitPos  = flip ? 'No'  : 'Yes'
  const creditPos = flip ? 'Yes' : 'No'
  const debitAmt  = (n: number) => flip ?  amt(n) : -amt(n)
  const creditAmt = (n: number) => flip ? -amt(n) :  amt(n)

  const entryDate       = buildTallyDate(params.voucherDate || params.billDate)
  const invoiceDate     = buildTallyDate(params.billDate)
  const voucherTypeName = esc(params.voucherType || 'GST PURCHASE')

  // Itemised mode whenever line items are present.
  // Falls back to item description when tallyStockItem is not mapped.
  const isMisc      = !!(params.miscLedgerItems?.length)
  const hasInventory = !!(params.lineItems?.length) && !isMisc

  // ── Inventory entries (VOUCHER level) ─────────────────────────────────────
  // Matches real Tally export: ALLINVENTORYENTRIES.LIST at voucher level,
  // each containing BATCHALLOCATIONS.LIST and ACCOUNTINGALLOCATIONS.LIST.
console.log('>>> line items', params)
  const inventoryEntries = hasInventory
    ? params.lineItems!.map((item) => {
        const stockName   = esc(item.tallyStockItem?.trim() || item.description)
        const unit        = esc(item.unit || 'Nos')
        const quantity    = item.quantity
        const rate        = amt(item.unitPrice)
        const itemAmt     = amt(item.amount)
        const purchLedger = item.ledger?.trim() ? esc(item.ledger.trim())
                          : params.purchaseLedger ? esc(params.purchaseLedger) : ''

        const discPct = (() => {
          if (!params.includeItemDiscount) return ''
          if (item.discountPercent != null && item.discountPercent !== 0) {
            return `\n              <DISCOUNT>${item.discountPercent}</DISCOUNT>`
          }
          if (item.discountAmount != null && item.discountAmount !== 0) {
            const grossAmt = item.quantity * item.unitPrice
            if (grossAmt > 0) {
              const equiv = parseFloat(((item.discountAmount / grossAmt) * 100).toFixed(2))
              return `\n              <DISCOUNT>${equiv}</DISCOUNT>`
            }
          }
          return ''
        })()

        
        return `
            <ALLINVENTORYENTRIES.LIST>
              <STOCKITEMNAME>${stockName}</STOCKITEMNAME>
              <ISDEEMEDPOSITIVE>${debitPos}</ISDEEMEDPOSITIVE>
              <RATE>${rate}/${unit}</RATE>${discPct}
              <AMOUNT>${debitAmt(itemAmt)}</AMOUNT>
              <ACTUALQTY> ${quantity} ${unit}</ACTUALQTY>
              <BILLEDQTY> ${quantity} ${unit}</BILLEDQTY>
              <BATCHALLOCATIONS.LIST>
                <GODOWNNAME>${esc(params.godown?.trim() || 'Main Location')}</GODOWNNAME>
                <BATCHNAME>Primary Batch</BATCHNAME>
                <AMOUNT>${debitAmt(itemAmt)}</AMOUNT>
                <ACTUALQTY> ${quantity} ${unit}</ACTUALQTY>
                <BILLEDQTY> ${quantity} ${unit}</BILLEDQTY>
              </BATCHALLOCATIONS.LIST>${item.ledger || purchLedger ? `
              <ACCOUNTINGALLOCATIONS.LIST>
                <LEDGERNAME>${item.ledger || purchLedger}</LEDGERNAME>
                <ISDEEMEDPOSITIVE>${debitPos}</ISDEEMEDPOSITIVE>
                <LEDGERFROMITEM>No</LEDGERFROMITEM>
                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>
                <ISPARTYLEDGER>No</ISPARTYLEDGER>
                <AMOUNT>${debitAmt(itemAmt)}</AMOUNT>
              </ACCOUNTINGALLOCATIONS.LIST>` : ''}
            </ALLINVENTORYENTRIES.LIST>`
      }).join('')
    : ''

  // Misc expense ledger entries — one debit entry per expense line (no inventory)
  const miscEntries = isMisc
    ? params.miscLedgerItems!
        .filter((item) => item.ledger?.trim() && item.amount)
        .map((item) => `
            <LEDGERENTRIES.LIST>
              <LEDGERNAME>${esc(item.ledger!.trim())}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>${debitPos}</ISDEEMEDPOSITIVE>
              <LEDGERFROMITEM>No</LEDGERFROMITEM>
              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>
              <ISPARTYLEDGER>No</ISPARTYLEDGER>
              <AMOUNT>${debitAmt(item.amount)}</AMOUNT>
            </LEDGERENTRIES.LIST>`).join('')
    : ''

  // ── Ledger entries — using LEDGERENTRIES.LIST as per real Tally XML ────────

  // Party ledger (vendor) — credit in purchase, debit in debit note
  const partyEntry = params.vendorLedger
    ? `
            <LEDGERENTRIES.LIST>
              <LEDGERNAME>${esc(params.vendorLedger)}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>${creditPos}</ISDEEMEDPOSITIVE>
              <LEDGERFROMITEM>No</LEDGERFROMITEM>
              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>
              <ISPARTYLEDGER>Yes</ISPARTYLEDGER>
              <AMOUNT>${creditAmt(params.totalAmount)}</AMOUNT>
            </LEDGERENTRIES.LIST>`
    : ''

  // Purchase ledger — only when NOT in itemised mode and NOT a misc bill
  const purchaseEntry = !hasInventory && !isMisc && params.purchaseLedger
    ? `
            <LEDGERENTRIES.LIST>
              <LEDGERNAME>${esc(params.purchaseLedger)}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>${debitPos}</ISDEEMEDPOSITIVE>
              <LEDGERFROMITEM>No</LEDGERFROMITEM>
              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>
              <ISPARTYLEDGER>No</ISPARTYLEDGER>
              <AMOUNT>${debitAmt(params.subtotal)}</AMOUNT>
            </LEDGERENTRIES.LIST>`
    : ''

  // Extra charges — debit entries (freight, insurance, etc.)
  const extraChargeEntries = (params.extraCharges ?? [])
    .filter((ec) => ec.ledger?.trim() && ec.amount)
    .map((ec) => `
            <LEDGERENTRIES.LIST>
              <LEDGERNAME>${esc(ec.ledger!.trim())}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>${debitPos}</ISDEEMEDPOSITIVE>
              <LEDGERFROMITEM>No</LEDGERFROMITEM>
              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>
              <ISPARTYLEDGER>No</ISPARTYLEDGER>
              <AMOUNT>${debitAmt(ec.amount)}</AMOUNT>
            </LEDGERENTRIES.LIST>`).join('')

  // Tax ledgers — one debit entry per rate bucket
  const taxEntry = ({ ledger, amount }: { ledger: string; amount: number }) => `
            <LEDGERENTRIES.LIST>
              <LEDGERNAME>${esc(ledger)}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>${debitPos}</ISDEEMEDPOSITIVE>
              <LEDGERFROMITEM>No</LEDGERFROMITEM>
              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>
              <ISPARTYLEDGER>No</ISPARTYLEDGER>
              <AMOUNT>${debitAmt(amount)}</AMOUNT>
            </LEDGERENTRIES.LIST>`

  const cgstEntry = (params.cgstEntries ?? []).filter((e) => e.amount !== 0).map(taxEntry).join('')
  const sgstEntry = (params.sgstEntries ?? []).filter((e) => e.amount !== 0).map(taxEntry).join('')
  const igstEntry = (params.igstEntries ?? []).filter((e) => e.amount !== 0).map(taxEntry).join('')

  // Invoice-level discount — normally a credit entry reducing the amount payable.
  const discountEntry = params.discountLedger?.trim() && params.invoiceDiscountAmount && params.invoiceDiscountAmount > 0
    ? `
            <LEDGERENTRIES.LIST>
              <LEDGERNAME>${esc(params.discountLedger)}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>${creditPos}</ISDEEMEDPOSITIVE>
              <LEDGERFROMITEM>No</LEDGERFROMITEM>
              <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>
              <ISPARTYLEDGER>No</ISPARTYLEDGER>
              <AMOUNT>${creditAmt(params.invoiceDiscountAmount)}</AMOUNT>
            </LEDGERENTRIES.LIST>`
    : ''

  // Round-off — ROUNDTYPE and ROUNDLIMIT match real Tally export.
  const roundOffLedger = esc(params.roundOffLedger?.trim() || 'Round Off')

  const roundOffEntry = params.roundOffAmount && params.roundOffAmount !== 0
    ? `
            <LEDGERENTRIES.LIST>
             <ROUNDTYPE>Normal Rounding</ROUNDTYPE>
                <LEDGERNAME>${roundOffLedger}</LEDGERNAME>
                <ISDEEMEDPOSITIVE>${debitPos}</ISDEEMEDPOSITIVE>
                <LEDGERFROMITEM>No</LEDGERFROMITEM>
                <REMOVEZEROENTRIES>No</REMOVEZEROENTRIES>
                <ISPARTYLEDGER>No</ISPARTYLEDGER>
                <AMOUNT>${flip ? amt(params.roundOffAmount) : amt(params.roundOffAmount * -1)}</AMOUNT>
                <ROUNDLIMIT>1</ROUNDLIMIT>
            </LEDGERENTRIES.LIST>`
    : ''

  return `<?xml version="1.0" encoding="utf-8"?>
<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Vouchers</REPORTNAME>${params.tallyCompany ? `
        <STATICVARIABLES>
          <SVCURRENTCOMPANY>${esc(params.tallyCompany)}</SVCURRENTCOMPANY>
        </STATICVARIABLES>` : ''}
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <VOUCHER VCHTYPE="${voucherTypeName}" ACTION="Create" OBJVIEW="Invoice Voucher View">
            <DATE>${entryDate}</DATE>${params.voucherNumber ? `
            <VOUCHERNUMBER>${esc(params.voucherNumber)}</VOUCHERNUMBER>` : ''}
            <REFERENCEDATE>${invoiceDate}</REFERENCEDATE>
            <VOUCHERTYPENAME>${voucherTypeName}</VOUCHERTYPENAME>${params.vendorLedger ? `
            <PARTYLEDGERNAME>${esc(params.vendorLedger)}</PARTYLEDGERNAME>
            <PARTYMAILINGNAME>${esc(params.vendorLedger)}</PARTYMAILINGNAME>` : ''}
            <REFERENCE>${esc(params.billNumber)}</REFERENCE>${params.narration ? `
            <NARRATION>${esc(params.narration)}</NARRATION>` : ''}
            <VCHENTRYMODE>${hasInventory ? 'Item Invoice' : 'Accounting Invoice'}</VCHENTRYMODE>
            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>
            <ISINVOICE>Yes</ISINVOICE>${inventoryEntries}${partyEntry}${miscEntries}${purchaseEntry}${extraChargeEntries}${cgstEntry}${sgstEntry}${igstEntry}${discountEntry}${roundOffEntry}
          </VOUCHER>
        </TALLYMESSAGE>
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>`
}

export function colorizeXml(xml: string): string {
  return xml
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(
      /&lt;(\/?[A-Z][A-Z0-9_.]*)(.*?)&gt;/g,
      (_m, tag: string, attrs: string) =>
        `<span class="xml-tag">&lt;${tag}${attrs}&gt;</span>`,
    )
    .replace(
      /&gt;([^&<\n]+)&lt;/g,
      (_m, val: string) => `&gt;<span class="xml-val">${val}</span>&lt;`,
    )
}
