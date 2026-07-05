import type { TallyGodown, TallyLedger, TallyStockItem, TallyStockGroup, TallyStockUnit, TallySyncResult } from '@/types'

export interface CreateStockItemPayload {
  name: string
  group: string
  unit: string
  description?: string
  gstApplicable: 'Yes' | 'No'
  taxability: string
  hsnCode: string
  gstRate?: number
  typeOfSupply: string
  tallyCompany?: string
}

const EXTENSION_MSG_TIMEOUT = 120_000

/**
 * Send a message to the extension via the content script bridge.
 * Uses window.postMessage so we never call chrome.runtime directly from
 * the page — this avoids the MV3 service-worker-sleep issue.
 */
async function sendToExtension<T>(type: string, payload: Record<string, unknown>): Promise<T> {
  return new Promise((resolve, reject) => {
    const msgId = Math.random().toString(36).slice(2)

    const timer = setTimeout(() => {
      window.removeEventListener('message', handler)
      const err = new Error(`[TallySync] Timeout: no response from extension for "${type}". Is the extension installed and enabled?`)
      console.error(err.message)
      reject(err)
    }, EXTENSION_MSG_TIMEOUT)

    function handler(event: MessageEvent) {
      if (!event.data?.__tallyReply || event.data.__msgId !== msgId) return
      clearTimeout(timer)
      window.removeEventListener('message', handler)
      if (event.data.error) {
        const err = new Error(`[TallySync] Extension error for "${type}": ${event.data.error}`)
        console.error(err.message)
        reject(err)
      } else {
        console.log(`[TallySync] "${type}" response:`, event.data)
        resolve(event.data as T)
      }
    }

    console.log(`[TallySync] Sending "${type}"`, payload)
    window.addEventListener('message', handler)
    window.postMessage({ __tallyMsg: true, __msgId: msgId, type, ...payload }, '*')
  })
}

// ── Public API ─────────────────────────────────────────────

export async function fetchTallyLedgers(tallyUrl: string, tallyCompany?: string): Promise<TallyLedger[]> {
  console.log('[Step 1] Fetching ledgers from Tally:', tallyUrl, 'company:', tallyCompany)
  const result = await sendToExtension<{ ledgers: TallyLedger[] }>('FETCH_LEDGERS', { tallyUrl, tallyCompany })
  console.log('[Step 2] Ledgers received from Tally extension. Count:', result.ledgers.length, '| Sample:', result.ledgers.slice(0, 3))
  return result.ledgers
}

export async function fetchTallyStockItems(tallyUrl: string, tallyCompany?: string): Promise<TallyStockItem[]> {
  const result = await sendToExtension<{ stockItems: TallyStockItem[] }>('FETCH_STOCK_ITEMS', { tallyUrl, tallyCompany })
  return result.stockItems
}

export async function fetchTallyStockGroups(tallyUrl: string, tallyCompany?: string): Promise<TallyStockGroup[]> {
  const result = await sendToExtension<{ stockGroups: TallyStockGroup[] }>('FETCH_STOCK_GROUPS', { tallyUrl, tallyCompany })
  return result.stockGroups
}

export async function fetchTallyStockUnits(tallyUrl: string, tallyCompany?: string): Promise<TallyStockUnit[]> {
  const result = await sendToExtension<{ stockUnits: TallyStockUnit[] }>('FETCH_STOCK_UNITS', { tallyUrl, tallyCompany })
  return result.stockUnits
}

export async function fetchTallyGodowns(tallyUrl: string, tallyCompany?: string): Promise<TallyGodown[]> {
  const result = await sendToExtension<{ godowns: TallyGodown[] }>('FETCH_GODOWNS', { tallyUrl, tallyCompany })
  return result.godowns
}

export async function fetchTallyVoucherTypes(tallyUrl: string, tallyCompany?: string): Promise<string[]> {
  const result = await sendToExtension<{ voucherTypes: string[] }>('FETCH_VOUCHER_TYPES', { tallyUrl, tallyCompany })
  return result.voucherTypes
}

export async function createTallyStockGroup(
  payload: { name: string; parent: string; tallyCompany?: string },
  tallyUrl: string,
): Promise<TallySyncResult> {
  const result = await sendToExtension<TallySyncResult>('CREATE_STOCK_GROUP', { ...payload, tallyUrl })
  console.log('[CreateStockGroup] Tally response:', result)
  return result
}

export async function createTallyStockItem(payload: CreateStockItemPayload, tallyUrl: string): Promise<TallySyncResult> {
  const result = await sendToExtension<TallySyncResult>('CREATE_STOCK_ITEM', { ...payload, tallyUrl })
  console.log('[CreateStockItem] Tally response:', result)
  return result
}

export interface CreateLedgerPayload {
  name: string
  gstin?: string
  pan?: string
  address?: string
  state?: string
  pincode?: string
  under?: string
  gstRegistrationType?: string
  tallyCompany?: string
}

export async function createTallyLedger(payload: CreateLedgerPayload, tallyUrl: string): Promise<TallySyncResult> {
  const result = await sendToExtension<TallySyncResult>('CREATE_LEDGER', { ...payload, tallyUrl })
  console.log('[CreateLedger] Tally response:', result)
  return result
}

export interface VoucherLedgerEntry {
  ledgerName:    string
  amount:        number
  isPartyLedger: boolean
}

export interface VoucherInventoryEntry {
  itemName: string
  qty:      number
  unit:     string
  amount:   number
}

export interface TallyVoucher {
  date:             string
  type:             string
  party:            string
  amount:           number  // total including GST (party ledger value)
  taxableAmount:    number  // amount minus CGST/SGST/IGST/Cess
  voucherNo:        string
  alterId?:         string  // Tally's ALTERID — changes on every edit, useful for diffing/dedup
  guid?:            string  // Tally's GUID — stable across edits, the safe identity for versioning (voucherNo alone collides across voucher types)
  hasSalesLedger?:  boolean // true when a configured sales account ledger appears in this voucher
  salesLedger?:     string  // matched sales account ledger name (set when salesAccounts is configured)
  purchaseLedger?:  string  // matched purchase account ledger name (set when purchaseAccounts is configured)
  ledgerEntries?:    VoucherLedgerEntry[]    // raw per-ledger detail — lets cash/bank flow etc. be recomputed later from DB
  inventoryEntries?: VoucherInventoryEntry[] // raw per-item detail — lets Top Items be recomputed later from DB
}

export async function fetchTallyVouchers(
  fromDate: string,
  toDate: string,
  voucherType: string,
  tallyUrl: string,
  tallyCompany?: string,
): Promise<TallyVoucher[]> {
  const result = await sendToExtension<{ vouchers: TallyVoucher[] }>('FETCH_VOUCHERS', {
    fromDate, toDate, voucherType, tallyUrl, tallyCompany,
  })
  return result.vouchers
}

export interface SalesPartyRow {
  name:   string
  amount: number
}

export async function fetchSalesPartyData(
  fromDate: string,
  toDate: string,
  tallyUrl: string,
  tallyCompany?: string,
): Promise<SalesPartyRow[]> {
  const result = await sendToExtension<{ parties: SalesPartyRow[] }>('FETCH_SALES_PARTY', {
    fromDate, toDate, tallyUrl, tallyCompany,
  })
  return result.parties
}

export async function fetchLedgerAmounts(
  fromDate:     string,
  toDate:       string,
  tallyUrl:     string,
  tallyCompany?: string,
  ledgerNames?:  string[],
): Promise<number> {
  if (!ledgerNames?.length) return 0
  const result = await sendToExtension<{ total: number }>(
    'FETCH_LEDGER_AMOUNTS',
    { fromDate, toDate, tallyUrl, tallyCompany, ledgerNames },
  )
  return result.total
}

export async function fetchStockValue(
  fromDate:    string,
  toDate:      string,
  tallyUrl:    string,
  tallyCompany?: string,
): Promise<{ openingStock: number; closingStock: number }> {
  const result = await sendToExtension<{ openingStock: number; closingStock: number }>(
    'FETCH_STOCK_VALUE',
    { fromDate, toDate, tallyUrl, tallyCompany },
  )
  return result
}

export interface BankSyncRow {
  date: string
  description: string
  ledger: string
  voucherType: string
  amount: number
  isPayment: boolean
  narration?: string
  originalDate?: string
}

export async function syncBankToTally(
  rows: BankSyncRow[],
  bankLedger: string,
  tallyUrl: string,
  tallyCompany?: string,
): Promise<TallySyncResult> {
  const result = await sendToExtension<TallySyncResult>('SYNC_BANK_TO_TALLY', { rows, bankLedger, tallyUrl, tallyCompany })
  console.log('[SyncBank] Tally response:', result)
  return result
}

export interface CashBankFlow {
  inflow:  number
  outflow: number
}

export interface TopItem {
  name:   string
  qty:    number
  unit:   string
  amount: number
}

export interface DaybookOptions {
  salesAccounts?:           string[]
  salesIncludeVouchers?:    string[]
  salesExcludeVouchers?:    string[]
  cashInflowLedgers?:       string[]
  bankLedgers?:             string[]
  purchaseAccounts?:        string[]
  indirectExpenseLedgers?:         string[]
  indirectExpenseIncludeVouchers?: string[]
  indirectExpenseExcludeVouchers?: string[]
  indirectIncomeLedgers?:          string[]
  indirectIncomeIncludeVouchers?:  string[]
  indirectIncomeExcludeVouchers?:  string[]
  ebitdaLedgers?:                  string[]
  ebitdaIncludeVouchers?:          string[]
  ebitdaExcludeVouchers?:          string[]
}

export async function fetchDaybook(
  fromDate: string,
  toDate: string,
  tallyUrl: string,
  tallyCompany?: string,
  options: DaybookOptions = {},
): Promise<{ vouchers: TallyVoucher[]; rawXml: string; cashFlow: CashBankFlow; bankFlow: CashBankFlow; topItems: TopItem[]; indExpTotal: number; indIncTotal: number; ebitdaAddback: number }> {
  const result = await sendToExtension<{ vouchers: TallyVoucher[]; rawXml: string; cashFlow: CashBankFlow; bankFlow: CashBankFlow; topItems: TopItem[]; indExpTotal: number; indIncTotal: number; ebitdaAddback: number }>('FETCH_DAYBOOK', {
    fromDate, toDate, tallyUrl, tallyCompany,
    salesAccounts:           options.salesAccounts           ?? [],
    salesIncludeVouchers:    options.salesIncludeVouchers    ?? [],
    salesExcludeVouchers:    options.salesExcludeVouchers    ?? [],
    cashInflowLedgers:       options.cashInflowLedgers       ?? [],
    bankLedgers:             options.bankLedgers             ?? [],
    purchaseAccounts:        options.purchaseAccounts        ?? [],
    indirectExpenseLedgers:         options.indirectExpenseLedgers         ?? [],
    indirectExpenseIncludeVouchers: options.indirectExpenseIncludeVouchers ?? [],
    indirectExpenseExcludeVouchers: options.indirectExpenseExcludeVouchers ?? [],
    indirectIncomeLedgers:          options.indirectIncomeLedgers          ?? [],
    indirectIncomeIncludeVouchers:  options.indirectIncomeIncludeVouchers  ?? [],
    indirectIncomeExcludeVouchers:  options.indirectIncomeExcludeVouchers  ?? [],
    ebitdaLedgers:                  options.ebitdaLedgers                  ?? [],
    ebitdaIncludeVouchers:          options.ebitdaIncludeVouchers          ?? [],
    ebitdaExcludeVouchers:          options.ebitdaExcludeVouchers          ?? [],
  })
  return result
}

export interface SlowStockItem {
  name:         string
  lastSaleDate: string   // "YYYY-MM-DD"
  daysSince:    number
}

export async function fetchSlowMovingStock(
  tallyUrl: string,
  tallyCompany?: string,
): Promise<{ items: SlowStockItem[] }> {
  return sendToExtension<{ items: SlowStockItem[] }>('FETCH_SLOW_STOCK', { tallyUrl, tallyCompany })
}

export interface RawLedger {
  name:    string
  group:   string
  balance: number  // positive = Dr (asset), negative = Cr (liability)
}

export async function fetchLedgerBalances(
  tallyUrl: string,
  tallyCompany?: string,
  asOfDate?: string,   // YYYYMMDD — defaults to today in the extension handler
): Promise<{ rawLedgers: RawLedger[] }> {
  return sendToExtension<{ rawLedgers: RawLedger[] }>('FETCH_LEDGER_BALANCES', {
    tallyUrl, tallyCompany, asOfDate,
  })
}

export interface GroupBalances {
  receivables:        number
  payables:           number
  equity:             number
  investments:        number
  currentLiabilities: number
  fixedAssets:        number
  totalLoans:         number
  bankOD:             number
}

export async function fetchGroupBalances(
  tallyUrl: string,
  tallyCompany?: string,
  asOfDate?: string,   // YYYYMMDD — ignored by Tally, always returns current date balance
): Promise<GroupBalances> {
  return sendToExtension<GroupBalances>('FETCH_GROUP_BALANCES', {
    tallyUrl, tallyCompany, asOfDate,
  })
}

// available: false means bill-wise ageing genuinely couldn't be determined
// (no debtor ledgers, or bill-wise details not maintained) — never fall back
// to a guessed number, show "No data available" instead.
export async function fetchReceivablesAgeing(
  tallyUrl: string,
  tallyCompany?: string,
  asOfDate?: string,   // YYYYMMDD
  withinDays = 90,
): Promise<{ available: boolean; total: number | null }> {
  return sendToExtension<{ available: boolean; total: number | null }>('FETCH_RECEIVABLES_AGEING', {
    tallyUrl, tallyCompany, asOfDate, withinDays,
  })
}


export async function syncToTally(xml: string, tallyUrl: string): Promise<TallySyncResult> {
  console.group('[Sync] Tally XML Payload')
  console.log('URL:', tallyUrl)
  console.log('XML (copy with: copy(window.__lastTallyXml)):\n', xml)
  console.groupEnd()
  // Attach to window so you can run copy(window.__lastTallyXml) in console to get the full XML
  ;(window as unknown as Record<string, unknown>).__lastTallyXml = xml
  const result = await sendToExtension<TallySyncResult>('SYNC_TO_TALLY', { xml, tallyUrl })
  console.log('[Sync] Tally response:', result)
  return result
}
