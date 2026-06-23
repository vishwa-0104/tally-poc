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

export interface TallyVoucher {
  date:            string
  type:            string
  party:           string
  amount:          number  // total including GST (party ledger value)
  taxableAmount:   number  // amount minus CGST/SGST/IGST/Cess
  voucherNo:       string
  hasSalesLedger?: boolean // true when a configured sales account ledger appears in this voucher
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
  salesAccounts?:        string[]
  salesIncludeVouchers?: string[]
  salesExcludeVouchers?: string[]
  cashInflowLedgers?:    string[]
  bankLedgers?:          string[]
}

export async function fetchDaybook(
  fromDate: string,
  toDate: string,
  tallyUrl: string,
  tallyCompany?: string,
  options: DaybookOptions = {},
): Promise<{ vouchers: TallyVoucher[]; rawXml: string; cashFlow: CashBankFlow; bankFlow: CashBankFlow; topItems: TopItem[] }> {
  const result = await sendToExtension<{ vouchers: TallyVoucher[]; rawXml: string; cashFlow: CashBankFlow; bankFlow: CashBankFlow; topItems: TopItem[] }>('FETCH_DAYBOOK', {
    fromDate, toDate, tallyUrl, tallyCompany,
    salesAccounts:        options.salesAccounts        ?? [],
    salesIncludeVouchers: options.salesIncludeVouchers ?? [],
    salesExcludeVouchers: options.salesExcludeVouchers ?? [],
    cashInflowLedgers:    options.cashInflowLedgers    ?? [],
    bankLedgers:          options.bankLedgers          ?? [],
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

export async function fetchGroupBalances(
  tallyUrl: string,
  tallyCompany?: string,
  asOfDate?: string,   // YYYYMMDD — ignored by Tally, always returns current date balance
): Promise<{ receivables: number; payables: number }> {
  return sendToExtension<{ receivables: number; payables: number }>('FETCH_GROUP_BALANCES', {
    tallyUrl, tallyCompany, asOfDate,
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
