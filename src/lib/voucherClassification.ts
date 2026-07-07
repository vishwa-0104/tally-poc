import type { TallyVoucher, CashBankFlow, TopItem, DaybookOptions } from '@/services/tallyService'

// Ports the cash/bank-flow, indirect income/expense, EBITDA, and Top Items
// classification from extension/background.js's parseVouchers() so the same
// numbers can be recomputed from DB-cached vouchers (which already carry
// taxableAmount/hasSalesLedger from storage — no GST/taxable recomputation
// needed here, unlike the live-Tally path).
//
// KNOWN GAP vs. the live path: background.js also scans ALLLEDGERENTRIES.LIST
// blocks that Tally places OUTSIDE <VOUCHER> tags (multi-party "as per
// details" Receipt vouchers) and attributes them to the nearest preceding
// voucher's date for cash/bank flow. Those entries aren't captured per-voucher
// at storage time, so cash/bank flow from DB-cached data can undercount for
// vouchers hitting that edge case. Flagged as a follow-up, not fixed here.

const CASH_RE = /cash/i
const BANK_RE = /\bbank\b/i

function toSet(names?: string[]): Set<string> | null {
  return names && names.length ? new Set(names.map((n) => n.toLowerCase())) : null
}

export interface ClassifyVouchersResult {
  cashFlow:      CashBankFlow
  bankFlow:      CashBankFlow
  topItems:      TopItem[]
  indExpTotal:   number
  indIncTotal:   number
  ebitdaAddback: number
  interestExpenseTotal:        number
  taxPaymentTotal:             number
  nonOperatingIncomeTotal:     number
  nonOperatingInvestmentTotal: number
}

export function classifyVouchers(
  vouchers: TallyVoucher[],
  options: DaybookOptions,
  fromISO: string,
  toISO: string,
): ClassifyVouchersResult {
  const cashFlow = { inflow: 0, outflow: 0 }
  const bankFlow = { inflow: 0, outflow: 0 }
  const itemMap = new Map<string, { qty: number; unit: string; amount: number }>()

  const salesAccountSet    = toSet(options.salesAccounts)
  const inflowSet          = toSet(options.cashInflowLedgers)
  const outflowSet         = inflowSet // cash inflow/outflow share the same configured ledger names
  const bankSet            = toSet(options.bankLedgers)
  const indExpSet          = toSet(options.indirectExpenseLedgers)
  const indIncSet          = toSet(options.indirectIncomeLedgers)
  const indExpIncVoucherSet = toSet(options.indirectExpenseIncludeVouchers)
  const indExpExcVoucherSet = toSet(options.indirectExpenseExcludeVouchers)
  const indIncIncVoucherSet = toSet(options.indirectIncomeIncludeVouchers)
  const indIncExcVoucherSet = toSet(options.indirectIncomeExcludeVouchers)
  const ebitdaSet           = toSet(options.ebitdaLedgers)
  const ebitdaIncSet        = toSet(options.ebitdaIncludeVouchers)
  const ebitdaExcSet        = toSet(options.ebitdaExcludeVouchers)
  // ROCE/ROE period-flow ledgers — magnitude only (no include/exclude-voucher
  // filtering, mirroring the FETCH_LEDGER_AMOUNTS path these replace), so raw
  // signed amounts are netted first and Math.abs()'d once at the very end
  // rather than using indExp/indInc's directional +=/-=.
  const interestExpenseSet        = toSet(options.interestExpenseLedgers)
  const taxPaymentSet             = toSet(options.taxPaymentLedgers)
  const nonOperatingIncomeSet     = toSet(options.nonOperatingIncomeLedgers)
  const nonOperatingInvestmentSet = toSet(options.nonOperatingInvestmentLedgers)

  const salesIncludeVouchers = options.salesIncludeVouchers ?? []
  const salesExcludeVouchers = options.salesExcludeVouchers ?? []

  let indExpTotal   = 0
  let indIncTotal   = 0
  let ebitdaAddback = 0
  let interestExpenseRaw       = 0
  let taxPaymentRaw            = 0
  let nonOperatingIncomeRaw    = 0
  let nonOperatingInvestmentRaw = 0

  for (const voucher of vouchers) {
    const { date, type, hasSalesLedger } = voucher
    const typeLower = type.toLowerCase()
    const inRange = (!fromISO || date >= fromISO) && (!toISO || date <= toISO)

    for (const le of voucher.ledgerEntries ?? []) {
      const ledgerLower = le.ledgerName.toLowerCase()
      const leAmt = le.amount

      if (indExpSet?.has(ledgerLower)) {
        const passesInc = !indExpIncVoucherSet || indExpIncVoucherSet.has(typeLower)
        const passesExc = !indExpExcVoucherSet || !indExpExcVoucherSet.has(typeLower)
        if (passesInc && passesExc) indExpTotal -= leAmt
      }
      if (indIncSet?.has(ledgerLower)) {
        const passesInc = !indIncIncVoucherSet || indIncIncVoucherSet.has(typeLower)
        const passesExc = !indIncExcVoucherSet || !indIncExcVoucherSet.has(typeLower)
        if (passesInc && passesExc) indIncTotal += leAmt
      }
      if (ebitdaSet?.has(ledgerLower)) {
        const passesInc = !ebitdaIncSet || ebitdaIncSet.has(typeLower)
        const passesExc = !ebitdaExcSet || !ebitdaExcSet.has(typeLower)
        if (passesInc && passesExc) ebitdaAddback -= leAmt // same sign as expenses: Dr=negative → addback positive
      }
      if (interestExpenseSet?.has(ledgerLower)) interestExpenseRaw += leAmt
      if (taxPaymentSet?.has(ledgerLower)) taxPaymentRaw += leAmt
      if (nonOperatingIncomeSet?.has(ledgerLower)) nonOperatingIncomeRaw += leAmt
      if (nonOperatingInvestmentSet?.has(ledgerLower)) nonOperatingInvestmentRaw += leAmt

      const isInflowLedger  = inflowSet  ? inflowSet.has(ledgerLower)  : CASH_RE.test(le.ledgerName)
      const isOutflowLedger = outflowSet ? outflowSet.has(ledgerLower) : CASH_RE.test(le.ledgerName)
      const isBankLedger    = bankSet    ? bankSet.has(ledgerLower)    : BANK_RE.test(le.ledgerName)

      // NOTE: do NOT skip party entries for cash/bank ledgers — in Cash Sale
      // and Contra vouchers, Cash/Bank is itself the party ledger.
      if (inRange && (isInflowLedger || isOutflowLedger)) {
        if (leAmt < 0) cashFlow.inflow  += Math.abs(leAmt)
        else           cashFlow.outflow += leAmt
      } else if (inRange && isBankLedger) {
        if (leAmt < 0) bankFlow.inflow  += Math.abs(leAmt)
        else           bankFlow.outflow += leAmt
      }
    }

    // Top items — only sales vouchers (typed/included, not excluded) with a matching ledger
    if (inRange) {
      const isExcluded = salesExcludeVouchers.length
        ? salesExcludeVouchers.some((t) => t.toLowerCase() === typeLower)
        : /credit\s*note/i.test(type)
      const isIncluded = !isExcluded && (salesIncludeVouchers.length
        ? salesIncludeVouchers.some((t) => t.toLowerCase() === typeLower)
        : /sales/i.test(type))
      const ledgerOk = !salesAccountSet || hasSalesLedger

      if (isIncluded && ledgerOk) {
        for (const ie of voucher.inventoryEntries ?? []) {
          if (!itemMap.has(ie.itemName)) itemMap.set(ie.itemName, { qty: 0, unit: ie.unit, amount: 0 })
          const entry = itemMap.get(ie.itemName)!
          entry.qty    += ie.qty
          entry.amount += ie.amount
        }
      }
    }
  }

  const topItems: TopItem[] = [...itemMap.entries()]
    .map(([name, v]) => ({ name, qty: v.qty, unit: v.unit, amount: v.amount }))
    .sort((a, b) => b.amount - a.amount)
    .slice(0, 10)

  return {
    cashFlow, bankFlow, topItems, indExpTotal, indIncTotal, ebitdaAddback,
    interestExpenseTotal:        Math.abs(interestExpenseRaw),
    taxPaymentTotal:             Math.abs(taxPaymentRaw),
    nonOperatingIncomeTotal:     Math.abs(nonOperatingIncomeRaw),
    nonOperatingInvestmentTotal: Math.abs(nonOperatingInvestmentRaw),
  }
}

// Credit vs Cash sales split, for DSO. Sundry Debtors party ⇒ credit sale,
// Cash/Bank party ⇒ cash sale — reuses the same party-name regex fallback
// already used above for cash/bank ledger flow, since a cash sale's party is
// always a Cash/Bank ledger and a credit sale's party is always a debtor
// ledger. No separate ledger-group fetch needed. Mirrors the same
// include/exclude voucher-type filtering computeSalesTotal (Dashboard.tsx)
// already applies, so the two totals are directly comparable.
export function computeCreditSalesTotal(
  vouchers: TallyVoucher[],
  sf: { salesAccounts?: string[]; salesIncludeVouchers?: string[]; salesExcludeVouchers?: string[] } | undefined,
): number {
  const { salesAccounts, salesIncludeVouchers, salesExcludeVouchers } = sf ?? {}
  const base = salesAccounts?.length ? vouchers.filter((v) => v.hasSalesLedger) : vouchers

  const included = base.filter((v) => {
    if (salesIncludeVouchers?.length)
      return salesIncludeVouchers.some((t) => v.type.toLowerCase() === t.toLowerCase())
    return /sales/i.test(v.type) && !/credit\s*note/i.test(v.type)
  })

  const excluded = base.filter((v) => {
    if (salesExcludeVouchers?.length)
      return salesExcludeVouchers.some((t) => v.type.toLowerCase() === t.toLowerCase())
    return /credit\s*note/i.test(v.type)
  })

  const isCreditSale = (v: TallyVoucher) => !CASH_RE.test(v.party) && !BANK_RE.test(v.party)

  return included.filter(isCreditSale).reduce((s, v) => s + v.taxableAmount, 0)
       - excluded.filter(isCreditSale).reduce((s, v) => s + v.taxableAmount, 0)
}
