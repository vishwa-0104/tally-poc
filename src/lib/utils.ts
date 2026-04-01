import { clsx, type ClassValue } from 'clsx'

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs)
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(amount)
}

export function formatDate(date: string): string {
  return new Date(date).toLocaleDateString('en-IN', {
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
  return dateStr.replace(/-/g, '')
}

export function buildTallyXml(params: {
  vendorLedger?: string
  purchaseLedger?: string
  cgstLedger?: string
  sgstLedger?: string
  igstLedger?: string
  billNumber: string
  billDate: string
  totalAmount: number
  subtotal: number
  cgstAmount: number
  sgstAmount: number
  igstAmount: number
  tallyCompany?: string
}): string {
  const d = buildTallyDate(params.billDate)

  const vendorEntry = params.vendorLedger
    ? `
            <PARTYLEDGERNAME>${params.vendorLedger}</PARTYLEDGERNAME>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${params.vendorLedger}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>
              <AMOUNT>${params.totalAmount}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>`
    : ''

  const purchaseEntry = params.purchaseLedger
    ? `
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${params.purchaseLedger}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-${params.subtotal}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>`
    : ''

  const cgstEntry = params.cgstLedger && params.cgstAmount !== 0
    ? `
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${params.cgstLedger}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-${params.cgstAmount}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>`
    : ''

  const sgstEntry = params.sgstLedger && params.sgstAmount !== 0
    ? `
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${params.sgstLedger}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-${params.sgstAmount}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>`
    : ''

  const igstEntry = params.igstLedger && params.igstAmount !== 0
    ? `
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${params.igstLedger}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-${params.igstAmount}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>`
    : ''

  return `<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Vouchers</REPORTNAME>${params.tallyCompany ? `
        <STATICVARIABLES>
          <SVCURRENTCOMPANY>${params.tallyCompany}</SVCURRENTCOMPANY>
        </STATICVARIABLES>` : ''}
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <VOUCHER VCHTYPE="Purchase" ACTION="Create">
            <DATE>${d}</DATE>
            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>
            <NARRATION>${params.billNumber}</NARRATION>
            ${vendorEntry}
            ${purchaseEntry}
            ${cgstEntry}
            ${sgstEntry}
            ${igstEntry}
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
