import axios from 'axios'
import type { DashboardSettings } from '@/types'
import type { TallyVoucher, SlowStockItem, DebtorBalance } from '@/services/tallyService'

export const api = axios.create({ baseURL: '/api' })

export async function getNextVoucherCounter(companyId: string): Promise<number> {
  const { data } = await api.post<{ counter: number }>(`/companies/${companyId}/voucher-counter/next`)
  return data.counter
}

// Attach JWT from localStorage on every request
api.interceptors.request.use((config) => {
  const raw = localStorage.getItem('tally-auth')
  if (raw) {
    try {
      const { state } = JSON.parse(raw)
      if (state?.token) config.headers.Authorization = `Bearer ${state.token}`
    } catch { /* ignore */ }
  }
  return config
})

export async function fetchSalesTargets(
  companyId: string,
  fyYear: number,
): Promise<{ month: number; target: number }[]> {
  const { data } = await api.get(`/companies/${companyId}/targets`, { params: { fyYear } })
  return data
}

export async function saveSalesTargets(
  companyId: string,
  fyYear: number,
  targets: { month: number; target: number }[],
): Promise<void> {
  await api.put(`/companies/${companyId}/targets`, { fyYear, targets })
}

export async function fetchDashboardSettings(companyId: string): Promise<DashboardSettings> {
  const { data } = await api.get(`/companies/${companyId}/dashboard-settings`)
  return data
}

export async function saveDashboardSettings(companyId: string, settings: DashboardSettings): Promise<void> {
  await api.put(`/companies/${companyId}/dashboard-settings`, settings)
}

// Cached vouchers — read-only, never touches Tally. `fetchedDates` tells apart
// "genuinely no vouchers that day" from "never fetched" for empty-state UI.
export async function fetchCachedVouchers(
  companyId: string,
  from: string,
  to: string,
): Promise<{ vouchers: TallyVoucher[]; fetchedDates: string[] }> {
  const { data } = await api.get(`/companies/${companyId}/vouchers`, { params: { from, to } })
  return data
}

export interface SaveVouchersFailure {
  voucherNo:   string
  type:        string
  date:        string
  party:       string
  identityKey: string
  alterId:     string
  error:       string
}

// Persists a live Tally fetch (Apply or the voucher-saved notify) — append-only by identityKey/alterId.
// Each voucher is saved independently server-side, so a bad voucher shows up in `failures`
// instead of silently taking the whole batch down with it.
export async function saveVouchers(
  companyId: string,
  from: string,
  to: string,
  vouchers: TallyVoucher[],
): Promise<{ inserted: number; skipped: number; failed: number; failures: SaveVouchersFailure[] }> {
  const { data } = await api.post(`/companies/${companyId}/vouchers`, { from, to, vouchers })
  return data
}

export interface DashboardSnapshotPatch {
  cashInHand?:         number | null
  bankBalance?:        number | null
  receivables?:        number | null
  payables?:           number | null
  openingStock?:       number | null
  closingStock?:       number | null
  directExpenseTotal?: number | null
  dioDirectExpenseTotal?: number | null
  slowStockItems?:     SlowStockItem[]
  debtorBalances?:     DebtorBalance[]
  equity?:             number | null
  investments?:        number | null
  currentLiabilities?: number | null
  fixedAssets?:        number | null
  totalLoans?:         number | null
  bankOD?:             number | null
  longTermBorrowings?: number | null
  roceEquity?:         number | null
  roeEquity?:          number | null
  internalBorrowings?: number | null
  intangibleAssets?:   number | null
  debtEquityLoans?:    number | null
  debtEquityCash?:     number | null
  debtEquityBank?:     number | null
  debtEquityEquity?:   number | null
  interestExpenseTotal?:        number | null
  taxPaymentTotal?:             number | null
  nonOperatingIncomeTotal?:     number | null
  nonOperatingInvestmentTotal?: number | null
  directorLoansTotal?:          number | null
}

export interface DashboardSnapshotData extends DashboardSnapshotPatch {
  fetchedAt: string
}

// "Current value" cache for Tally queries that can't be scoped to a past date
// (closing balances, receivables/payables, stock value, slow-stock).
export async function fetchDashboardSnapshot(companyId: string): Promise<DashboardSnapshotData | null> {
  const { data } = await api.get(`/companies/${companyId}/dashboard-snapshot`)
  return data
}

export async function saveDashboardSnapshot(companyId: string, patch: DashboardSnapshotPatch): Promise<void> {
  await api.put(`/companies/${companyId}/dashboard-snapshot`, patch)
}

// On 401, clear auth and redirect to login
api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('tally-auth')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  },
)
