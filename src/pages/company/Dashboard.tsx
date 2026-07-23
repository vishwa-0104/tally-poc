import { useState, useCallback, useEffect, useRef } from 'react'
import { toast } from 'react-hot-toast'
import {
  TrendingUp, AlertCircle,
  Lightbulb, AlertTriangle,
  RefreshCw, Download, Zap,
  CalendarDays, Package, Clock, Scale, LineChart, Landmark,
} from 'lucide-react'
import { useAuthStore, useCompanyStore, useDaybookSyncStore } from '@/store'
import { fetchDaybook, fetchSlowMovingStock, fetchLedgerBalances, fetchGroupBalances, fetchStockValue, fetchLedgerAmounts, fetchTallyStockItems, fetchDebtorBalances, type SlowStockItem, type TallyVoucher, type TopItem, type SalesPartyRow, type DebtorBalance } from '@/services/tallyService'
import {
  fetchSalesTargets, fetchDashboardSettings,
  fetchCachedVouchers, saveVouchers, fetchDashboardSnapshot, saveDashboardSnapshot,
  fetchCfoSuggestions, type DashboardSnapshotPatch, type CfoReport, type CfoKpis,
} from '@/lib/api'
import type { DashboardSettings } from '@/types'
import { getTallyUrl } from './CompanySettings'
import { formatCurrency, formatDate } from '@/lib/utils'
import { useExtensionStatus } from '@/hooks/useExtension'
import { classifyVouchers, computeCreditSalesTotal } from '@/lib/voucherClassification'
import { SalesWidget } from '@/shadcn/components/dashboard/sales-widget'
import { SalesChartWidget } from '@/shadcn/components/dashboard/sales-chart-widget'
import { CashWidget } from '@/shadcn/components/dashboard/cash-widget'
import { BankWidget } from '@/shadcn/components/dashboard/bank-widget'
import { ReceivablesWidget } from '@/shadcn/components/dashboard/receivables-widget'
import { PayablesWidget } from '@/shadcn/components/dashboard/payables-widget'
import { DebtorsWidget } from '@/shadcn/components/dashboard/debtors-widget'
import { ItemsWidget } from '@/shadcn/components/dashboard/items-widget'
import { GrossMarginWidget } from '@/shadcn/components/dashboard/gross-margin-widget'
import { EbitdaWidget } from '@/shadcn/components/dashboard/ebitda-widget'
import { NetMarginWidget } from '@/shadcn/components/dashboard/net-margin-widget'
import { StocksWidget } from '@/shadcn/components/dashboard/stocks-widget'
import { RatioWidget } from '@/shadcn/components/dashboard/ratio-widget'
import { Switch } from '@/shadcn/components/ui/switch'
import { CompanyPageHeader } from '@/shadcn/components/company-page-header'
import { FormatProvider } from '@/shadcn/lib/format-context'

// ── Types ─────────────────────────────────────────────────────────────────────

type Tab           = 'performance' | 'analysis' | 'cfo'
type FilterPreset  = 'today' | 'quarter' | 'ytd' | 'custom'

// ── Date helpers ──────────────────────────────────────────────────────────────

function toTallyDate(iso: string) { return iso.replace(/-/g, '') }
const fmt = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const todayStr = () => fmt(new Date())

function getFilterDates(preset: FilterPreset, cfrom: string, cto: string) {
  const today = new Date()
  if (preset === 'today') return { from: fmt(today), to: fmt(today) }
  if (preset === 'quarter') {
    const m = today.getMonth()
    const qs =
      m >= 3 && m <= 5 ? new Date(today.getFullYear(), 3, 1)
      : m >= 6 && m <= 8 ? new Date(today.getFullYear(), 6, 1)
      : m >= 9            ? new Date(today.getFullYear(), 9, 1)
                          : new Date(today.getFullYear(), 0, 1)
    return { from: fmt(qs), to: fmt(today) }
  }
  if (preset === 'ytd') {
    const fyStart = today.getMonth() >= 3
      ? new Date(today.getFullYear(), 3, 1)
      : new Date(today.getFullYear() - 1, 3, 1)
    return { from: fmt(fyStart), to: fmt(today) }
  }
  return { from: cfrom, to: cto }
}

// ── Dashboard settings helpers ────────────────────────────────────────────────

type SalesFilterSettings = {
  salesAccounts?:        string[]
  salesIncludeVouchers?: string[]
  salesExcludeVouchers?: string[]
}

type PurchaseFilterSettings = {
  purchaseAccounts?:        string[]
  purchaseIncludeVouchers?: string[]
  purchaseExcludeVouchers?: string[]
}

function computePurchaseTotal(vouchers: TallyVoucher[], pf: PurchaseFilterSettings | undefined): number {
  const { purchaseAccounts, purchaseIncludeVouchers, purchaseExcludeVouchers } = pf ?? {}

  // Mirror sales logic: if purchaseAccounts configured, first narrow to vouchers
  // that contain a matching ledger (hasPurchaseLedger set by extension).
  const base = purchaseAccounts?.length ? vouchers.filter(v => !!v.purchaseLedger) : vouchers

  const included = base.filter(v => {
    if (purchaseIncludeVouchers?.length)
      return purchaseIncludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
    return /purchase/i.test(v.type) && !/debit\s*note/i.test(v.type)
  })

  const excluded = base.filter(v => {
    if (purchaseExcludeVouchers?.length)
      return purchaseExcludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
    return /debit\s*note/i.test(v.type)
  })

  return included.reduce((s, v) => s + v.taxableAmount, 0)
       - excluded.reduce((s, v) => s + v.taxableAmount, 0)
}

function computeSalesTotal(vouchers: TallyVoucher[], sf: SalesFilterSettings | undefined): number {
  const { salesAccounts, salesIncludeVouchers, salesExcludeVouchers } = sf ?? {}

  const base = salesAccounts?.length ? vouchers.filter(v => v.hasSalesLedger) : vouchers

  const included = base.filter(v => {
    if (salesIncludeVouchers?.length)
      return salesIncludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
    return /sales/i.test(v.type) && !/credit\s*note/i.test(v.type)
  })

  const excluded = base.filter(v => {
    if (salesExcludeVouchers?.length)
      return salesExcludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
    return /credit\s*note/i.test(v.type)
  })

  return included.reduce((s, v) => s + v.taxableAmount, 0)
       - excluded.reduce((s, v) => s + v.taxableAmount, 0)
}

// Apr(fyYear) .. current month — each bucket is that month's sales so far
// (the current month is naturally partial since `vouchers` only runs to today).
function bucketSalesTrendMonthly(vouchers: TallyVoucher[], sf: SalesFilterSettings | undefined, fyYear: number): { label: string; amount: number }[] {
  const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  const currentYM = todayStr().slice(0, 7)
  const result: { label: string; amount: number }[] = []
  for (let i = 0; i < 12; i++) {
    const y        = i < 9 ? fyYear : fyYear + 1 // Apr..Dec → fyYear, Jan..Mar → fyYear+1
    const monthIdx = (3 + i) % 12
    const ym       = `${y}-${String(monthIdx + 1).padStart(2, '0')}`
    if (ym > currentYM) break
    result.push({ label: monthNames[monthIdx], amount: computeSalesTotal(vouchers.filter(v => v.date.startsWith(ym)), sf) })
  }
  return result
}

// Last `days` calendar days ending today, one bucket per day even if a day has
// no vouchers at all (shows as a zero bar rather than skipping the day).
function bucketSalesTrendDaily(vouchers: TallyVoucher[], sf: SalesFilterSettings | undefined, days: number): { label: string; amount: number }[] {
  const result: { label: string; amount: number }[] = []
  for (let i = days - 1; i >= 0; i--) {
    const d   = new Date()
    d.setDate(d.getDate() - i)
    const iso = fmt(d)
    result.push({
      label:  d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' }),
      amount: computeSalesTotal(vouchers.filter(v => v.date === iso), sf),
    })
  }
  return result
}

// ── Target helpers ────────────────────────────────────────────────────────────

function getCurrentFyYear() {
  const today = new Date()
  return today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1
}

// Current Ratio / Quick Ratio — sum the user-picked Tally GROUP names' own
// closing balances (magnitude, same convention as every other "how much"
// ledger-list setting here) out of the full group list already fetched by
// fetchGroupBalances. null when the setting itself is empty (never guess);
// a picked name Tally doesn't return just contributes 0, matching how an
// unmatched ledger name in fetchLedgerAmounts silently contributes nothing.
function sumGroupBalances(
  allGroups: { name: string; balance: number }[] | undefined,
  groupNames: string[] | undefined,
): number | null {
  if (!groupNames?.length || !allGroups) return null
  return groupNames.reduce((sum, name) => {
    const match = allGroups.find(g => g.name.toLowerCase() === name.toLowerCase())
    return sum + (match ? Math.abs(match.balance) : 0)
  }, 0)
}

// DSO/DIO/DPO's "YTD days" multiplier option — days elapsed since the FY
// start (1-Apr) as of the given date, inclusive of both ends (e.g. 12-Jul
// in an Apr-start FY = 103 days).
function daysSinceFyStart(toDateStr: string): number {
  const to = new Date(toDateStr)
  const fyYear = to.getMonth() >= 3 ? to.getFullYear() : to.getFullYear() - 1
  const fyStart = new Date(fyYear, 3, 1)
  return Math.floor((to.getTime() - fyStart.getTime()) / 86400000) + 1
}

function getQuarterMonths(): number[] {
  const m = new Date().getMonth()
  if (m >= 3 && m <= 5) return [4, 5, 6]
  if (m >= 6 && m <= 8) return [7, 8, 9]
  if (m >= 9)           return [10, 11, 12]
  return [1, 2, 3]
}

// Returns months if custom dates align to one or more complete calendar months, else null
function getMonthsForCustom(from: string, to: string): number[] | null {
  const [fy, fm, fd] = from.split('-').map(Number)
  const [ty, tm, td] = to.split('-').map(Number)
  if (fd !== 1) return null
  // last day of the `to` month
  if (td !== new Date(ty, tm, 0).getDate()) return null
  const months: number[] = []
  let y = fy, m = fm
  while (y < ty || (y === ty && m <= tm)) {
    months.push(m)
    m++; if (m > 12) { m = 1; y++ }
  }
  return months.length > 0 ? months : null
}

function computeTargetForPeriod(
  preset: FilterPreset,
  customFrom: string,
  customTo: string,
  targets: Record<number, number>,
): number | null {
  let months: number[] | null = null
  if (preset === 'today')   return null
  if (preset === 'quarter') months = getQuarterMonths()
  if (preset === 'ytd')     months = [1,2,3,4,5,6,7,8,9,10,11,12]
  if (preset === 'custom')  months = getMonthsForCustom(customFrom, customTo)
  if (!months) return null
  const sum = months.reduce((s, m) => s + (targets[m] ?? 0), 0)
  return sum > 0 ? sum : null
}

// ── Main component ────────────────────────────────────────────────────────────

const TABS: { key: Tab; label: string }[] = [
  { key: 'performance', label: 'Performance'     },
  { key: 'analysis',    label: 'KPI Analytics'     },
  { key: 'cfo',         label: 'CFO Suggestions' },
]

// 'ytd' (monthly view) and 'custom' tabs are hidden for now — keep the
// underlying logic/state intact, just don't render the buttons.
const FILTERS: { key: FilterPreset; label: string }[] = [
  { key: 'today',   label: 'Today'        },
  { key: 'ytd',     label: 'Year to Date (YTD)'          },
  { key: 'custom',  label: 'Custom'       }
]

// Analysis tab's own filter — independent of the Performance tab's FILTERS/
// filterPreset state above, so switching one never affects the other.
const ANALYSIS_FILTERS: { key: FilterPreset; label: string }[] = [
  { key: 'ytd',    label: 'Year to Date (YTD)'    },
]

// Raw inputs behind the 9 ratio KPIs. null = genuinely unavailable (never a
// fabricated number) — every ratio card checks its own required inputs and
// renders "No data available" if any are null, rather than guessing.
interface AnalysisInputs {
  debtors:                     number | null
  creditors:                   number | null
  creditSales:                 number | null
  openingStock:                number | null
  closingStock:                number | null
  // DIO/DPO each have their own dedicated Purchases figure (and DIO its own
  // Direct Expenses) — deliberately separate from Gross Margin/Net Profit's
  // own purchaseTotal/directExpenses local variables elsewhere in this file.
  dioPurchases:                number | null
  dioDirectExpenses:           number | null
  dpoPurchases:                number | null
  // Current Ratio / Quick Ratio — user-picked ledger list sums, replacing
  // the old fixed group-balance figures (Stock/Debtors/Creditors reuse for
  // Current Ratio, Cash/Bank/Investments/CurrentLiabilities/BankOD for
  // Quick Ratio). Each ratio gets its own dedicated numerator/denominator.
  currentRatioAssets:          number | null
  currentRatioLiabilities:     number | null
  quickRatioAssets:            number | null
  quickRatioLiabilities:       number | null
  // ROCE-only "Long Term Borrowings" and Equity — every ratio below has its
  // own dedicated figures rather than sharing one Capital-Account/Loans-
  // (Liability) group value.
  longTermBorrowings:          number | null
  roceEquity:                  number | null
  netProfit:                   number | null
  interestExpense:             number | null
  taxPayment:                  number | null
  nonOperatingIncome:          number | null
  nonOperatingInvestment:      number | null
  directorLoans:               number | null
  // ROE
  roeEquity:                   number | null
  internalBorrowings:          number | null
  intangibleAssets:            number | null
  // Debt/Equity
  debtEquityLoans:             number | null
  debtEquityCash:              number | null
  debtEquityBank:              number | null
  debtEquityEquity:            number | null
}

const emptyAnalysisInputs: AnalysisInputs = {
  debtors: null, creditors: null, creditSales: null, openingStock: null, closingStock: null,
  dioPurchases: null, dioDirectExpenses: null, dpoPurchases: null,
  currentRatioAssets: null, currentRatioLiabilities: null, quickRatioAssets: null, quickRatioLiabilities: null,
  longTermBorrowings: null, roceEquity: null,
  netProfit: null, interestExpense: null, taxPayment: null, nonOperatingIncome: null,
  nonOperatingInvestment: null, directorLoans: null,
  roeEquity: null, internalBorrowings: null, intangibleAssets: null,
  debtEquityLoans: null, debtEquityCash: null, debtEquityBank: null, debtEquityEquity: null,
}

interface RatioResults {
  dso:         number | null
  dio:         number | null
  dpo:         number | null
  ccc:         number | null
  currentRatio: number | null
  quickRatio:  number | null
  roce:        number | null
  roe:         number | null
  debtEquity:  number | null
}

// Pure derivation from AnalysisInputs — every ratio individually null-guards
// its own required inputs so one missing figure never silently zeroes or
// skews a different card. `days` is each ratio's own configurable
// multiplier (YTD days elapsed by default, or a fixed 365 if configured) —
// see daysSinceFyStart above and the render call site for how it's resolved.
function computeRatios(i: AnalysisInputs, days: { dso: number; dio: number; dpo: number }): RatioResults {
  const dso = i.debtors != null && i.creditSales
    ? (i.debtors / i.creditSales) * days.dso : null

  const cogs = i.openingStock != null && i.dioPurchases != null && i.dioDirectExpenses != null && i.closingStock != null
    ? i.openingStock + i.dioPurchases + i.dioDirectExpenses - i.closingStock : null
  const dio = i.closingStock != null && cogs
    ? (i.closingStock / cogs) * days.dio : null

  const dpo = i.creditors != null && i.dpoPurchases
    ? (i.creditors / i.dpoPurchases) * days.dpo : null

  const ccc = dso != null && dio != null && dpo != null ? dso + dio - dpo : null

  // Current Ratio / Quick Ratio — both fully user-configured now (own
  // Assets/Liabilities ledger lists), replacing the old fixed group-balance
  // math. Denominator is required (no data → "No data available" rather
  // than a divide-by-zero or a fabricated number).
  const currentRatio = i.currentRatioAssets != null && i.currentRatioLiabilities
    ? i.currentRatioAssets / i.currentRatioLiabilities : null

  const quickRatio = i.quickRatioAssets != null && i.quickRatioLiabilities
    ? i.quickRatioAssets / i.quickRatioLiabilities : null

  // Tax Payment, Long Term Borrowings, and Non-Operating Investment default
  // to 0 when their ledger-list setting is left empty — per the user, these
  // three are legitimately zero for companies with no such activity, unlike
  // Equity/Net Profit/Interest Expense/Non-Operating Income below, which stay
  // strictly null-gated ("No data available") since a real company is never
  // actually zero on those, and silently defaulting them to 0 would badly
  // distort ROCE rather than just omitting it.
  // EBIT = Net Profit + Interest Expense + Tax Payment (Net Profit is after
  // interest/tax are deducted, so they're added back, not subtracted again)
  const ebit = i.netProfit != null && i.interestExpense != null
    ? i.netProfit + i.interestExpense + (i.taxPayment ?? 0) : null
  const roceNumerator = ebit != null && i.nonOperatingIncome != null ? ebit - i.nonOperatingIncome : null
  const roceDenominator = i.roceEquity != null
    ? i.roceEquity + (i.longTermBorrowings ?? 0) - (i.nonOperatingInvestment ?? 0) : null
  // Equity ledgers now preserve their true sign (see fetchLedgerTotal's
  // 'equity' mode) — a company with genuinely negative equity (accumulated
  // losses exceeding capital) would flip the ratio's sign into something
  // that reads as "healthy" when it's the opposite. Never divide by a
  // zero-or-negative denominator here — show "No data available" instead.
  const roce = roceNumerator != null && roceDenominator != null && roceDenominator > 0
    ? (roceNumerator / roceDenominator) * 100 : null

  // ROE numerator reuses the existing Net Profit (YTD) figure — no separate
  // setting. Internal Borrowings/Intangible Assets default to 0 when
  // unconfigured (commonly genuinely zero); Equity stays required.
  const roeDenominator = i.roeEquity != null
    ? i.roeEquity + (i.internalBorrowings ?? 0) - (i.intangibleAssets ?? 0) : null
  const roe = i.netProfit != null && roeDenominator != null && roeDenominator > 0
    ? (i.netProfit / roeDenominator) * 100 : null

  // Every Debt/Equity component is its own dedicated setting now (Loans,
  // Cash, Bank, Equity, Director Loans) — independent of the shared
  // group-balance cash/bank/equity/totalLoans figures used elsewhere. Loans
  // and Equity are the two figures that define what this ratio even means,
  // so they stay required; Cash/Bank/Director Loans default to 0 since many
  // companies genuinely have none to net out.
  const debtEquityNumerator = i.debtEquityLoans != null
    ? i.debtEquityLoans - (i.debtEquityCash ?? 0) - (i.debtEquityBank ?? 0) : null
  const debtEquityDenominator = i.debtEquityEquity != null
    ? i.debtEquityEquity + (i.directorLoans ?? 0) : null
  const debtEquity = debtEquityNumerator != null && debtEquityDenominator != null && debtEquityDenominator > 0
    ? debtEquityNumerator / debtEquityDenominator : null

  return { dso, dio, dpo, ccc, currentRatio, quickRatio, roce, roe, debtEquity }
}

// ── CFO report helpers ───────────────────────────────────────────────────────
// All deterministic — thresholds inferred from the sample Executive Financial
// Summary report this section was built to match. No AI involvement: the
// numbers driving these bands are already real (computeRatios/loadFromDb),
// so the assessment text is just a plain-language readout of a real number,
// never a model-generated figure.

function formatCompactLakhs(value: number): string {
  if (Math.abs(value) < 100000) return formatCurrency(value)
  const lakhs = value / 100000
  return `${lakhs < 0 ? '-' : ''}₹${Math.abs(lakhs).toFixed(2)}L`
}

// Net Profit is structurally derived from Gross Margin minus opex/tax, so it
// should sit at or below it. Net Profit % exceeding Gross Margin % at all
// (not by some minimum gap) is itself the anomaly — it means indirect/
// non-operating income is carrying the business, not core trading.
function hasMarginAnomaly(grossMarginPct: number | null, netProfitPct: number | null): boolean {
  if (grossMarginPct == null || netProfitPct == null) return false
  return netProfitPct > grossMarginPct
}

function dsoAssessment(v: number | null): string {
  if (v == null) return 'No data available'
  if (v <= 30) return 'Fast collection cycle — debtors are converting to cash quickly.'
  if (v <= 45) return `Reasonable collection period; realization from debtors takes ~${v.toFixed(0)} days.`
  if (v <= 60) return 'Elevated. Tighten credit terms and follow up on outstanding collections.'
  return 'Extremely prolonged. Working capital is trapped in receivables.'
}
function dioAssessment(v: number | null): string {
  if (v == null) return 'No data available'
  if (v <= 30) return 'Efficient stock turnover; inventory holds for about a month on average.'
  if (v <= 60) return 'Moderate. Within typical trading norms.'
  if (v <= 90) return 'Elevated. Review slow-moving stock and reorder cadence.'
  return 'Excessive. Capital is tied up in inventory for too long.'
}
function dpoAssessment(v: number | null): string {
  if (v == null) return 'No data available'
  if (v <= 30) return 'Short payment cycle. Limited use of supplier credit.'
  if (v <= 60) return 'Reasonable reliance on supplier credit.'
  return 'Extremely prolonged. The company is heavily leaning on supplier credit to fund operations.'
}
function cccAssessment(v: number | null): string {
  if (v == null) return 'No data available'
  if (v <= 0) return 'Mathematically favorable, but check whether this is driven by delayed supplier payouts.'
  if (v <= 45) return 'Efficient cash conversion cycle.'
  if (v <= 90) return 'Moderate. The working capital cycle is lengthening.'
  return 'Extended. Significant cash is locked in the operating cycle.'
}
function roceAssessment(v: number | null): string {
  if (v == null) return 'No data available'
  if (v < 10) return 'Weak capital efficiency. Returns barely cover the cost of capital.'
  if (v < 20) return 'Moderate capital efficiency.'
  return 'High capital efficiency, though check whether this is due to a low overall capital asset base.'
}
function roeAssessment(v: number | null): string {
  if (v == null) return 'No data available'
  if (v < 10) return 'Weak returns for equity stakeholders.'
  if (v < 20) return 'Reasonable return for equity stakeholders.'
  return 'Robust return for equity stakeholders — check leverage via current obligations.'
}
function quickRatioNote(v: number | null): string {
  if (v == null) return 'No data available'
  if (v < 0.5) return 'Severe Liquid Stress'
  if (v < 1.0) return 'Below comfortable threshold'
  return 'Healthy quick liquidity'
}
function flowNote(inflow: number | null, outflow: number | null): string {
  if (inflow == null || outflow == null) return 'No data available'
  if (inflow === outflow) return `Inflow: ${formatCurrency(inflow)} | Outflow: ${formatCurrency(outflow)}`
  const diff = formatCurrency(Math.abs(inflow - outflow))
  const cmp = inflow < outflow ? `Inflow < Outflow by ${diff}` : `Inflow > Outflow by ${diff}`
  return `Inflow: ${formatCurrency(inflow)} | Outflow: ${formatCurrency(outflow)} · ${cmp}`
}

// Report-style stat card — centered layout with a full-tone background,
// matching the reference Executive Financial Summary report (as opposed to
// the dashboard's left-aligned top-border StatCard used elsewhere).
function ReportStatCard({ label, value, sub, tone = 'blue' }: {
  label: string
  value: string
  sub?:  string
  tone?: 'blue' | 'green' | 'danger'
}) {
  const styles = {
    blue:   { wrap: 'bg-muted border-border', value: 'text-brand-600',   sub: 'text-muted-foreground' },
    green:  { wrap: 'bg-muted border-border', value: 'text-emerald-600', sub: 'text-muted-foreground' },
    danger: { wrap: 'bg-red-50 border-red-200',   value: 'text-red-600',    sub: 'text-red-600'  },
  }[tone]
  return (
    <div className={`rounded-xl border p-4 text-center ${styles.wrap}`}>
      <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider mb-1.5">{label}</p>
      <p className={`text-2xl font-bold leading-tight ${styles.value}`}>{value}</p>
      {sub && <p className={`text-[11px] mt-1.5 leading-snug ${styles.sub}`}>{sub}</p>}
    </div>
  )
}

// Numbered section heading with a small blue accent bar, matching the
// reference report's "1. Key Financial Metrics" style headings.
function ReportSectionHeading({ n, title }: { n: number; title: string }) {
  return (
    <div className="flex items-center gap-2 mb-2">
      <div className="w-1 h-4 bg-brand-600 rounded-sm shrink-0" />
      <p className="text-sm font-bold text-foreground">{n}. {title}</p>
    </div>
  )
}

// Splits an AI-generated action item on its first "Title: description"
// colon (the prompt now asks for this shape) so the lead phrase can be
// bolded like the reference report. Falls back to plain text if the model
// didn't include a colon.
function renderActionItem(item: string) {
  const idx = item.indexOf(': ')
  if (idx === -1) return <span>{item}</span>
  return (
    <>
      <span className="font-semibold text-foreground">{item.slice(0, idx + 1)}</span>
      <span>{item.slice(idx + 1)}</span>
    </>
  )
}

export default function Dashboard() {
  const { activeCompanyId } = useAuthStore()
  const { getCompany }       = useCompanyStore()
  const { connected }        = useExtensionStatus()

  const companyId    = activeCompanyId ?? ''
  const company      = getCompany(companyId)
  const tallyUrl     = getTallyUrl(companyId, company?.port)
  const tallyCompany = company?.name ?? undefined

  const fyYear = getCurrentFyYear()
  const todayLabel = new Date().toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })

  const [compactFormat,   setCompactFormat]   = useState(true)
  const [activeTab,       setActiveTab]       = useState<Tab>('performance')
  const [filterPreset,    setFilterPreset]    = useState<FilterPreset>('today')
  const [customFrom,      setCustomFrom]      = useState(todayStr())
  const [customTo,        setCustomTo]        = useState(todayStr())
  const [monthlyTargets,  setMonthlyTargets]  = useState<Record<number, number>>({})

  const [dashboardSettings, setDashboardSettings] = useState<DashboardSettings>({})

  const [cashInflow,  setCashInflow]  = useState<number | null>(null)
  const [cashOutflow, setCashOutflow] = useState<number | null>(null)
  const [cashInHand,  setCashInHand]  = useState<number | null>(null)

  const [bankInflow,   setBankInflow]   = useState<number | null>(null)
  const [bankOutflow,  setBankOutflow]  = useState<number | null>(null)
  const [bankBalance,  setBankBalance]  = useState<number | null>(null)

  const [receivables, setReceivables] = useState<number | null>(null)
  const [payables,    setPayables]    = useState<number | null>(null)
  const [topItems,      setTopItems]      = useState<TopItem[]>([])
  const [topDebtors,    setTopDebtors]    = useState<SalesPartyRow[]>([])
  const [grossMargin,    setGrossMargin]    = useState<number | null>(null)
  const [grossMarginPct, setGrossMarginPct] = useState<number | null>(null)
  const [ebitda,         setEbitda]         = useState<number | null>(null)
  const [ebitdaPct,      setEbitdaPct]      = useState<number | null>(null)
  const [netProfit,      setNetProfit]      = useState<number | null>(null)
  const [netProfitPct,   setNetProfitPct]   = useState<number | null>(null)

  const [total,             setTotal]             = useState(0)
  const [prevDaySales,      setPrevDaySales]      = useState<number | null>(null)
  const [salesTrend,        setSalesTrend]        = useState<{ label: string; amount: number }[]>([])
  const [slowStock,         setSlowStock]         = useState<SlowStockItem[]>([])
  const [exportingSlowStock, setExportingSlowStock] = useState(false)
  const [exportingItems,     setExportingItems]     = useState(false)
  const [exportingDebtors,   setExportingDebtors]   = useState(false)
  const [exportingPurchases, setExportingPurchases] = useState(false)
  const [purchaseVouchers,  setPurchaseVouchers]  = useState<(TallyVoucher & { role: 'Included' | 'Excluded' })[]>([])
  const [loading,       setLoading]       = useState(false)
  const [fetched,       setFetched]       = useState(false)
  const [error,         setError]         = useState<string | null>(null)
  const [activePeriod,  setActivePeriod]  = useState<{ from: string; to: string } | null>(null)
  const [uncachedRange, setUncachedRange] = useState(false) // true when the DB has never seen this range — hints "click Apply"
  const [lastFetchedAt, setLastFetchedAt] = useState<Date | null>(null) // set only by an explicit Fetch Live click, cleared only by the next one

  // ── Analysis tab — fully independent filter/state from the Performance tab above ──
  const [analysisFilterPreset, setAnalysisFilterPreset] = useState<FilterPreset>('ytd')
  const [analysisCustomFrom,   setAnalysisCustomFrom]   = useState(todayStr())
  const [analysisCustomTo,     setAnalysisCustomTo]     = useState(todayStr())
  const [analysisLoading,      setAnalysisLoading]      = useState(false)
  const [analysisFetched,      setAnalysisFetched]      = useState(false)
  const [analysisUncachedRange, setAnalysisUncachedRange] = useState(false)
  const [analysisLastFetchedAt, setAnalysisLastFetchedAt] = useState<Date | null>(null) // set only by an explicit Fetch Live click, cleared only by the next one
  const [analysisActivePeriod, setAnalysisActivePeriod] = useState<{ from: string; to: string } | null>(null)
  const [analysisInputs,       setAnalysisInputs]       = useState<AnalysisInputs>(emptyAnalysisInputs)

  // CFO Suggestions tab — AI-generated report, always computed from a fresh
  // YTD read (loadFromDb/loadAnalysisFromDb below), independent of whatever
  // period is currently selected on the Performance/Analysis tabs. cfoKpis
  // holds the raw YTD data the report's tables render directly (monthly
  // sales, top items/debtors, debtor balances, slow stock) — never
  // regenerated by the AI, to avoid numeric drift.
  const [cfoReport,      setCfoReport]      = useState<CfoReport | null>(null)
  const [cfoKpis,        setCfoKpis]        = useState<CfoKpis | null>(null)
  const [cfoRatios,      setCfoRatios]      = useState<RatioResults | null>(null)
  const [cfoLoading,     setCfoLoading]     = useState(false)
  const [cfoError,       setCfoError]       = useState(false)
  const [cfoGeneratedAt, setCfoGeneratedAt] = useState<Date | null>(null)

  // Sales-card trend chart. YTD buckets the already-fetched `all` vouchers by
  // month — no extra call. Today needs history beyond the single day already
  // in scope, so it reads the last 10 days from the DB cache only (same
  // "comparison data never needs a live Tally call" reasoning as prevDaySales
  // in loadFromDb) — it'll fill in day by day as the cache accumulates.
  // Custom is left alone for now.
  const updateSalesTrend = useCallback(async (preset: FilterPreset, all: TallyVoucher[], sf: SalesFilterSettings | undefined): Promise<{ label: string; amount: number }[]> => {
    if (preset === 'ytd') {
      const trend = bucketSalesTrendMonthly(all, sf, getCurrentFyYear())
      setSalesTrend(trend)
      return trend
    }
    if (preset === 'today' && companyId) {
      const start = new Date()
      start.setDate(start.getDate() - 9)
      try {
        const { vouchers: trendVouchers } = await fetchCachedVouchers(companyId, fmt(start), todayStr())
        const trend = bucketSalesTrendDaily(trendVouchers, sf, 10)
        setSalesTrend(trend)
        return trend
      } catch {
        setSalesTrend([])
        return []
      }
    }
    setSalesTrend([])
    return []
  }, [companyId])

  const fetchData = useCallback(async (preset: FilterPreset, cfrom: string, cto: string, settingsOverride?: DashboardSettings) => {
    const settings = settingsOverride ?? dashboardSettings
    if (!connected) {
      toast.error('Tally not connected. Please ensure the extension is installed and Tally is open.')
      return
    }
    const { from, to } = getFilterDates(preset, cfrom, cto)

    const salesSettings = settings.today

    setLoading(true)
    setError(null)
    setTopDebtors([])
    setGrossMargin(null)
    setGrossMarginPct(null)
    setEbitda(null)
    setEbitdaPct(null)
    setNetProfit(null)
    setNetProfitPct(null)
    try {
      const { vouchers: all, cashFlow: daybookCashFlow, bankFlow: daybookBankFlow, topItems: fetchedTopItems, indExpTotal, indIncTotal, ebitdaAddback } = await fetchDaybook(
        toTallyDate(from), toTallyDate(to), tallyUrl, tallyCompany,
        {
          salesAccounts:           salesSettings?.salesAccounts,
          salesIncludeVouchers:    salesSettings?.salesIncludeVouchers,
          salesExcludeVouchers:    salesSettings?.salesExcludeVouchers,
          cashInflowLedgers:       settings.today?.cashInflowLedgers,
          bankLedgers:             settings.today?.bankLedgers,
          purchaseAccounts:        settings.ytd?.purchaseAccounts,
          indirectExpenseLedgers:         settings.ytd?.indirectExpenseLedgers,
          indirectExpenseIncludeVouchers: settings.ytd?.indirectExpenseIncludeVouchers,
          indirectExpenseExcludeVouchers: settings.ytd?.indirectExpenseExcludeVouchers,
          indirectIncomeLedgers:          settings.ytd?.indirectIncomeLedgers,
          indirectIncomeIncludeVouchers:  settings.ytd?.indirectIncomeIncludeVouchers,
          indirectIncomeExcludeVouchers:  settings.ytd?.indirectIncomeExcludeVouchers,
          ebitdaLedgers:                  settings.ytd?.ebitdaLedgers,
          ebitdaIncludeVouchers:          settings.ytd?.ebitdaIncludeVouchers,
          ebitdaExcludeVouchers:          settings.ytd?.ebitdaExcludeVouchers,
        },
      )
      setTopItems(fetchedTopItems ?? [])

      const pf = settings.ytd as PurchaseFilterSettings | undefined
      const { purchaseAccounts, purchaseIncludeVouchers, purchaseExcludeVouchers } = pf ?? {}

      // XLS export — all purchase-type vouchers by type (no ledger filter)
      const pvIncluded = all
        .filter(v => purchaseIncludeVouchers?.length
          ? purchaseIncludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /purchase/i.test(v.type) && !/debit\s*note/i.test(v.type))
        .map(v => ({ ...v, role: 'Included' as const }))
      const pvExcluded = all
        .filter(v => purchaseExcludeVouchers?.length
          ? purchaseExcludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /debit\s*note/i.test(v.type))
        .map(v => ({ ...v, role: 'Excluded' as const }))
      setPurchaseVouchers([...pvIncluded, ...pvExcluded].sort((a, b) => a.date.localeCompare(b.date)))

      const todaySalesTotal = computeSalesTotal(all, salesSettings)
      setTotal(todaySalesTotal)
      setActivePeriod({ from, to })
      void updateSalesTrend(preset, all, salesSettings)

      const purchaseTotal = preset === 'ytd' ? computePurchaseTotal(all, settings.ytd) : 0

      // ── Purchase summary (flat console.log — visible in extension service worker) ──
      if (preset === 'ytd') {
        const typeCount: Record<string, number> = {}
        for (const v of all) typeCount[v.type] = (typeCount[v.type] ?? 0) + 1
        const typeStr = Object.entries(typeCount).map(([t, n]) => `${t}(${n})`).join(', ') || 'NONE'

        // Gross margin set = type-filtered AND ledger-filtered (mirrors computePurchaseTotal)
        const base       = purchaseAccounts?.length ? all.filter(v => !!v.purchaseLedger) : all
        const gmIncluded = base.filter(v => purchaseIncludeVouchers?.length
          ? purchaseIncludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /purchase/i.test(v.type) && !/debit\s*note/i.test(v.type))
        const gmExcluded = base.filter(v => purchaseExcludeVouchers?.length
          ? purchaseExcludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /debit\s*note/i.test(v.type))

        const gmTotal    = gmIncluded.reduce((s, v) => s + v.taxableAmount, 0)
        const debitTotal = gmExcluded.reduce((s, v) => s + v.taxableAmount, 0)

        console.log('=== PURCHASE SUMMARY ===')
        console.log('Voucher types:', typeStr)
        console.log(`Purchase by type  (before ledger filter) : ${pvIncluded.length} vouchers | taxable : ${pvIncluded.reduce((s, v) => s + v.taxableAmount, 0).toFixed(2)}`)
        console.log(`Purchase by ledger (for gross margin)    : ${gmIncluded.length} vouchers | taxable : ${gmTotal.toFixed(2)}${purchaseAccounts?.length ? '' : ' (no Purchase Accounts configured — all used)'}`)
        console.log(`Debit notes                              : ${gmExcluded.length} vouchers | taxable : ${debitTotal.toFixed(2)}`)
        console.log(`Net purchase (gross margin)              : ${purchaseTotal.toFixed(2)}`)
        console.log('--- By purchase ledger ---')
        const byLedger: Record<string, typeof gmIncluded> = {}
        for (const v of gmIncluded) {
          const key = v.purchaseLedger ?? '(all)'
          ;(byLedger[key] ??= []).push(v)
        }
        if (Object.keys(byLedger).length === 0) {
          console.log('  (no purchase vouchers)')
        }
        for (const [ledger, vs] of Object.entries(byLedger)) {
          const total = vs.reduce((s, v) => s + v.taxableAmount, 0)
          console.log(`  [${ledger}]  total: ${total.toFixed(2)}`)
          for (const v of vs.sort((a, b) => a.date.localeCompare(b.date)))
            console.log(`    ${v.date} | ${v.voucherNo} | ${v.party} : ${v.taxableAmount.toFixed(2)}`)
        }
        console.log('--- Debit notes ---')
        if (gmExcluded.length === 0) console.log('  (none)')
        for (const v of gmExcluded)
          console.log(`  ${v.date} | ${v.voucherNo} | ${v.party} : ${v.taxableAmount.toFixed(2)}`)
        console.log('========================')
      }

      console.log('[Sales] Total:', todaySalesTotal, '| preset:', preset, '| from:', from, '| to:', to)

      // 2. Inflow/outflow from daybook (already parsed in background.js — no extra Tally call)
      console.log('[Settings] salesAccounts:', salesSettings?.salesAccounts ?? '(none)', '| include:', salesSettings?.salesIncludeVouchers ?? '(none)', '| exclude:', salesSettings?.salesExcludeVouchers ?? '(none)')
      console.log('[Settings] saved cashInflowLedgers:', settings.today?.cashInflowLedgers ?? '(none — using default: ledgers matching /cash/i)')
      console.log('[Settings] NOTE: outflow uses same cash ledger names as inflow')
      setCashInflow(daybookCashFlow.inflow)
      setCashOutflow(daybookCashFlow.outflow)
      setBankInflow(daybookBankFlow.inflow)
      setBankOutflow(daybookBankFlow.outflow)
      console.log('[CashFlow from Tally] inflow:', daybookCashFlow.inflow, '| outflow:', daybookCashFlow.outflow)
      console.log('[BankFlow from Tally] inflow:', daybookBankFlow.inflow, '| outflow:', daybookBankFlow.outflow)

      // ── XLS-ready voucher dump ──
      const vTsvHeader = 'Date\tVoucher No\tType\tParty\tAmount\tTaxable Amount\tLedger'
      const vTsvRows = all.map(v =>
        `${v.date}\t${v.voucherNo}\t${v.type}\t${v.party}\t${v.amount.toFixed(2)}\t${v.taxableAmount.toFixed(2)}\t${v.salesLedger ?? v.purchaseLedger ?? ''}`
      )
      console.log('%c[Vouchers XLS] Copy the block below → paste into Excel', 'font-weight:bold;color:#0d9488')
      console.log([vTsvHeader, ...vTsvRows].join('\n'))

      // 4. Closing balances — only fetched and shown when filter is "Today".
      // Tally's ClosingBalance ignores SVTODATE so historical balances are not possible.
      // Captured in outer-scoped lets (not just state) so the DB-persist block below
      // can use the freshly-fetched values — reading state here would race, since
      // setState doesn't apply synchronously within the same function execution.
      let latestCashInHand:    number | null = null
      let latestBankBalance:   number | null = null
      let latestReceivables:   number | null = null
      let latestPayables:      number | null = null
      if (to === todayStr()) {
        try {
          const { rawLedgers } = await fetchLedgerBalances(tallyUrl, tallyCompany, toTallyDate(todayStr()))
          const cashLedgers = rawLedgers.filter(l => l.group.toLowerCase().includes('cash'))
          const bankLedgers = rawLedgers.filter(l => l.group.toLowerCase().includes('bank'))
          if (rawLedgers.length > 0) {
            const cashInHand = -cashLedgers.reduce((s, l) => s + l.balance, 0)
            const bankBal    = -bankLedgers.reduce((s, l) => s + l.balance, 0)
            console.log('[Balances] cashInHand:', cashInHand, '| bankBalance:', bankBal)
            setCashInHand(cashInHand)
            setBankBalance(bankBal)
            latestCashInHand  = cashInHand
            latestBankBalance = bankBal
          } else {
            setCashInHand(null)
            setBankBalance(null)
          }
        } catch (err) {
          console.error('[Balances] fetchLedgerBalances failed:', err)
          setCashInHand(null)
          setBankBalance(null)
        }

        try {
          const { receivables: rec, payables: pay } = await fetchGroupBalances(tallyUrl, tallyCompany)
          console.log('[GroupBalances] receivables:', rec, '| payables:', pay)
          setReceivables(rec)
          setPayables(pay)
          latestReceivables = rec
          latestPayables    = pay
        } catch (err) {
          console.error('[GroupBalances] fetchGroupBalances failed:', err)
          setReceivables(null)
          setPayables(null)
        }

        // Deliberately NOT awaited here — this fetch is batched into many
        // small sequential Tally requests, each its own message with its own
        // 120s timeout budget (see fetchDebtorBalances in tallyService.ts),
        // and can take a while for a large ledger master. Awaiting it inline
        // would stall every other KPI card on this tab behind it. Runs on
        // its own and persists its own snapshot patch independently once done.
        fetchDebtorBalances(tallyUrl, tallyCompany)
          .then(({ balances }) => {
            console.log('[DebtorBalances] parties:', balances.length)
            void saveDashboardSnapshot(companyId, { debtorBalances: balances })
              .catch((err: unknown) => console.error('[DebtorBalances] Failed to persist snapshot:', err))
          })
          .catch((err: unknown) => {
            console.error('[DebtorBalances] fetchDebtorBalances failed:', err)
          })
      } else {
        setCashInHand(null)
        setBankBalance(null)
        setReceivables(null)
        setPayables(null)
      }

      setFetched(true)

      // 4. Yesterday fetch — prev day sales comparison
      if (preset === 'today') {
        setPrevDaySales(null)
        const yDate = new Date(); yDate.setDate(yDate.getDate() - 1)
        const yd    = fmt(yDate)
        console.log('[PrevDay] Fetching yesterday sales. Date:', yd, 'TallyDate:', toTallyDate(yd))
        try {
          const { vouchers: yv } = await fetchDaybook(toTallyDate(yd), toTallyDate(yd), tallyUrl, tallyCompany, {})
          console.log('[PrevDay] Raw vouchers received:', yv.length, yv)
          const yTotal = computeSalesTotal(yv, settings.today)
          console.log('[PrevDay] Total:', yTotal)
          console.log('[Comparison] Today:', todaySalesTotal, '| Yesterday:', yTotal,
            '| Change:', (((todaySalesTotal - yTotal) / (yTotal || 1)) * 100).toFixed(1) + '%')
          setPrevDaySales(yTotal)
        } catch (err) {
          console.error('[PrevDay] Failed to fetch yesterday data:', err)
          setPrevDaySales(null)
        }
      } else {
        setPrevDaySales(null)
      }

      // Top debtors — computed from already-fetched daybook data (same filter as computeSalesTotal)
      {
        const { salesAccounts, salesIncludeVouchers, salesExcludeVouchers } = salesSettings ?? {}
        const base = salesAccounts?.length ? all.filter(v => v.hasSalesLedger) : all
        const salesVouchers = base.filter(v => salesIncludeVouchers?.length
          ? salesIncludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /sales/i.test(v.type) && !/credit\s*note/i.test(v.type))
        const creditNotes = base.filter(v => salesExcludeVouchers?.length
          ? salesExcludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /credit\s*note/i.test(v.type))
        const partyMap = new Map<string, number>()
        for (const v of salesVouchers)
          partyMap.set(v.party, (partyMap.get(v.party) ?? 0) + v.amount)
        for (const v of creditNotes)
          partyMap.set(v.party, (partyMap.get(v.party) ?? 0) - v.amount)
        const debtors = [...partyMap.entries()]
          .filter(([, amt]) => amt > 0)
          .sort(([, a], [, b]) => b - a)
          .map(([name, amount]) => ({ name, amount }))
        setTopDebtors(debtors)
      }

      // 5. Non-critical fetches in parallel — none block the main KPIs.
      const [slowResult, stockResult, directExpResult] = await Promise.allSettled([
        fetchSlowMovingStock(tallyUrl, tallyCompany),
        preset === 'ytd'
          ? fetchStockValue(toTallyDate(from), toTallyDate(to), tallyUrl, tallyCompany)
          : Promise.resolve(null),
        preset === 'ytd'
          ? fetchLedgerAmounts(toTallyDate(from), toTallyDate(to), tallyUrl, tallyCompany, settings.ytd?.directExpenseLedgers)
          : Promise.resolve(0),
      ])
      if (slowResult.status === 'fulfilled') setSlowStock(slowResult.value.items)
      if (preset === 'ytd' && stockResult.status === 'fulfilled' && stockResult.value) {
        const { openingStock, closingStock } = stockResult.value
        const directExpenses = directExpResult.status === 'fulfilled' ? Math.abs(directExpResult.value ?? 0) : 0

        const indirectExpenses = indExpTotal
        const indirectIncome   = indIncTotal

        const gm    = (todaySalesTotal + closingStock) - (openingStock + purchaseTotal + directExpenses)
        const gmPct = todaySalesTotal > 0 ? (gm / todaySalesTotal) * 100 : 0
        const np    = gm - indirectExpenses + indirectIncome
        const npPct = todaySalesTotal > 0 ? (np / todaySalesTotal) * 100 : 0

        console.group('[P&L] YTD breakdown')
        console.log('Config — directExpLedgers   :', settings.ytd?.directExpenseLedgers ?? [])
        console.log('Config — indirectExpLedgers :', settings.ytd?.indirectExpenseLedgers ?? [])
        console.log('Config — indirectIncLedgers :', settings.ytd?.indirectIncomeLedgers ?? [])
        console.log('─────────────────────────────────────────')
        console.log('Sales              :', todaySalesTotal.toFixed(2))
        console.log('Opening Stock      :', openingStock.toFixed(2))
        console.log('Closing Stock      :', closingStock.toFixed(2))
        console.log('Purchases          :', purchaseTotal.toFixed(2))
        console.log('Direct Expenses    :', directExpenses.toFixed(2))
        console.log('─────────────────────────────────────────')
        console.log('Gross Profit       :', gm.toFixed(2), `(${gmPct.toFixed(2)}%)`)
        console.log('Indirect Expenses  :', indirectExpenses.toFixed(2))
        console.log('Indirect Income    :', indirectIncome.toFixed(2))
        console.log('─────────────────────────────────────────')
        console.log('Net Profit         :', np.toFixed(2), `(${npPct.toFixed(2)}%)`)
        console.groupEnd()

        const eb    = np + ebitdaAddback
        const ebPct = todaySalesTotal > 0 ? (eb / todaySalesTotal) * 100 : 0

        setGrossMargin(gm)
        setGrossMarginPct(gmPct)
        setEbitda(eb)
        setEbitdaPct(ebPct)
        setNetProfit(np)
        setNetProfitPct(npPct)
      }

      // Persist this live fetch to the DB — best-effort, fire-and-forget, never
      // blocks the UI. Only include snapshot fields actually computed this run,
      // so e.g. applying a past custom range doesn't clobber today's cached
      // balances with nulls.
      void saveVouchers(companyId, from, to, all)
        .then((r) => {
          if (r.failed > 0) {
            console.error(`[Dashboard] ${r.failed}/${all.length} voucher(s) failed to persist to DB — dashboard cache will be missing these until fixed:`, r.failures)
          }
        })
        .catch((err: unknown) => console.error('[Dashboard] Failed to persist vouchers:', err))

      const snapshotPatch: DashboardSnapshotPatch = {
        slowStockItems: slowResult.status === 'fulfilled' ? slowResult.value.items : [],
      }
      if (to === todayStr()) {
        snapshotPatch.cashInHand      = latestCashInHand
        snapshotPatch.bankBalance     = latestBankBalance
        snapshotPatch.receivables     = latestReceivables
        snapshotPatch.payables        = latestPayables
        // debtorBalances is deliberately NOT included here — it's fetched
        // decoupled (see above) and persists its own snapshot patch once
        // its batched Tally requests finish, since it can resolve well
        // after this main snapshot save already ran.
      }
      if (preset === 'ytd' && stockResult.status === 'fulfilled' && stockResult.value) {
        snapshotPatch.openingStock       = stockResult.value.openingStock
        snapshotPatch.closingStock       = stockResult.value.closingStock
        snapshotPatch.directExpenseTotal = directExpResult.status === 'fulfilled' ? Math.abs(directExpResult.value ?? 0) : 0
      }
      void saveDashboardSnapshot(companyId, snapshotPatch).catch((err: unknown) => console.error('[Dashboard] Failed to persist snapshot:', err))
    } catch (err) {
      console.error('[Dashboard] fetchData failed:', err)
      setError('no-data')
      toast.error('No data found. Please check that Tally is open and try again.')
    } finally {
      setLoading(false)
    }
  }, [connected, tallyUrl, tallyCompany, dashboardSettings, updateSalesTrend])

  // Reads whatever's cached in the DB for the given range — never touches
  // Tally. Used for every tab/filter switch; Apply and the initial mount's
  // one-time backfill are the only paths that go live (see fetchData above).
  //
  // Also returns every KPI it computes (not just fetchedDates) — needed by
  // generateCfoSuggestions, which calls this with 'ytd' and must read the
  // freshly-computed values in the SAME invocation. Reading component state
  // instead would be stale: setXxx(...) queues an update for the next
  // render, but this function's own local closure doesn't see it.
  const loadFromDb = useCallback(async (preset: FilterPreset, cfrom: string, cto: string): Promise<{
    fetchedDates: string[]
    data: {
      total: number
      salesTrend: { label: string; amount: number }[]
      grossMargin: number | null; grossMarginPct: number | null
      ebitda: number | null; ebitdaPct: number | null
      netProfit: number | null; netProfitPct: number | null
      cashInHand: number | null; bankBalance: number | null
      cashInflow: number | null; cashOutflow: number | null
      bankInflow: number | null; bankOutflow: number | null
      receivables: number | null; payables: number | null
      topItems: TopItem[]
      topDebtors: SalesPartyRow[]
      slowStock: SlowStockItem[]
      debtorBalances: DebtorBalance[]
    }
  }> => {
    const emptyData = {
      total: 0, salesTrend: [], grossMargin: null, grossMarginPct: null,
      ebitda: null, ebitdaPct: null, netProfit: null, netProfitPct: null,
      cashInHand: null, bankBalance: null,
      cashInflow: null, cashOutflow: null, bankInflow: null, bankOutflow: null,
      receivables: null, payables: null,
      topItems: [], topDebtors: [], slowStock: [], debtorBalances: [],
    }
    if (!companyId) return { fetchedDates: [], data: emptyData }
    const { from, to } = getFilterDates(preset, cfrom, cto)
    const salesSettings = dashboardSettings.today

    setLoading(true)
    setError(null)
    try {
      const [{ vouchers: all, fetchedDates }, snapshot] = await Promise.all([
        fetchCachedVouchers(companyId, from, to),
        fetchDashboardSnapshot(companyId),
      ])

      const { cashFlow, bankFlow, topItems: fetchedTopItems, indExpTotal, indIncTotal, ebitdaAddback } = classifyVouchers(
        all,
        {
          salesAccounts:           salesSettings?.salesAccounts,
          salesIncludeVouchers:    salesSettings?.salesIncludeVouchers,
          salesExcludeVouchers:    salesSettings?.salesExcludeVouchers,
          cashInflowLedgers:       dashboardSettings.today?.cashInflowLedgers,
          bankLedgers:             dashboardSettings.today?.bankLedgers,
          purchaseAccounts:        dashboardSettings.ytd?.purchaseAccounts,
          indirectExpenseLedgers:         dashboardSettings.ytd?.indirectExpenseLedgers,
          indirectExpenseIncludeVouchers: dashboardSettings.ytd?.indirectExpenseIncludeVouchers,
          indirectExpenseExcludeVouchers: dashboardSettings.ytd?.indirectExpenseExcludeVouchers,
          indirectIncomeLedgers:          dashboardSettings.ytd?.indirectIncomeLedgers,
          indirectIncomeIncludeVouchers:  dashboardSettings.ytd?.indirectIncomeIncludeVouchers,
          indirectIncomeExcludeVouchers:  dashboardSettings.ytd?.indirectIncomeExcludeVouchers,
          ebitdaLedgers:                  dashboardSettings.ytd?.ebitdaLedgers,
          ebitdaIncludeVouchers:          dashboardSettings.ytd?.ebitdaIncludeVouchers,
          ebitdaExcludeVouchers:          dashboardSettings.ytd?.ebitdaExcludeVouchers,
        },
        from,
        to,
      )
      setTopItems(fetchedTopItems)

      const pf = dashboardSettings.ytd as PurchaseFilterSettings | undefined
      const { purchaseIncludeVouchers, purchaseExcludeVouchers } = pf ?? {}
      const pvIncluded = all
        .filter(v => purchaseIncludeVouchers?.length
          ? purchaseIncludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /purchase/i.test(v.type) && !/debit\s*note/i.test(v.type))
        .map(v => ({ ...v, role: 'Included' as const }))
      const pvExcluded = all
        .filter(v => purchaseExcludeVouchers?.length
          ? purchaseExcludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /debit\s*note/i.test(v.type))
        .map(v => ({ ...v, role: 'Excluded' as const }))
      setPurchaseVouchers([...pvIncluded, ...pvExcluded].sort((a, b) => a.date.localeCompare(b.date)))

      const totalSales = computeSalesTotal(all, salesSettings)
      setTotal(totalSales)
      setActivePeriod({ from, to })
      const salesTrendResult = await updateSalesTrend(preset, all, salesSettings)

      const purchaseTotal = preset === 'ytd' ? computePurchaseTotal(all, dashboardSettings.ytd) : 0

      setCashInflow(cashFlow.inflow)
      setCashOutflow(cashFlow.outflow)
      setBankInflow(bankFlow.inflow)
      setBankOutflow(bankFlow.outflow)

      // Top debtors — same logic as the live path in fetchData
      let topDebtorsResult: SalesPartyRow[] = []
      {
        const { salesAccounts, salesIncludeVouchers, salesExcludeVouchers } = salesSettings ?? {}
        const base = salesAccounts?.length ? all.filter(v => v.hasSalesLedger) : all
        const salesVouchers = base.filter(v => salesIncludeVouchers?.length
          ? salesIncludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /sales/i.test(v.type) && !/credit\s*note/i.test(v.type))
        const creditNotes = base.filter(v => salesExcludeVouchers?.length
          ? salesExcludeVouchers.some(t => v.type.toLowerCase() === t.toLowerCase())
          : /credit\s*note/i.test(v.type))
        const partyMap = new Map<string, number>()
        for (const v of salesVouchers) partyMap.set(v.party, (partyMap.get(v.party) ?? 0) + v.amount)
        for (const v of creditNotes) partyMap.set(v.party, (partyMap.get(v.party) ?? 0) - v.amount)
        const debtors = [...partyMap.entries()]
          .filter(([, amt]) => amt > 0)
          .sort(([, a], [, b]) => b - a)
          .map(([name, amount]) => ({ name, amount }))
        setTopDebtors(debtors)
        topDebtorsResult = debtors
      }

      // Snapshot fields — cached "current value" data, only meaningful for today/ytd-relevant views
      let cashInHandResult: number | null = null
      let bankBalanceResult: number | null = null
      let receivablesResult: number | null = null
      let payablesResult: number | null = null
      let debtorBalancesResult: DebtorBalance[] = []
      if (to === todayStr()) {
        cashInHandResult     = snapshot?.cashInHand ?? null
        bankBalanceResult    = snapshot?.bankBalance ?? null
        receivablesResult    = snapshot?.receivables ?? null
        payablesResult       = snapshot?.payables ?? null
        debtorBalancesResult = snapshot?.debtorBalances ?? []
        setCashInHand(cashInHandResult)
        setBankBalance(bankBalanceResult)
        setReceivables(receivablesResult)
        setPayables(payablesResult)
      } else {
        setCashInHand(null)
        setBankBalance(null)
        setReceivables(null)
        setPayables(null)
      }
      const slowStockResult = snapshot?.slowStockItems ?? []
      setSlowStock(slowStockResult)

      let grossMarginResult: number | null = null, grossMarginPctResult: number | null = null
      let ebitdaResult: number | null = null, ebitdaPctResult: number | null = null
      let netProfitResult: number | null = null, netProfitPctResult: number | null = null
      if (preset === 'ytd' && snapshot?.openingStock != null && snapshot?.closingStock != null) {
        const openingStock    = snapshot.openingStock
        const closingStock    = snapshot.closingStock
        const directExpenses  = snapshot.directExpenseTotal ?? 0
        const gm    = (totalSales + closingStock) - (openingStock + purchaseTotal + directExpenses)
        const gmPct = totalSales > 0 ? (gm / totalSales) * 100 : 0
        const np    = gm - indExpTotal + indIncTotal
        const npPct = totalSales > 0 ? (np / totalSales) * 100 : 0
        const eb    = np + ebitdaAddback
        const ebPct = totalSales > 0 ? (eb / totalSales) * 100 : 0
        setGrossMargin(gm)
        setGrossMarginPct(gmPct)
        setEbitda(eb)
        setEbitdaPct(ebPct)
        setNetProfit(np)
        setNetProfitPct(npPct)
        grossMarginResult = gm; grossMarginPctResult = gmPct
        ebitdaResult      = eb; ebitdaPctResult      = ebPct
        netProfitResult   = np; netProfitPctResult   = npPct
      } else {
        setGrossMargin(null)
        setGrossMarginPct(null)
        setEbitda(null)
        setEbitdaPct(null)
        setNetProfit(null)
        setNetProfitPct(null)
      }

      // Previous-day comparison — only from cache, never a live Tally call
      if (preset === 'today') {
        const yDate = new Date(); yDate.setDate(yDate.getDate() - 1)
        const yd = fmt(yDate)
        const { vouchers: yv } = await fetchCachedVouchers(companyId, yd, yd)
        setPrevDaySales(yv.length > 0 ? computeSalesTotal(yv, salesSettings) : null)
      } else {
        setPrevDaySales(null)
      }

      setFetched(true)
      return {
        fetchedDates,
        data: {
          total: totalSales, salesTrend: salesTrendResult,
          grossMargin: grossMarginResult, grossMarginPct: grossMarginPctResult,
          ebitda: ebitdaResult, ebitdaPct: ebitdaPctResult,
          netProfit: netProfitResult, netProfitPct: netProfitPctResult,
          cashInHand: cashInHandResult, bankBalance: bankBalanceResult,
          cashInflow: cashFlow.inflow, cashOutflow: cashFlow.outflow,
          bankInflow: bankFlow.inflow, bankOutflow: bankFlow.outflow,
          receivables: receivablesResult, payables: payablesResult,
          topItems: fetchedTopItems, topDebtors: topDebtorsResult,
          slowStock: slowStockResult, debtorBalances: debtorBalancesResult,
        },
      }
    } catch (err) {
      console.error('[Dashboard] loadFromDb failed:', err)
      setError('no-data')
      return { fetchedDates: [], data: emptyData }
    } finally {
      setLoading(false)
    }
  }, [companyId, dashboardSettings, updateSalesTrend])

  // ── Analysis tab — DB-only read, mirrors loadFromDb above but for the 9
  // ratio KPIs. Never touches Tally. Balance-sheet inputs (debtors, creditors,
  // cash, bank, investments, current liabilities, bank OD, equity, total
  // loans) only apply when `to` is today — same Tally "ClosingBalance ignores
  // SVTODATE" limitation loadFromDb already works around for
  // receivables/payables/cash/bank.
  const loadAnalysisFromDb = useCallback(async (preset: FilterPreset, cfrom: string, cto: string): Promise<{ fetchedDates: string[]; data: AnalysisInputs }> => {
    if (!companyId) return { fetchedDates: [], data: emptyAnalysisInputs }
    const { from, to } = getFilterDates(preset, cfrom, cto)
    const isCurrent = to === todayStr()

    setAnalysisLoading(true)
    try {
      const [{ vouchers: all, fetchedDates }, snapshot] = await Promise.all([
        fetchCachedVouchers(companyId, from, to),
        fetchDashboardSnapshot(companyId),
      ])

      const purchaseTotal = computePurchaseTotal(all, dashboardSettings.ytd)
      // DIO/DPO each get their own dedicated Purchases figure, filtered from
      // the same already-fetched vouchers — deliberately separate from
      // purchaseTotal above (Gross Margin/Net Profit), so tuning one never
      // silently moves the other.
      const dioPurchaseTotal = computePurchaseTotal(all, {
        purchaseAccounts:        dashboardSettings.ytd?.dioPurchaseAccounts,
        purchaseIncludeVouchers: dashboardSettings.ytd?.dioPurchaseIncludeVouchers,
        purchaseExcludeVouchers: dashboardSettings.ytd?.dioPurchaseExcludeVouchers,
      })
      const dpoPurchaseTotal = computePurchaseTotal(all, {
        purchaseAccounts:        dashboardSettings.ytd?.dpoPurchaseAccounts,
        purchaseIncludeVouchers: dashboardSettings.ytd?.dpoPurchaseIncludeVouchers,
        purchaseExcludeVouchers: dashboardSettings.ytd?.dpoPurchaseExcludeVouchers,
      })
      // DSO's Credit Sales split deliberately uses the Analysis tab's own
      // Sales setting (independent of Performance tab). Total Sales — which
      // feeds Net Profit/ROCE/ROE — deliberately does NOT: Net Profit must be
      // the same number on both tabs, so it stays on the Performance tab's
      // Today-tab Sales setting.
      const analysisSalesFilter: SalesFilterSettings = {
        salesAccounts:        dashboardSettings.ytd?.analysisSalesAccounts,
        salesIncludeVouchers: dashboardSettings.ytd?.analysisSalesIncludeVouchers,
        salesExcludeVouchers: dashboardSettings.ytd?.analysisSalesExcludeVouchers,
      }
      const creditSales   = computeCreditSalesTotal(all, analysisSalesFilter)
      const totalSales    = computeSalesTotal(all, dashboardSettings.today)
      console.log('[Analysis][DB] DSO Sales settings:', analysisSalesFilter)
      console.log(`[Analysis][DB] Total Sales (Net Profit, uses Performance tab setting): ${totalSales} | Credit Sales (for DSO): ${creditSales} | vouchers in range: ${all.length}`)

      const classifyResult = classifyVouchers(
        all,
        {
          indirectExpenseLedgers:         dashboardSettings.ytd?.indirectExpenseLedgers,
          indirectExpenseIncludeVouchers: dashboardSettings.ytd?.indirectExpenseIncludeVouchers,
          indirectExpenseExcludeVouchers: dashboardSettings.ytd?.indirectExpenseExcludeVouchers,
          indirectIncomeLedgers:          dashboardSettings.ytd?.indirectIncomeLedgers,
          indirectIncomeIncludeVouchers:  dashboardSettings.ytd?.indirectIncomeIncludeVouchers,
          indirectIncomeExcludeVouchers:  dashboardSettings.ytd?.indirectIncomeExcludeVouchers,
          interestExpenseLedgers:         dashboardSettings.ytd?.interestExpenseLedgers,
          taxPaymentLedgers:              dashboardSettings.ytd?.taxPaymentLedgers,
          nonOperatingIncomeLedgers:      dashboardSettings.ytd?.nonOperatingIncomeLedgers,
          nonOperatingInvestmentLedgers:  dashboardSettings.ytd?.nonOperatingInvestmentLedgers,
        },
        from, to,
      )

      // null (not 0) when the ledger list isn't configured — same contract as
      // the live-fetch path's fetchLedgerTotal.
      const dbInterestExpense    = dashboardSettings.ytd?.interestExpenseLedgers?.length
        ? classifyResult.interestExpenseTotal : null
      const dbTaxPayment         = dashboardSettings.ytd?.taxPaymentLedgers?.length
        ? classifyResult.taxPaymentTotal : null
      const dbNonOpIncome        = dashboardSettings.ytd?.nonOperatingIncomeLedgers?.length
        ? classifyResult.nonOperatingIncomeTotal : null
      const dbNonOpInvestment    = dashboardSettings.ytd?.nonOperatingInvestmentLedgers?.length
        ? classifyResult.nonOperatingInvestmentTotal : null

      let netProfit: number | null = null
      if (snapshot?.openingStock != null && snapshot?.closingStock != null && snapshot?.directExpenseTotal != null) {
        const gm = (totalSales + snapshot.closingStock) - (snapshot.openingStock + purchaseTotal + snapshot.directExpenseTotal)
        netProfit = gm - classifyResult.indExpTotal + classifyResult.indIncTotal
      }

      // DIO = Closing Stock / COGS * 365, COGS = Opening Stock + Purchases + Direct Expenses − Closing Stock
      {
        const openingStock   = snapshot?.openingStock ?? null
        const closingStock   = snapshot?.closingStock ?? null
        const dioDirectExpenses = snapshot?.dioDirectExpenseTotal ?? null
        const cogs = openingStock != null && dioDirectExpenses != null && closingStock != null
          ? openingStock + dioPurchaseTotal + dioDirectExpenses - closingStock : null
        const dioDays = closingStock != null && cogs ? (closingStock / cogs) * 365 : null
        console.log(`[Analysis][DB] DIO — Opening Stock: ${openingStock} | Closing Stock: ${closingStock} | Purchases: ${dioPurchaseTotal} | Direct Expenses: ${dioDirectExpenses}`)
        console.log(`[Analysis][DB] DIO — COGS: ${cogs} | DIO (days): ${dioDays}`)
        console.log(`[Analysis][DB] DPO — Purchases: ${dpoPurchaseTotal}`)
      }

      // Current Ratio / Quick Ratio — both fully user-configured (own
      // Assets/Liabilities ledger-list totals cached on the snapshot).
      {
        const dbCurrentRatioAssets      = snapshot?.currentRatioAssetsTotal ?? null
        const dbCurrentRatioLiabilities = snapshot?.currentRatioLiabilitiesTotal ?? null
        const dbQuickRatioAssets        = snapshot?.quickRatioAssetsTotal ?? null
        const dbQuickRatioLiabilities   = snapshot?.quickRatioLiabilitiesTotal ?? null
        const currentRatioVal = dbCurrentRatioAssets != null && dbCurrentRatioLiabilities
          ? dbCurrentRatioAssets / dbCurrentRatioLiabilities : null
        const quickRatioVal = dbQuickRatioAssets != null && dbQuickRatioLiabilities
          ? dbQuickRatioAssets / dbQuickRatioLiabilities : null
        console.log(`[Analysis][DB] Current Ratio — Assets: ${dbCurrentRatioAssets} | Liabilities: ${dbCurrentRatioLiabilities} | ratio: ${currentRatioVal}`)
        console.log(`[Analysis][DB] Quick Ratio — Assets: ${dbQuickRatioAssets} | Liabilities: ${dbQuickRatioLiabilities} | ratio: ${quickRatioVal}`)
      }

      // ROCE = (EBIT − Non-Operating Income) / (Equity + Long Term Borrowings − Non-Operating Investment) * 100
      // EBIT = Net Profit + Interest Expense + Tax Payment (Net Profit is after
      // interest/tax are deducted, so they're added back, not subtracted again)
      {
        const dbRoceEquity         = snapshot?.roceEquity ?? null
        const dbLongTermBorrowings = snapshot?.longTermBorrowings ?? null
        const dbEbit = netProfit != null && dbInterestExpense != null
          ? netProfit + dbInterestExpense + (dbTaxPayment ?? 0) : null
        const roceNum = dbEbit != null && dbNonOpIncome != null ? dbEbit - dbNonOpIncome : null
        const roceDen = dbRoceEquity != null
          ? dbRoceEquity + (dbLongTermBorrowings ?? 0) - (dbNonOpInvestment ?? 0) : null
        const roceVal = roceNum != null && roceDen != null && roceDen > 0 ? (roceNum / roceDen) * 100 : null
        console.log(`[Analysis][DB] ROCE — Net Profit: ${netProfit} | Interest Expense: ${dbInterestExpense} | Tax Payment: ${dbTaxPayment} | EBIT: ${dbEbit}`)
        console.log(`[Analysis][DB] ROCE — Non-Operating Income: ${dbNonOpIncome} | Equity: ${dbRoceEquity} | Long Term Borrowings: ${dbLongTermBorrowings} | Non-Operating Investment: ${dbNonOpInvestment}`)
        console.log(`[Analysis][DB] ROCE — numerator: ${roceNum} | denominator: ${roceDen}${roceDen != null && roceDen <= 0 ? ' (<= 0, ratio blocked)' : ''} | ROCE (%): ${roceVal}`)
      }

      // ROE = Net Profit / (Equity + Internal Borrowings − Intangible Assets) * 100
      {
        const dbRoeEquity          = snapshot?.roeEquity ?? null
        const dbInternalBorrowings = snapshot?.internalBorrowings ?? null
        const dbIntangibleAssets   = snapshot?.intangibleAssets ?? null
        const roeDen = dbRoeEquity != null
          ? dbRoeEquity + (dbInternalBorrowings ?? 0) - (dbIntangibleAssets ?? 0) : null
        const roeVal = netProfit != null && roeDen != null && roeDen > 0 ? (netProfit / roeDen) * 100 : null
        console.log(`[Analysis][DB] ROE — Net Profit: ${netProfit} | Equity: ${dbRoeEquity} | Internal Borrowings: ${dbInternalBorrowings} | Intangible Assets: ${dbIntangibleAssets}`)
        console.log(`[Analysis][DB] ROE — denominator: ${roeDen}${roeDen != null && roeDen <= 0 ? ' (<= 0, ratio blocked)' : ''} | ROE (%): ${roeVal}`)
      }

      // Debt/Equity = (Loans − Cash − Bank) / (Equity + Director Loans)
      {
        const dbDebtEquityLoans  = snapshot?.debtEquityLoans ?? null
        const dbDebtEquityCash   = snapshot?.debtEquityCash ?? null
        const dbDebtEquityBank   = snapshot?.debtEquityBank ?? null
        const dbDebtEquityEquity = snapshot?.debtEquityEquity ?? null
        const dbDirectorLoans    = snapshot?.directorLoansTotal ?? null
        const deNum = dbDebtEquityLoans != null
          ? dbDebtEquityLoans - (dbDebtEquityCash ?? 0) - (dbDebtEquityBank ?? 0) : null
        const deDen = dbDebtEquityEquity != null
          ? dbDebtEquityEquity + (dbDirectorLoans ?? 0) : null
        const deVal = deNum != null && deDen != null && deDen > 0 ? deNum / deDen : null
        console.log(`[Analysis][DB] Debt/Equity — Loans: ${dbDebtEquityLoans} | Cash: ${dbDebtEquityCash} | Bank: ${dbDebtEquityBank}`)
        console.log(`[Analysis][DB] Debt/Equity — Equity: ${dbDebtEquityEquity} | Director Loans: ${dbDirectorLoans}`)
        console.log(`[Analysis][DB] Debt/Equity — numerator: ${deNum} | denominator: ${deDen}${deDen != null && deDen <= 0 ? ' (<= 0, ratio blocked)' : ''} | ratio: ${deVal}`)
      }

      const inputs: AnalysisInputs = {
        debtors:               isCurrent ? (snapshot?.receivables ?? null) : null,
        creditors:             isCurrent ? (snapshot?.payables ?? null) : null,
        creditSales,
        openingStock:          snapshot?.openingStock ?? null,
        closingStock:          snapshot?.closingStock ?? null,
        dioPurchases:          dioPurchaseTotal,
        dioDirectExpenses:     snapshot?.dioDirectExpenseTotal ?? null,
        dpoPurchases:          dpoPurchaseTotal,
        currentRatioAssets:      snapshot?.currentRatioAssetsTotal ?? null,
        currentRatioLiabilities: snapshot?.currentRatioLiabilitiesTotal ?? null,
        quickRatioAssets:        snapshot?.quickRatioAssetsTotal ?? null,
        quickRatioLiabilities:   snapshot?.quickRatioLiabilitiesTotal ?? null,
        longTermBorrowings:     snapshot?.longTermBorrowings ?? null,
        roceEquity:             snapshot?.roceEquity ?? null,
        netProfit,
        interestExpense:        dbInterestExpense,
        taxPayment:             dbTaxPayment,
        nonOperatingIncome:     dbNonOpIncome,
        nonOperatingInvestment: dbNonOpInvestment,
        directorLoans:          snapshot?.directorLoansTotal ?? null,
        roeEquity:              snapshot?.roeEquity ?? null,
        internalBorrowings:     snapshot?.internalBorrowings ?? null,
        intangibleAssets:       snapshot?.intangibleAssets ?? null,
        debtEquityLoans:        snapshot?.debtEquityLoans ?? null,
        debtEquityCash:         snapshot?.debtEquityCash ?? null,
        debtEquityBank:         snapshot?.debtEquityBank ?? null,
        debtEquityEquity:       snapshot?.debtEquityEquity ?? null,
      }
      setAnalysisInputs(inputs)
      setAnalysisActivePeriod({ from, to })
      setAnalysisFetched(true)
      return { fetchedDates, data: inputs }
    } catch (err) {
      console.error('[Dashboard] loadAnalysisFromDb failed:', err)
      return { fetchedDates: [], data: emptyAnalysisInputs }
    } finally {
      setAnalysisLoading(false)
    }
  }, [companyId, dashboardSettings])

  // ── Analysis tab — live Tally fetch + persist, mirrors fetchData above.
  const fetchAnalysisData = useCallback(async (preset: FilterPreset, cfrom: string, cto: string) => {
    if (!connected) {
      toast.error('Tally not connected. Please ensure the extension is installed and Tally is open.')
      return
    }
    const { from, to } = getFilterDates(preset, cfrom, cto)
    const isCurrent = to === todayStr()
    const fFrom = toTallyDate(from)
    const fTo   = toTallyDate(to)

    // Only hits Tally for a ledger list that's actually configured — an
    // unconfigured list must stay null ("No data available"), never 0, since
    // 0 is indistinguishable from "genuinely no expense this period".
    // fetchLedgerAmounts returns the SIGNED net balance (Dr positive, Cr
    // negative, same convention as everywhere else in this codebase) — mode
    // decides how to interpret it: 'magnitude' (default) takes the absolute
    // value, correct for expense/income/loan/asset figures where only "how
    // much" matters. 'equity' passes the signed value straight through with
    // NO transform — confirmed against real Tally data that Dr-positive/
    // Cr-negative is exactly the sign the user expects for Equity too (an
    // earlier version negated this, which was wrong), so this preserves
    // genuinely negative equity (accumulated losses) as a negative number.
    const fetchLedgerTotal = (names?: string[], mode: 'magnitude' | 'equity' = 'magnitude'): Promise<number | null> =>
      names?.length
        ? fetchLedgerAmounts(fFrom, fTo, tallyUrl, tallyCompany, names)
            .then(signed => mode === 'equity' ? signed : Math.abs(signed))
            .catch((err: unknown) => {
              console.error('[Analysis][Live] fetchLedgerAmounts failed for', names, ':', err)
              return null
            })
        : Promise.resolve(null)

    setAnalysisLoading(true)
    try {
      const [
        daybookResult, stockResult, directExpResult, dioDirectExpResult,
        groupBalResult,
        directorLoansTotal,
        longTermBorrowingsTotal, roceEquityTotal,
        roeEquityTotal, internalBorrowingsTotal, intangibleAssetsTotal,
        debtEquityLoansTotal, debtEquityCashTotal, debtEquityBankTotal, debtEquityEquityTotal,
      ] = await Promise.all([
        fetchDaybook(fFrom, fTo, tallyUrl, tallyCompany, {
          // Analysis tab's own Sales definition, not the Performance tab's —
          // must match what computeSalesTotal/computeCreditSalesTotal filter
          // by below, since hasSalesLedger is computed here, ledger-entry-side.
          salesAccounts:                  dashboardSettings.ytd?.analysisSalesAccounts,
          salesIncludeVouchers:           dashboardSettings.ytd?.analysisSalesIncludeVouchers,
          salesExcludeVouchers:           dashboardSettings.ytd?.analysisSalesExcludeVouchers,
          // Everything below must mirror the Performance tab's fetchData
          // exactly (same settings keys) — this fetchDaybook result gets
          // persisted via saveVouchers into the SAME shared vouchers table
          // Performance tab reads, so omitting any of these silently wipes
          // that flag (e.g. purchaseLedger) for every voucher in this date
          // range until Performance tab does its own live re-fetch.
          cashInflowLedgers:              dashboardSettings.today?.cashInflowLedgers,
          bankLedgers:                    dashboardSettings.today?.bankLedgers,
          purchaseAccounts:               dashboardSettings.ytd?.purchaseAccounts,
          indirectExpenseLedgers:         dashboardSettings.ytd?.indirectExpenseLedgers,
          indirectExpenseIncludeVouchers: dashboardSettings.ytd?.indirectExpenseIncludeVouchers,
          indirectExpenseExcludeVouchers: dashboardSettings.ytd?.indirectExpenseExcludeVouchers,
          indirectIncomeLedgers:          dashboardSettings.ytd?.indirectIncomeLedgers,
          indirectIncomeIncludeVouchers:  dashboardSettings.ytd?.indirectIncomeIncludeVouchers,
          indirectIncomeExcludeVouchers:  dashboardSettings.ytd?.indirectIncomeExcludeVouchers,
          ebitdaLedgers:                  dashboardSettings.ytd?.ebitdaLedgers,
          ebitdaIncludeVouchers:          dashboardSettings.ytd?.ebitdaIncludeVouchers,
          ebitdaExcludeVouchers:          dashboardSettings.ytd?.ebitdaExcludeVouchers,
          interestExpenseLedgers:         dashboardSettings.ytd?.interestExpenseLedgers,
          taxPaymentLedgers:              dashboardSettings.ytd?.taxPaymentLedgers,
          nonOperatingIncomeLedgers:      dashboardSettings.ytd?.nonOperatingIncomeLedgers,
          nonOperatingInvestmentLedgers:  dashboardSettings.ytd?.nonOperatingInvestmentLedgers,
        }),
        fetchStockValue(fFrom, fTo, tallyUrl, tallyCompany),
        fetchLedgerAmounts(fFrom, fTo, tallyUrl, tallyCompany, dashboardSettings.ytd?.directExpenseLedgers),
        fetchLedgerAmounts(fFrom, fTo, tallyUrl, tallyCompany, dashboardSettings.ytd?.dioDirectExpenseLedgers),
        isCurrent ? fetchGroupBalances(tallyUrl, tallyCompany) : Promise.resolve(null),
        fetchLedgerTotal(dashboardSettings.ytd?.directorLoanLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.longTermBorrowingLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.equityLedgers, 'equity'),
        fetchLedgerTotal(dashboardSettings.ytd?.roeEquityLedgers, 'equity'),
        fetchLedgerTotal(dashboardSettings.ytd?.internalBorrowingLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.intangibleAssetLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.debtEquityLoanLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.debtEquityCashLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.debtEquityBankLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.debtEquityEquityLedgers, 'equity'),
      ])

      // Current Ratio / Quick Ratio — sum whichever Tally GROUPS the user
      // picked, from the full group list groupBalResult already fetched
      // above (no separate request needed; a group's own closing balance
      // already rolls up everything nested under it).
      const currentRatioAssetsTotal      = sumGroupBalances(groupBalResult?.allGroups, dashboardSettings.ytd?.currentRatioAssetsGroups)
      const currentRatioLiabilitiesTotal = sumGroupBalances(groupBalResult?.allGroups, dashboardSettings.ytd?.currentRatioLiabilitiesGroups)
      const quickRatioAssetsTotal        = sumGroupBalances(groupBalResult?.allGroups, dashboardSettings.ytd?.quickRatioAssetsGroups)
      const quickRatioLiabilitiesTotal   = sumGroupBalances(groupBalResult?.allGroups, dashboardSettings.ytd?.quickRatioLiabilitiesGroups)

      const { vouchers: all, indExpTotal, indIncTotal } = daybookResult
      // null (not 0) when the ledger list isn't configured — 0 would be
      // indistinguishable from "genuinely no interest/tax/non-op this period"
      // and would let ROCE compute a misleading number instead of hiding it.
      const interestExpenseTotal        = dashboardSettings.ytd?.interestExpenseLedgers?.length
        ? daybookResult.interestExpenseTotal : null
      const taxPaymentTotal             = dashboardSettings.ytd?.taxPaymentLedgers?.length
        ? daybookResult.taxPaymentTotal : null
      const nonOperatingIncomeTotal     = dashboardSettings.ytd?.nonOperatingIncomeLedgers?.length
        ? daybookResult.nonOperatingIncomeTotal : null
      const nonOperatingInvestmentTotal = dashboardSettings.ytd?.nonOperatingInvestmentLedgers?.length
        ? daybookResult.nonOperatingInvestmentTotal : null
      const purchaseTotal = computePurchaseTotal(all, dashboardSettings.ytd)
      // DIO/DPO each get their own dedicated Purchases figure, filtered from
      // the same already-fetched vouchers — deliberately separate from
      // purchaseTotal above (Gross Margin/Net Profit), so tuning one never
      // silently moves the other.
      const dioPurchaseTotal = computePurchaseTotal(all, {
        purchaseAccounts:        dashboardSettings.ytd?.dioPurchaseAccounts,
        purchaseIncludeVouchers: dashboardSettings.ytd?.dioPurchaseIncludeVouchers,
        purchaseExcludeVouchers: dashboardSettings.ytd?.dioPurchaseExcludeVouchers,
      })
      const dpoPurchaseTotal = computePurchaseTotal(all, {
        purchaseAccounts:        dashboardSettings.ytd?.dpoPurchaseAccounts,
        purchaseIncludeVouchers: dashboardSettings.ytd?.dpoPurchaseIncludeVouchers,
        purchaseExcludeVouchers: dashboardSettings.ytd?.dpoPurchaseExcludeVouchers,
      })
      // DSO's Credit Sales split deliberately uses the Analysis tab's own
      // Sales setting (independent of Performance tab). Total Sales — which
      // feeds Net Profit/ROCE/ROE — deliberately does NOT: Net Profit must be
      // the same number on both tabs, so it stays on the Performance tab's
      // Today-tab Sales setting.
      const analysisSalesFilter: SalesFilterSettings = {
        salesAccounts:        dashboardSettings.ytd?.analysisSalesAccounts,
        salesIncludeVouchers: dashboardSettings.ytd?.analysisSalesIncludeVouchers,
        salesExcludeVouchers: dashboardSettings.ytd?.analysisSalesExcludeVouchers,
      }
      const creditSales   = computeCreditSalesTotal(all, analysisSalesFilter)
      const totalSales    = computeSalesTotal(all, dashboardSettings.today)
      console.log('[Analysis][Live] DSO Sales settings:', analysisSalesFilter)
      console.log(`[Analysis][Live] Total Sales (Net Profit, uses Performance tab setting): ${totalSales} | Credit Sales (for DSO): ${creditSales} | vouchers in range: ${all.length}`)

      const { openingStock, closingStock } = stockResult
      const directExpenses = Math.abs(directExpResult)
      const dioDirectExpenses = Math.abs(dioDirectExpResult)
      const gm = (totalSales + closingStock) - (openingStock + purchaseTotal + directExpenses)
      const netProfit = gm - indExpTotal + indIncTotal

      // DIO = Closing Stock / COGS * 365, COGS = Opening Stock + Purchases + Direct Expenses − Closing Stock
      {
        const cogs = openingStock + dioPurchaseTotal + dioDirectExpenses - closingStock
        const dioDays = cogs ? (closingStock / cogs) * 365 : null
        console.log(`[Analysis][Live] DIO — Opening Stock: ${openingStock} | Closing Stock: ${closingStock} | Purchases: ${dioPurchaseTotal} | Direct Expenses: ${dioDirectExpenses}`)
        console.log(`[Analysis][Live] DIO — COGS: ${cogs} | DIO (days): ${dioDays}`)
        console.log(`[Analysis][Live] DPO — Purchases: ${dpoPurchaseTotal}`)
      }

      const debtors             = isCurrent && groupBalResult ? groupBalResult.receivables : null
      const creditors           = isCurrent && groupBalResult ? groupBalResult.payables : null

      // Current Ratio / Quick Ratio — both fully user-configured (own
      // Assets/Liabilities ledger-list totals), replacing the old fixed
      // group-balance math.
      {
        const currentRatioVal = currentRatioAssetsTotal != null && currentRatioLiabilitiesTotal
          ? currentRatioAssetsTotal / currentRatioLiabilitiesTotal : null
        const quickRatioVal = quickRatioAssetsTotal != null && quickRatioLiabilitiesTotal
          ? quickRatioAssetsTotal / quickRatioLiabilitiesTotal : null
        console.log(`[Analysis][Live] Current Ratio — Assets: ${currentRatioAssetsTotal} | Liabilities: ${currentRatioLiabilitiesTotal} | ratio: ${currentRatioVal}`)
        console.log(`[Analysis][Live] Quick Ratio — Assets: ${quickRatioAssetsTotal} | Liabilities: ${quickRatioLiabilitiesTotal} | ratio: ${quickRatioVal}`)
      }

      // ROCE = (EBIT − Non-Operating Income) / (Equity + Long Term Borrowings − Non-Operating Investment) * 100
      // EBIT = Net Profit + Interest Expense + Tax Payment (added back, not
      // subtracted again — Net Profit is already after interest/tax)
      // Mirrors computeRatios exactly: Tax Payment/Long Term Borrowings/Non-
      // Operating Investment default to 0 when unconfigured, and a zero-or-
      // negative denominator (e.g. genuinely negative Equity) blocks the
      // ratio rather than producing a misleadingly inverted number.
      {
        const ebitVal = netProfit != null && interestExpenseTotal != null
          ? netProfit + interestExpenseTotal + (taxPaymentTotal ?? 0) : null
        const roceNum = ebitVal != null && nonOperatingIncomeTotal != null ? ebitVal - nonOperatingIncomeTotal : null
        const roceDen = roceEquityTotal != null
          ? roceEquityTotal + (longTermBorrowingsTotal ?? 0) - (nonOperatingInvestmentTotal ?? 0) : null
        const roceVal = roceNum != null && roceDen != null && roceDen > 0 ? (roceNum / roceDen) * 100 : null
        console.log(`[Analysis][Live] ROCE — Net Profit: ${netProfit} | Interest Expense: ${interestExpenseTotal} | Tax Payment: ${taxPaymentTotal} | EBIT: ${ebitVal}`)
        console.log(`[Analysis][Live] ROCE — Non-Operating Income: ${nonOperatingIncomeTotal} | Equity: ${roceEquityTotal} | Long Term Borrowings: ${longTermBorrowingsTotal} | Non-Operating Investment: ${nonOperatingInvestmentTotal}`)
        console.log(`[Analysis][Live] ROCE — numerator: ${roceNum} | denominator: ${roceDen}${roceDen != null && roceDen <= 0 ? ' (<= 0, ratio blocked)' : ''} | ROCE (%): ${roceVal}`)
      }

      // ROE = Net Profit / (Equity + Internal Borrowings − Intangible Assets) * 100
      {
        const roeDen = roeEquityTotal != null
          ? roeEquityTotal + (internalBorrowingsTotal ?? 0) - (intangibleAssetsTotal ?? 0) : null
        const roeVal = netProfit != null && roeDen != null && roeDen > 0 ? (netProfit / roeDen) * 100 : null
        console.log(`[Analysis][Live] ROE — Net Profit: ${netProfit} | Equity: ${roeEquityTotal} | Internal Borrowings: ${internalBorrowingsTotal} | Intangible Assets: ${intangibleAssetsTotal}`)
        console.log(`[Analysis][Live] ROE — denominator: ${roeDen}${roeDen != null && roeDen <= 0 ? ' (<= 0, ratio blocked)' : ''} | ROE (%): ${roeVal}`)
      }

      // Debt/Equity = (Loans − Cash − Bank) / (Equity + Director Loans)
      {
        const deNum = debtEquityLoansTotal != null
          ? debtEquityLoansTotal - (debtEquityCashTotal ?? 0) - (debtEquityBankTotal ?? 0) : null
        const deDen = debtEquityEquityTotal != null
          ? debtEquityEquityTotal + (directorLoansTotal ?? 0) : null
        const deVal = deNum != null && deDen != null && deDen > 0 ? deNum / deDen : null
        console.log(`[Analysis][Live] Debt/Equity — Loans: ${debtEquityLoansTotal} | Cash: ${debtEquityCashTotal} | Bank: ${debtEquityBankTotal}`)
        console.log(`[Analysis][Live] Debt/Equity — Equity: ${debtEquityEquityTotal} | Director Loans: ${directorLoansTotal}`)
        console.log(`[Analysis][Live] Debt/Equity — numerator: ${deNum} | denominator: ${deDen}${deDen != null && deDen <= 0 ? ' (<= 0, ratio blocked)' : ''} | ratio: ${deVal}`)
      }

      setAnalysisInputs({
        debtors, creditors, creditSales, openingStock, closingStock,
        dioPurchases: dioPurchaseTotal, dioDirectExpenses, dpoPurchases: dpoPurchaseTotal,
        currentRatioAssets: currentRatioAssetsTotal, currentRatioLiabilities: currentRatioLiabilitiesTotal,
        quickRatioAssets: quickRatioAssetsTotal, quickRatioLiabilities: quickRatioLiabilitiesTotal,
        longTermBorrowings: longTermBorrowingsTotal,
        roceEquity: roceEquityTotal, netProfit,
        interestExpense: interestExpenseTotal, taxPayment: taxPaymentTotal,
        nonOperatingIncome: nonOperatingIncomeTotal, nonOperatingInvestment: nonOperatingInvestmentTotal,
        directorLoans: directorLoansTotal,
        roeEquity: roeEquityTotal, internalBorrowings: internalBorrowingsTotal, intangibleAssets: intangibleAssetsTotal,
        debtEquityLoans: debtEquityLoansTotal, debtEquityCash: debtEquityCashTotal,
        debtEquityBank: debtEquityBankTotal, debtEquityEquity: debtEquityEquityTotal,
      })
      setAnalysisActivePeriod({ from, to })
      setAnalysisFetched(true)

      void saveVouchers(companyId, from, to, all)
        .catch((err: unknown) => console.error('[Analysis] Failed to persist vouchers:', err))

      const snapshotPatch: DashboardSnapshotPatch = {
        openingStock, closingStock, directExpenseTotal: directExpenses,
        dioDirectExpenseTotal: dioDirectExpenses,
      }
      if (isCurrent) {
        snapshotPatch.receivables        = debtors
        snapshotPatch.payables           = creditors
      }
      if (currentRatioAssetsTotal      != null) snapshotPatch.currentRatioAssetsTotal      = currentRatioAssetsTotal
      if (currentRatioLiabilitiesTotal != null) snapshotPatch.currentRatioLiabilitiesTotal = currentRatioLiabilitiesTotal
      if (quickRatioAssetsTotal        != null) snapshotPatch.quickRatioAssetsTotal        = quickRatioAssetsTotal
      if (quickRatioLiabilitiesTotal   != null) snapshotPatch.quickRatioLiabilitiesTotal   = quickRatioLiabilitiesTotal
      if (directorLoansTotal          != null) snapshotPatch.directorLoansTotal          = directorLoansTotal
      if (longTermBorrowingsTotal     != null) snapshotPatch.longTermBorrowings          = longTermBorrowingsTotal
      if (roceEquityTotal             != null) snapshotPatch.roceEquity                  = roceEquityTotal
      if (roeEquityTotal              != null) snapshotPatch.roeEquity                   = roeEquityTotal
      if (internalBorrowingsTotal     != null) snapshotPatch.internalBorrowings          = internalBorrowingsTotal
      if (intangibleAssetsTotal       != null) snapshotPatch.intangibleAssets            = intangibleAssetsTotal
      if (debtEquityLoansTotal        != null) snapshotPatch.debtEquityLoans             = debtEquityLoansTotal
      if (debtEquityCashTotal         != null) snapshotPatch.debtEquityCash              = debtEquityCashTotal
      if (debtEquityBankTotal         != null) snapshotPatch.debtEquityBank              = debtEquityBankTotal
      if (debtEquityEquityTotal       != null) snapshotPatch.debtEquityEquity            = debtEquityEquityTotal

      void saveDashboardSnapshot(companyId, snapshotPatch)
        .catch((err: unknown) => console.error('[Analysis] Failed to persist snapshot:', err))
    } catch (err) {
      console.error('[Dashboard] fetchAnalysisData failed:', err)
      toast.error('No data found. Please check that Tally is open and try again.')
    } finally {
      setAnalysisLoading(false)
    }
  }, [connected, tallyUrl, tallyCompany, dashboardSettings, companyId])

  // Analysis tab's own one-time DB-backfill-on-mount + preset-change auto-load,
  // mirroring the Performance tab's equivalent effect above but fully decoupled.
  const hasDoneAnalysisInitialLoadRef = useRef(false)
  useEffect(() => {
    if (!companyId) return
    if (analysisFilterPreset === 'custom') return
    loadAnalysisFromDb(analysisFilterPreset, analysisCustomFrom, analysisCustomTo).then(({ fetchedDates }) => {
      setAnalysisUncachedRange(fetchedDates.length === 0)
      if (!hasDoneAnalysisInitialLoadRef.current) {
        hasDoneAnalysisInitialLoadRef.current = true
        if (fetchedDates.length === 0) fetchAnalysisData(analysisFilterPreset, analysisCustomFrom, analysisCustomTo)
      }
    })
  }, [analysisFilterPreset, companyId, dashboardSettings]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleAnalysisFilterChange = (preset: FilterPreset) => {
    setAnalysisFilterPreset(preset)
  }

  const handleAnalysisApply = () => {
    loadAnalysisFromDb(analysisFilterPreset, analysisCustomFrom, analysisCustomTo).then(({ fetchedDates }) => {
      setAnalysisUncachedRange(fetchedDates.length === 0)
    })
  }

  const handleAnalysisFetchLive = () => {
    setAnalysisUncachedRange(false)
    setAnalysisLastFetchedAt(new Date())
    fetchAnalysisData(analysisFilterPreset, analysisCustomFrom, analysisCustomTo)
  }

  // AI-generated CFO Suggestions — ALWAYS computed from a fresh YTD read,
  // regardless of whatever period is currently selected on the Performance/
  // Analysis tabs. Reuses loadFromDb/loadAnalysisFromDb (already-proven DB-
  // cache reads) rather than a parallel fetch path — accepted trade-off:
  // this also updates what those tabs show if visited afterward, since it's
  // the same shared component state.
  //
  // The AI call itself is cached server-side (DashboardSnapshot.cfoReport +
  // cfoInputsHash): every visit recomputes the fresh kpis/ratios and
  // fingerprints them, but only calls the AI when that fingerprint differs
  // from the one that produced the last stored report — otherwise the
  // stored report is reused with no AI call. `force` (the Regenerate
  // button) always calls the AI regardless of the fingerprint.
  const generateCfoSuggestions = useCallback(async (force = false) => {
    if (!companyId) return
    setCfoLoading(true)
    setCfoError(false)
    try {
      const [perf, analysis, snapshot] = await Promise.all([
        loadFromDb('ytd', '', ''),
        loadAnalysisFromDb('ytd', '', ''),
        fetchDashboardSnapshot(companyId),
      ])
      const cfoYtdDays = daysSinceFyStart(todayStr())
      const ratios = computeRatios(analysis.data, {
        dso: (dashboardSettings.ytd?.dsoDaysMode ?? 'ytd') === '365' ? 365 : cfoYtdDays,
        dio: (dashboardSettings.ytd?.dioDaysMode ?? 'ytd') === '365' ? 365 : cfoYtdDays,
        dpo: (dashboardSettings.ytd?.dpoDaysMode ?? 'ytd') === '365' ? 365 : cfoYtdDays,
      })
      const kpis: CfoKpis = {
        totalSales:     perf.data.total,
        monthlySales:   perf.data.salesTrend,
        grossMargin:    perf.data.grossMargin,
        grossMarginPct: perf.data.grossMarginPct,
        ebitda:         perf.data.ebitda,
        ebitdaPct:      perf.data.ebitdaPct,
        netProfit:      perf.data.netProfit,
        netProfitPct:   perf.data.netProfitPct,
        cashInHand:     perf.data.cashInHand,
        bankBalance:    perf.data.bankBalance,
        cashInflow:     perf.data.cashInflow,
        cashOutflow:    perf.data.cashOutflow,
        bankInflow:     perf.data.bankInflow,
        bankOutflow:    perf.data.bankOutflow,
        receivables:    perf.data.receivables,
        payables:       perf.data.payables,
        topItems:       perf.data.topItems,
        topDebtors:     perf.data.topDebtors,
        slowStock:      perf.data.slowStock,
        debtorBalances: perf.data.debtorBalances,
      }
      setCfoKpis(kpis)
      setCfoRatios(ratios)

      const fingerprint = JSON.stringify({ kpis, ratios })
      if (!force && snapshot?.cfoReport && snapshot.cfoInputsHash === fingerprint) {
        setCfoReport(snapshot.cfoReport as CfoReport)
        setCfoGeneratedAt(new Date())
        return
      }

      const report = await fetchCfoSuggestions(companyId, ratios, kpis)
      setCfoReport(report)
      setCfoGeneratedAt(new Date())
      void saveDashboardSnapshot(companyId, { cfoReport: report, cfoInputsHash: fingerprint })
    } catch (err) {
      console.error('[CfoSuggestions] failed:', err)
      setCfoError(true)
    } finally {
      setCfoLoading(false)
    }
  }, [companyId, dashboardSettings, loadFromDb, loadAnalysisFromDb])

  // Re-checks every time the user switches INTO the CFO tab (not merely
  // because the component re-rendered while already on it) — the ref
  // detects the transition so this doesn't loop. generateCfoSuggestions
  // itself decides whether that means a real AI call or an instant cache
  // hit, based on the data fingerprint.
  const prevTabRef = useRef<Tab | null>(null)
  useEffect(() => {
    const enteredCfo = activeTab === 'cfo' && prevTabRef.current !== 'cfo'
    prevTabRef.current = activeTab
    if (!enteredCfo || !companyId) return
    generateCfoSuggestions()
  }, [activeTab, companyId, generateCfoSuggestions])

  // Browsers suggest document.title as the default "Save as PDF" filename,
  // so swap it to the company name for the duration of the print dialog and
  // restore it once the dialog closes (afterprint fires on both Save and
  // Cancel).
  const printCfoReport = () => {
    const originalTitle = document.title
    const safeName = (company?.name ?? 'Company').replace(/[\\/:*?"<>|]/g, '').trim()
    document.title = `${safeName} - CFO Report${activePeriod ? ` - ${activePeriod.from}_${activePeriod.to}` : ''}`
    const restoreTitle = () => {
      document.title = originalTitle
      window.removeEventListener('afterprint', restoreTitle)
    }
    window.addEventListener('afterprint', restoreTitle)
    toast('In the print dialog, open "More settings" and uncheck "Headers and footers" for a clean PDF.', { duration: 6000, icon: '💡' })
    window.print()
  }

  // Shared PDF export for the Performance / KPI Analytics tabs — same
  // window.print() + document.title-swap trick as printCfoReport, generalized
  // with a label and period so each tab's file gets a sensible default name.
  const printDashboardReport = (label: string, period: { from: string; to: string } | null) => {
    const originalTitle = document.title
    const safeName = (company?.name ?? 'Company').replace(/[\\/:*?"<>|]/g, '').trim()
    document.title = `${safeName} - ${label}${period ? ` - ${period.from}_${period.to}` : ''}`
    const restoreTitle = () => {
      document.title = originalTitle
      window.removeEventListener('afterprint', restoreTitle)
    }
    window.addEventListener('afterprint', restoreTitle)
    toast('In the print dialog, open "More settings" and uncheck "Headers and footers" for a clean PDF.', { duration: 6000, icon: '💡' })
    window.print()
  }

  const reloadMeta = () => {
    if (!companyId) return
    fetchSalesTargets(companyId, fyYear)
      .then(rows => {
        const map: Record<number, number> = {}
        rows.forEach(r => { map[r.month] = r.target })
        setMonthlyTargets(map)
      })
      .catch(() => { /* optional */ })
    return fetchDashboardSettings(companyId)
      .then(s => { setDashboardSettings(s); return s })
      .catch(() => ({} as DashboardSettings))
  }

  // Load targets/settings on mount
  useEffect(() => {
    reloadMeta()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // DB-only read, auto-fired on preset/company/settings change — never calls
  // Tally. Only for Today / This Quarter / YTD. Custom is deliberately excluded:
  // it used to also auto-fire on every customFrom/customTo change, so picking a
  // start then an end date on the calendar fired two separate reads (and, if
  // Apply was clicked before both had landed, could race and appear to "double"
  // data on screen). Custom is now fully manual — see handleApply below. The one
  // exception here is the very first run ever for this company: if nothing has
  // been cached yet for the active non-custom preset, do a one-time live fetch
  // to populate it (mirrors the previously-documented "auto-fetch today on
  // mount" behavior).
  const hasDoneInitialLoadRef = useRef(false)
  useEffect(() => {
    if (!companyId) return
    if (filterPreset === 'custom') return
    loadFromDb(filterPreset, customFrom, customTo).then(({ fetchedDates }) => {
      setUncachedRange(fetchedDates.length === 0)
      if (!hasDoneInitialLoadRef.current) {
        hasDoneInitialLoadRef.current = true
        if (fetchedDates.length === 0) fetchData(filterPreset, customFrom, customTo)
      }
    })
  }, [filterPreset, companyId, dashboardSettings]) // eslint-disable-line react-hooks/exhaustive-deps

  // Auto-refresh from DB when the notify-triggered background sync
  // (useDaybookNotifications, mounted once at CompanyLayout regardless of
  // which page is visible) finishes updating this company's data — without
  // this, a Tally edit only shows up here after a manual page reload.
  // Skipped for Custom mode, matching the "Custom is fully manual" design
  // above — an edit landing in the DB shouldn't itself trigger a read while
  // the user's mid-adjusting a custom date range.
  const lastDaybookSync = useDaybookSyncStore((s) => (companyId ? s.lastUpdated[companyId] : undefined))
  useEffect(() => {
    if (!companyId || !lastDaybookSync) return
    if (filterPreset === 'custom') return
    loadFromDb(filterPreset, customFrom, customTo).then(({ fetchedDates }) => {
      setUncachedRange(fetchedDates.length === 0)
    })
  }, [lastDaybookSync]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleTabChange = (tab: Tab) => {
    setActiveTab(tab)
  }

  const handleFilterChange = (preset: FilterPreset) => {
    setFilterPreset(preset)
  }

  // Custom mode only — reads whatever's already cached in the DB for the
  // chosen from/to. Never touches Tally. Picking dates no longer fires any
  // request on its own; this is the only trigger for Custom now.
  const handleApply = () => {
    loadFromDb(filterPreset, customFrom, customTo).then(({ fetchedDates }) => {
      setUncachedRange(fetchedDates.length === 0)
    })
  }

  // Always available regardless of preset — explicit live Tally fetch, which
  // also persists the result to the DB for future DB-only reads.
  const handleFetchLive = () => {
    setUncachedRange(false)
    setLastFetchedAt(new Date())
    fetchData(filterPreset, customFrom, customTo)
  }

  // Shared by every export below — the filename period always reflects
  // activePeriod (the currently-applied Today/YTD/Custom filter), so a
  // download always matches what's on screen.
  //
  // A real, properly-quoted CSV — not a tab-separated file wearing an .xls
  // extension. The old trick (TSV + .xls) only opens correctly in Windows
  // Excel, which sniffs the content; Excel/Numbers on Mac trust the
  // extension, expect the real OLE2/xlsx binary format, and fail back to
  // splitting on commas only — which is why everything landed in column A.
  const csvCell = (cell: string | number) => {
    const s = String(cell)
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
  }

  const downloadXls = (rows: (string | number)[][], filenamePrefix: string) => {
    const csv  = rows.map(r => r.map(csvCell).join(',')).join('\r\n')
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8' })
    const url  = URL.createObjectURL(blob)
    const a    = document.createElement('a')
    const period = activePeriod ? `${activePeriod.from}_${activePeriod.to}` : 'export'
    a.href     = url
    a.download = `${filenamePrefix}_${period}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  // Row-building for a full year's data is synchronous CPU work — for large
  // exports (e.g. thousands of purchase vouchers over a YTD range) that can
  // take long enough to notice, and being synchronous it would otherwise
  // block the spinner from ever painting. Yielding one tick first lets React
  // commit the "exporting…" state before the heavy string-building runs.
  const yieldToPaint = () => new Promise(resolve => setTimeout(resolve, 0))

  const exportPurchasesToXls = async () => {
    if (purchaseVouchers.length === 0) { toast.error('No purchase vouchers to export'); return }
    setExportingPurchases(true)
    try {
      await yieldToPaint()
      const rows = [
        ['Date', 'Voucher No', 'Voucher Type', 'Party', 'Role', 'Total Amount (with GST)', 'Taxable Amount', 'GST Amount'],
        ...purchaseVouchers.map(v => [
          v.date,
          v.voucherNo,
          v.type,
          v.party,
          v.role,
          v.amount.toFixed(2),
          v.taxableAmount.toFixed(2),
          (v.amount - v.taxableAmount).toFixed(2),
        ]),
        [],
        ['', '', '', '', 'TOTAL',
          purchaseVouchers.reduce((s, v) => s + v.amount, 0).toFixed(2),
          purchaseVouchers.reduce((s, v) => s + v.taxableAmount, 0).toFixed(2),
          purchaseVouchers.reduce((s, v) => s + (v.amount - v.taxableAmount), 0).toFixed(2),
        ],
      ]
      downloadXls(rows, 'vouchers')
    } finally {
      setExportingPurchases(false)
    }
  }

  const exportTopItemsToXls = async () => {
    if (topItems.length === 0) { toast.error('No items to export'); return }
    setExportingItems(true)
    try {
      await yieldToPaint()
      const rows = [
        ['Description', 'Qty', 'Amt (₹)'],
        ...topItems.map(item => [
          item.name,
          `${item.qty % 1 === 0 ? item.qty : item.qty.toFixed(2)}${item.unit ? ' ' + item.unit : ''}`,
          item.amount.toFixed(2),
        ]),
      ]
      downloadXls(rows, 'top_items')
    } finally {
      setExportingItems(false)
    }
  }

  const exportTopDebtorsToXls = async () => {
    if (topDebtors.length === 0) { toast.error('No debtors to export'); return }
    setExportingDebtors(true)
    try {
      await yieldToPaint()
      const rows = [
        ['Party', 'Amt (₹)'],
        ...topDebtors.map(d => [d.name, d.amount.toFixed(2)]),
      ]
      downloadXls(rows, 'top_debtors')
    } finally {
      setExportingDebtors(false)
    }
  }

  const exportSlowStockToXls = async () => {
    if (slowStock.length === 0) { toast.error('No slow-moving items to export'); return }
    setExportingSlowStock(true)
    try {
      const stockItems = await fetchTallyStockItems(tallyUrl, tallyCompany)
      const byName = new Map(stockItems.map(s => [s.name, s]))
      const rows = [
        ['Stock', 'Last Sale Date', 'Days Since Sale', 'Closing Qty', 'Closing Value (₹)'],
        ...slowStock.map(item => {
          const match = byName.get(item.name)
          return [
            item.name,
            item.lastSaleDate,
            item.daysSince,
            match?.closingQty != null ? match.closingQty.toFixed(2) : 'N/A',
            match?.closingValue != null ? match.closingValue.toFixed(2) : 'N/A',
          ]
        }),
      ]
      downloadXls(rows, 'slow_moving_stock')
    } catch {
      toast.error('Could not fetch current stock qty/value from Tally.')
    } finally {
      setExportingSlowStock(false)
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div className="flex flex-col h-full overflow-y-auto bg-grid-paper">

      <CompanyPageHeader
        title={company?.name ?? 'Dashboard'}
        subtitle="Dashboard"
        actions={
          <>
            {!connected && (
              <span className="text-[11px] text-amber-600 bg-amber-50 border border-amber-200 rounded-full px-2.5 py-1 dark:bg-amber-950/40 dark:border-amber-900 dark:text-amber-400">
                Extension not connected
              </span>
            )}
          </>
        }
      />

      {/* ── Tabs — outside the bordered header, no border of its own ── */}
      <div className="px-6 pt-3 shrink-0">
        <div className="flex items-center gap-4">
          {TABS.map(t => (
            <button
              key={t.key}
              onClick={() => handleTabChange(t.key)}
              className={`text-sm px-3 py-1.5 rounded-lg transition-colors ${
                activeTab === t.key
                  ? 'font-semibold text-foreground bg-accent'
                  : 'font-medium text-muted-foreground hover:text-foreground hover:bg-accent/50'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {/* ── Page body ── */}
      <div className="px-6 py-5 w-full space-y-5">

        {/* ══════════════════ PERFORMANCE TAB ══════════════════ */}
        {activeTab === 'performance' && (
          <FormatProvider compact={compactFormat}>
            {/* Filter bar */}
            <div className="flex items-center gap-4 flex-wrap">
              <div className="flex items-center gap-4">
                {FILTERS.map(f => (
                  <button
                    key={f.key}
                    onClick={() => handleFilterChange(f.key)}
                    className={`pb-1 text-xs border-b-2 transition-colors ${
                      filterPreset === f.key
                        ? 'font-semibold text-foreground border-foreground'
                        : 'font-medium text-muted-foreground border-transparent hover:text-foreground'
                    }`}
                  >
                    {f.key === 'today' ? `${f.label} — ${todayLabel}` : f.label}
                  </button>
                ))}
              </div>

              {filterPreset === 'custom' && (
                <>
                  <input
                    type="date" value={customFrom}
                    onChange={e => setCustomFrom(e.target.value)}
                    className="text-xs border border-border rounded-full px-3 py-1.5 bg-muted text-foreground outline-none focus:border-primary"
                  />
                  <span className="text-muted-foreground text-xs">to</span>
                  <input
                    type="date" value={customTo}
                    onChange={e => setCustomTo(e.target.value)}
                    className="text-xs border border-border rounded-full px-3 py-1.5 bg-muted text-foreground outline-none focus:border-primary"
                  />
                  <button
                    onClick={handleApply}
                    disabled={loading}
                    className="px-4 py-1.5 bg-primary text-primary-foreground text-xs font-semibold rounded-full hover:bg-primary/90 disabled:opacity-50 transition-colors"
                  >
                    Go
                  </button>
                </>
              )}

              <button
                onClick={handleFetchLive}
                disabled={loading}
                title="Fetch the latest data from Tally and save it to the database"
                className="flex items-center gap-1 px-3 py-1.5 bg-secondary text-secondary-foreground text-xs font-semibold rounded-lg hover:bg-muted disabled:opacity-50 transition-colors"
              >
                <Zap className="w-3 h-3" />
                Fetch Live
              </button>

              <button
                onClick={() => printDashboardReport('Performance Dashboard', activePeriod)}
                disabled={!fetched}
                title="Generate a PDF of this dashboard (opens the print dialog — choose Save as PDF)"
                className="flex items-center gap-1 px-3 py-1.5 bg-secondary text-secondary-foreground text-xs font-semibold rounded-lg hover:bg-muted disabled:opacity-50 transition-colors"
              >
                <Download className="w-3 h-3" />
                Save
              </button>

              <label className="flex items-center gap-1.5 text-xs text-muted-foreground cursor-pointer select-none">
                <Switch checked={compactFormat} onCheckedChange={setCompactFormat} size="sm" />
                In Thousands
              </label>
              {fetched && purchaseVouchers.length > 0 && (
                <button
                  onClick={exportPurchasesToXls}
                  disabled={exportingPurchases}
                  title={`Export ${purchaseVouchers.length} vouchers to CSV`}
                  className="flex items-center gap-1 px-3 py-1.5 bg-green-600 text-white text-xs font-semibold rounded-lg hover:bg-green-700 disabled:opacity-50"
                >
                  {exportingPurchases
                    ? <RefreshCw className="w-3 h-3 animate-spin" />
                    : <Download className="w-3 h-3" />}
                  Export ({purchaseVouchers.length})
                </button>
              )}

              {lastFetchedAt && (
                <span className="ml-auto text-[11px] text-muted-foreground">
                  Last fetched: {lastFetchedAt.toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                </span>
              )}

              {loading && <RefreshCw className="w-3.5 h-3.5 text-blue-500 animate-spin" />}
            </div>

            <div className="print-report space-y-4">
            {/* Print-only report header — hidden on screen, shown only in the PDF/print output */}
            <div className="hidden print:block">
              <p className="text-lg font-bold text-foreground">{company?.name ?? 'Company'}</p>
              {company?.gstin && <p className="text-sm text-muted-foreground">GSTIN: {company.gstin}</p>}
              <p className="text-sm font-semibold text-foreground mt-2">Performance Dashboard</p>
              {activePeriod && (
                <p className="text-xs text-muted-foreground">
                  Reporting Period: {activePeriod.from === activePeriod.to
                    ? new Date(activePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
                    : `${new Date(activePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })} – ${new Date(activePeriod.to).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`}
                </p>
              )}
              <div className="border-t-2 border-brand-600 mt-3 mb-1" />
            </div>

            {filterPreset === 'today' ? (
              /* Today view — new shadcn-style widget layout (matches the shadcn dashboard mockup) */
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 sm:gap-4 lg:grid-cols-3">
                <SalesWidget current={fetched ? total : null} previous={fetched ? prevDaySales : null} />
                <SalesChartWidget data={fetched ? salesTrend : []} />
                <CashWidget
                  inflow={fetched ? cashInflow : null}
                  outflow={fetched ? cashOutflow : null}
                  inHand={fetched ? cashInHand : null}
                />
                <BankWidget
                  inflow={fetched ? bankInflow : null}
                  outflow={fetched ? bankOutflow : null}
                  balance={fetched ? bankBalance : null}
                />
                <ReceivablesWidget total={fetched ? receivables : null} />
                <PayablesWidget total={fetched ? payables : null} />
                <DebtorsWidget
                  data={fetched ? topDebtors.slice(0, 8) : []}
                  onDownload={fetched && topDebtors.length > 0 ? exportTopDebtorsToXls : undefined}
                  downloadPending={exportingDebtors}
                />
                <ItemsWidget
                  data={fetched ? topItems.map(item => ({ name: item.name, qty: item.qty, unit: item.unit, amount: item.amount })) : []}
                  onDownload={fetched && topItems.length > 0 ? exportTopItemsToXls : undefined}
                  downloadPending={exportingItems}
                />
              </div>
            ) : filterPreset === 'ytd' ? (
              /* YTD view — new shadcn-style widget layout (matches the shadcn dashboard mockup) */
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 sm:gap-4 lg:grid-cols-4">
                <SalesWidget
                  title="Sales (YTD)"
                  current={fetched ? total : null}
                  previous={null}
                  targetInfo={(() => {
                    const periodTarget = fetched
                      ? computeTargetForPeriod(filterPreset, customFrom, customTo, monthlyTargets)
                      : null
                    return (periodTarget && total > 0)
                      ? { target: periodTarget, achieved: (total / periodTarget) * 100 }
                      : null
                  })()}
                />
                <GrossMarginWidget
                  value={fetched ? grossMargin : null}
                  pct={fetched ? grossMarginPct : null}
                  targetPct={dashboardSettings.ytd?.grossMarginTarget ?? null}
                />
                <EbitdaWidget
                  value={fetched ? ebitda : null}
                  pct={fetched ? ebitdaPct : null}
                />
                <NetMarginWidget
                  value={fetched ? netProfit : null}
                  pct={fetched ? netProfitPct : null}
                />
                <SalesChartWidget
                  title="Sales Trend — Monthly (YTD)"
                  data={fetched ? salesTrend : []}
                  className="lg:col-span-4"
                />
                <CashWidget
                  inflow={fetched ? cashInflow : null}
                  outflow={fetched ? cashOutflow : null}
                  inHand={fetched ? cashInHand : null}
                />
                <BankWidget
                  inflow={fetched ? bankInflow : null}
                  outflow={fetched ? bankOutflow : null}
                  balance={fetched ? bankBalance : null}
                />
                <ReceivablesWidget total={fetched ? receivables : null} />
                <PayablesWidget total={fetched ? payables : null} />
                <DebtorsWidget
                  data={fetched ? topDebtors.slice(0, 8) : []}
                  onDownload={fetched && topDebtors.length > 0 ? exportTopDebtorsToXls : undefined}
                  downloadPending={exportingDebtors}
                />
                <ItemsWidget
                  data={fetched ? topItems.map(item => ({ name: item.name, qty: item.qty, unit: item.unit, amount: item.amount })) : []}
                  onDownload={fetched && topItems.length > 0 ? exportTopItemsToXls : undefined}
                  downloadPending={exportingItems}
                />
                <StocksWidget
                  data={fetched ? slowStock.slice(0, 10) : []}
                  onDownload={fetched && slowStock.length > 0 ? exportSlowStockToXls : undefined}
                  downloadPending={exportingSlowStock}
                />
              </div>
            ) : (
              /* Custom range — matches Today's tile layout (no Gross Margin/EBITDA/Net
                 Margin — those are YTD-only metrics that need opening/closing stock). */
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 sm:gap-4 lg:grid-cols-3">
                <SalesWidget
                  title={`Sales (${
                    activePeriod
                      ? activePeriod.from === activePeriod.to
                        ? new Date(activePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
                        : `${new Date(activePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })} – ${new Date(activePeriod.to).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`
                      : 'Loading…'
                  })`}
                  current={fetched ? total : null}
                  previous={null}
                  targetInfo={(() => {
                    const periodTarget = fetched
                      ? computeTargetForPeriod(filterPreset, customFrom, customTo, monthlyTargets)
                      : null
                    return (periodTarget && total > 0)
                      ? { target: periodTarget, achieved: (total / periodTarget) * 100 }
                      : null
                  })()}
                />
                <SalesChartWidget data={fetched ? salesTrend : []} />
                <CashWidget
                  inflow={fetched ? cashInflow : null}
                  outflow={fetched ? cashOutflow : null}
                  inHand={fetched ? cashInHand : null}
                />
                <BankWidget
                  inflow={fetched ? bankInflow : null}
                  outflow={fetched ? bankOutflow : null}
                  balance={fetched ? bankBalance : null}
                />
                <ReceivablesWidget total={fetched ? receivables : null} />
                <PayablesWidget total={fetched ? payables : null} />
                <DebtorsWidget
                  data={fetched ? topDebtors.slice(0, 8) : []}
                  onDownload={fetched && topDebtors.length > 0 ? exportTopDebtorsToXls : undefined}
                  downloadPending={exportingDebtors}
                />
                <ItemsWidget
                  data={fetched ? topItems.map(item => ({ name: item.name, qty: item.qty, unit: item.unit, amount: item.amount })) : []}
                  onDownload={fetched && topItems.length > 0 ? exportTopItemsToXls : undefined}
                  downloadPending={exportingItems}
                />
              </div>
            )}
            </div>

            {/* Error */}
            {error && (
              <div className="flex items-center gap-3 bg-red-50 border border-red-200 rounded-xl px-4 py-3 dark:bg-red-950/30 dark:border-red-900">
                <AlertCircle className="w-4 h-4 text-red-500 shrink-0" />
                <p className="text-xs text-red-600 dark:text-red-400">No data available. Please ensure Tally is open and click Refresh.</p>
              </div>
            )}

            {/* Uncached range hint — DB has never seen this range; distinct from "genuinely zero vouchers" */}
            {!error && !loading && fetched && uncachedRange && (
              <div className="flex items-center gap-3 bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 dark:bg-amber-950/30 dark:border-amber-900">
                <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0" />
                <p className="text-xs text-amber-700 dark:text-amber-400">No cached data for this range yet — click Fetch Live to pull it from Tally.</p>
              </div>
            )}

          </FormatProvider>
        )}

        {/* ══════════════════ ANALYSIS TAB ══════════════════ */}
        {activeTab === 'analysis' && (
          <div className="space-y-5">

            {/* Filter bar — fully independent of the Performance tab's filter above */}
            <div className="flex items-center gap-4 flex-wrap">
              <div className="flex items-center gap-4">
                {ANALYSIS_FILTERS.map(f => (
                  <button
                    key={f.key}
                    onClick={() => handleAnalysisFilterChange(f.key)}
                    className={`pb-1 text-xs border-b-2 transition-colors ${
                      analysisFilterPreset === f.key
                        ? 'font-semibold text-foreground border-foreground'
                        : 'font-medium text-muted-foreground border-transparent hover:text-foreground'
                    }`}
                  >
                    {f.key === 'today' ? `${f.label} — ${todayLabel}` : f.label}
                  </button>
                ))}
              </div>

              {analysisFilterPreset === 'custom' && (
                <>
                  <input
                    type="date" value={analysisCustomFrom}
                    onChange={e => setAnalysisCustomFrom(e.target.value)}
                    className="text-xs border border-border rounded-full px-3 py-1.5 bg-muted text-foreground outline-none focus:border-primary"
                  />
                  <span className="text-muted-foreground text-xs">to</span>
                  <input
                    type="date" value={analysisCustomTo}
                    onChange={e => setAnalysisCustomTo(e.target.value)}
                    className="text-xs border border-border rounded-full px-3 py-1.5 bg-muted text-foreground outline-none focus:border-primary"
                  />
                  <button
                    onClick={handleAnalysisApply}
                    disabled={analysisLoading}
                    className="px-4 py-1.5 bg-primary text-primary-foreground text-xs font-semibold rounded-full hover:bg-primary/90 disabled:opacity-50 transition-colors"
                  >
                    Go
                  </button>
                </>
              )}

              <button
                onClick={handleAnalysisFetchLive}
                disabled={analysisLoading}
                title="Fetch the latest data from Tally and save it to the database"
                className="flex items-center gap-1 px-3 py-1.5 bg-secondary text-secondary-foreground text-xs font-semibold rounded-lg hover:bg-muted disabled:opacity-50 transition-colors"
              >
                <Zap className="w-3 h-3" />
                Fetch Live
              </button>

              <button
                onClick={() => printDashboardReport('KPI Analytics', analysisActivePeriod)}
                disabled={!analysisFetched}
                title="Generate a PDF of this dashboard (opens the print dialog — choose Save as PDF)"
                className="flex items-center gap-1 px-3 py-1.5 bg-secondary text-secondary-foreground text-xs font-semibold rounded-lg hover:bg-muted disabled:opacity-50 transition-colors"
              >
                <Download className="w-3 h-3" />
                Save
              </button>

              {analysisLastFetchedAt && (
                <span className="ml-auto text-[11px] text-muted-foreground">
                  Last fetched: {analysisLastFetchedAt.toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                </span>
              )}

              {analysisLoading && <RefreshCw className="w-3.5 h-3.5 text-blue-500 animate-spin" />}
            </div>

            {!analysisLoading && analysisFetched && analysisUncachedRange && (
              <div className="flex items-center gap-2 px-3 py-2 bg-amber-50 border border-amber-200 rounded-lg">
                <AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                <p className="text-xs text-amber-700">No cached data for this range yet — click Fetch Live to pull it from Tally.</p>
              </div>
            )}

            {analysisActivePeriod && (
              <p className="text-xs text-muted-foreground print:hidden">
                Showing: {analysisActivePeriod.from === analysisActivePeriod.to
                  ? new Date(analysisActivePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
                  : `${new Date(analysisActivePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })} – ${new Date(analysisActivePeriod.to).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`}
              </p>
            )}

            <div className="print-report space-y-4">
            {/* Print-only report header — hidden on screen, shown only in the PDF/print output */}
            <div className="hidden print:block">
              <p className="text-lg font-bold text-foreground">{company?.name ?? 'Company'}</p>
              {company?.gstin && <p className="text-sm text-muted-foreground">GSTIN: {company.gstin}</p>}
              <p className="text-sm font-semibold text-foreground mt-2">KPI Analytics</p>
              {analysisActivePeriod && (
                <p className="text-xs text-muted-foreground">
                  Reporting Period: {analysisActivePeriod.from === analysisActivePeriod.to
                    ? new Date(analysisActivePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
                    : `${new Date(analysisActivePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })} – ${new Date(analysisActivePeriod.to).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`}
                </p>
              )}
              <div className="border-t-2 border-brand-600 mt-3 mb-1" />
            </div>

            {/* 9 ratio KPI cards */}
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 sm:gap-4 lg:grid-cols-4">
              {(() => {
                const ytdDaysForRatios = daysSinceFyStart(analysisActivePeriod?.to ?? todayStr())
                const dayMultipliers = {
                  dso: (dashboardSettings.ytd?.dsoDaysMode ?? 'ytd') === '365' ? 365 : ytdDaysForRatios,
                  dio: (dashboardSettings.ytd?.dioDaysMode ?? 'ytd') === '365' ? 365 : ytdDaysForRatios,
                  dpo: (dashboardSettings.ytd?.dpoDaysMode ?? 'ytd') === '365' ? 365 : ytdDaysForRatios,
                }
                const r = computeRatios(analysisInputs, dayMultipliers)
                return (
                  <>
                    <RatioWidget title="DSO" subtitle="Days Sales Outstanding" icon={CalendarDays} value={r.dso} suffix=" days" />
                    <RatioWidget title="DIO" subtitle="Days Inventory Outstanding" icon={Package} value={r.dio} suffix=" days" />
                    <RatioWidget title="DPO" subtitle="Days Payables Outstanding" icon={Clock} value={r.dpo} suffix=" days" />
                    <RatioWidget title="CCC" subtitle="Cash Conversion Cycle (DSO + DIO − DPO)" icon={RefreshCw} value={r.ccc} suffix=" days" />
                    <RatioWidget title="Current Ratio" subtitle="Current Assets / Current Liabilities" icon={Scale} value={r.currentRatio} suffix=" times" />
                    <RatioWidget title="Quick Ratio" subtitle="Quick Assets / Current Liabilities" icon={Zap} value={r.quickRatio} suffix=" times" />
                    <RatioWidget title="ROCE" subtitle="Return on Capital Employed" icon={TrendingUp} value={r.roce} suffix="%" />
                    <RatioWidget title="ROE" subtitle="Return on Equity" icon={LineChart} value={r.roe} suffix="%" />
                    <RatioWidget title="Debt / Equity" icon={Landmark} value={r.debtEquity} suffix=" times" />
                  </>
                )
              })()}
            </div>
            </div>

          </div>
        )}

        {/* ══════════════════ CFO SUGGESTIONS TAB ══════════════════ */}
        {activeTab === 'cfo' && (
          <div className="space-y-4">
            <div className="flex items-center gap-2 mb-1">
              <Lightbulb className="w-4 h-4 text-amber-500" />
              <p className="text-sm font-semibold text-foreground">AI-Powered Analysis on YTD Basis</p>
              {cfoLoading ? (
                <span className="ml-auto flex items-center gap-1.5 text-[11px] text-muted-foreground">
                  <RefreshCw className="w-3 h-3 animate-spin" /> Generating…
                </span>
              ) : (
                <div className="ml-auto flex items-center gap-3">
                  {cfoReport && (
                    <button
                      onClick={printCfoReport}
                      title="Generate a PDF of this report (opens the print dialog — choose Save as PDF)"
                      className="flex items-center gap-1 text-[11px] font-medium text-muted-foreground hover:text-foreground"
                    >
                      <Download className="w-3 h-3" /> Generate PDF
                    </button>
                  )}
                  <button
                    onClick={() => generateCfoSuggestions(true)}
                    title="Regenerate the report from the latest YTD data"
                    className="flex items-center gap-1 text-[11px] font-medium text-blue-600 hover:text-blue-700"
                  >
                    <RefreshCw className="w-3 h-3" /> Regenerate
                  </button>
                </div>
              )}
            </div>

            {cfoLoading && !cfoReport ? (
              <div className="h-40 flex flex-col items-center justify-center gap-2 text-muted-foreground border border-dashed border-border rounded-xl">
                <RefreshCw className="w-5 h-5 animate-spin" />
                <p className="text-sm">Generating your YTD report…</p>
              </div>
            ) : !cfoReport ? (
              <div className="h-40 flex flex-col items-center justify-center gap-1 text-muted-foreground border border-dashed border-border rounded-xl">
                <p className="text-sm font-medium">{cfoError ? "Couldn't generate the report" : 'No report yet'}</p>
                <p className="text-xs">Click Regenerate to try again.</p>
              </div>
            ) : (
              <div className="space-y-4 print-cfo-report">
                {cfoError && (
                  <p className="text-xs text-red-500 print:hidden">Last regenerate attempt failed — showing the previous report.</p>
                )}

                {/* Report Header */}
                <div className="bg-card border border-border rounded-xl p-5">
                  <p className="text-lg font-bold text-foreground">{company?.name ?? 'Company'}</p>
                  <p className="text-sm text-muted-foreground mt-0.5">Financial Performance Summary on YTD Basis</p>
                  <div className="flex items-center justify-between gap-4 mt-1">
                    <p className="text-xs text-muted-foreground">
                      Reporting Period: {activePeriod ? `${formatDate(activePeriod.from)} – ${formatDate(activePeriod.to)}` : '—'}
                    </p>
                    {cfoGeneratedAt && (
                      <p className="text-xs text-muted-foreground shrink-0">
                        {cfoGeneratedAt.toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                      </p>
                    )}
                  </div>
                  <div className="border-t-2 border-brand-600 mt-3" />
                </div>

                {/* Key Financial Metrics */}
                <div>
                  <ReportSectionHeading n={1} title="Key Financial Metrics" />
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <ReportStatCard label="Total Sales" value={formatCurrency(cfoKpis?.totalSales ?? 0)} sub="YTD Turnover" tone="blue" />
                    <ReportStatCard
                      label="Gross Margin"
                      value={cfoKpis?.grossMargin != null ? formatCurrency(cfoKpis.grossMargin) : '—'}
                      sub={cfoKpis?.grossMarginPct != null ? `${cfoKpis.grossMarginPct.toFixed(1)}% Margin` : 'No data available'}
                      tone="blue"
                    />
                    <ReportStatCard
                      label="EBITDA"
                      value={cfoKpis?.ebitda != null ? formatCurrency(cfoKpis.ebitda) : '—'}
                      sub={cfoKpis?.ebitdaPct != null ? `${cfoKpis.ebitdaPct.toFixed(1)}% Margin` : 'No data available'}
                      tone="blue"
                    />
                    <ReportStatCard
                      label="Net Profit"
                      value={cfoKpis?.netProfit != null ? formatCurrency(cfoKpis.netProfit) : '—'}
                      sub={cfoKpis?.netProfitPct != null ? `${cfoKpis.netProfitPct.toFixed(1)}% Margin` : 'No data available'}
                      tone={(cfoKpis?.netProfit ?? 0) < 0 ? 'danger' : 'blue'}
                    />
                  </div>
                  <div className="mt-3 rounded-xl border border-brand-100 bg-brand-50 p-4">
                    <p className="text-sm text-foreground leading-relaxed">
                      <span className="font-bold text-brand-700">Critical Margin Structural Anomaly: </span>
                      {cfoKpis?.grossMarginPct == null || cfoKpis?.netProfitPct == null ? (
                        <span>No data available — Gross Margin and/or Net Profit could not be computed for this period.</span>
                      ) : hasMarginAnomaly(cfoKpis.grossMarginPct, cfoKpis.netProfitPct) ? (
                        <>
                          The core operating Gross Margin stands at an extremely thin{' '}
                          <span className="font-semibold">{cfoKpis.grossMarginPct.toFixed(1)}%</span> (Sales minus Purchases), whereas the Net Profit margin is higher at{' '}
                          <span className="font-semibold">{cfoKpis.netProfitPct.toFixed(1)}%</span>. This indicates that core trading operations are under-performing, and profitability is driven by substantial{' '}
                          <span className="font-semibold">Indirect Income</span> or non-operating revenue.
                        </>
                      ) : (
                        <span>
                          None detected — Net Profit margin ({cfoKpis.netProfitPct.toFixed(1)}%) is at or below Gross Margin ({cfoKpis.grossMarginPct.toFixed(1)}%), consistent with a structurally healthy core trading business.
                        </span>
                      )}
                    </p>
                  </div>
                </div>

                {/* Cash & Bank Liquidity Analysis */}
                <div>
                  <ReportSectionHeading n={2} title="Cash & Bank Liquidity Analysis" />
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-3">
                    <ReportStatCard
                      label="Cash in Hand"
                      value={cfoKpis?.cashInHand != null ? formatCurrency(cfoKpis.cashInHand) : '—'}
                      sub={flowNote(cfoKpis?.cashInflow ?? null, cfoKpis?.cashOutflow ?? null)}
                      tone="green"
                    />
                    <ReportStatCard
                      label="Bank Balance"
                      value={cfoKpis?.bankBalance != null ? `${formatCurrency(cfoKpis.bankBalance)}${cfoKpis.bankBalance < 0 ? ' (OD)' : ''}` : '—'}
                      sub={flowNote(cfoKpis?.bankInflow ?? null, cfoKpis?.bankOutflow ?? null)}
                      tone={(cfoKpis?.bankBalance ?? 0) < 0 ? 'danger' : 'blue'}
                    />
                    <ReportStatCard
                      label="Current Ratio"
                      value={cfoRatios?.currentRatio != null ? cfoRatios.currentRatio.toFixed(2) : '—'}
                      sub="Benchmark: 1.5 - 2.0"
                      tone={cfoRatios?.currentRatio != null && cfoRatios.currentRatio < 1.5 ? 'danger' : 'blue'}
                    />
                    <ReportStatCard
                      label="Quick Ratio"
                      value={cfoRatios?.quickRatio != null ? cfoRatios.quickRatio.toFixed(2) : '—'}
                      sub={quickRatioNote(cfoRatios?.quickRatio ?? null)}
                      tone={cfoRatios?.quickRatio != null && cfoRatios.quickRatio < 1.0 ? 'danger' : 'blue'}
                    />
                  </div>
                  {(() => {
                    const hasData = cfoKpis && (cfoKpis.cashInHand != null || cfoKpis.bankBalance != null)
                    const cash = cfoKpis?.cashInHand ?? 0
                    const bank = cfoKpis?.bankBalance ?? 0
                    const maxAbs = Math.max(Math.abs(cash), Math.abs(bank), 1)
                    const rows = [
                      { label: 'Cash In Hand', value: cash, color: 'bg-emerald-600' },
                      { label: 'Bank Balance', value: bank, color: bank < 0 ? 'bg-red-500' : 'bg-emerald-600' },
                    ]
                    return (
                      <div className="bg-muted border border-border rounded-xl p-4">
                        <p className="text-[11px] font-bold text-muted-foreground uppercase tracking-wider mb-3">Bank &amp; Cash Liquidity Comparison</p>
                        {hasData ? (
                          <div className="space-y-3">
                            {rows.map((row, i) => (
                              <div key={i} className="flex items-center gap-3">
                                <span className="w-24 shrink-0 text-xs text-muted-foreground">{row.label}</span>
                                <div className="flex-1 flex items-center gap-2">
                                  <div className="flex-1 max-w-md">
                                    <div className={`h-6 rounded ${row.color}`} style={{ width: `${Math.max((Math.abs(row.value) / maxAbs) * 100, 3)}%` }} />
                                  </div>
                                  <span className="text-xs font-semibold text-foreground whitespace-nowrap">
                                    {formatCompactLakhs(row.value)}{row.value < 0 ? ' (OD)' : ''}
                                  </span>
                                </div>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <p className="text-xs text-muted-foreground italic">No data available.</p>
                        )}
                      </div>
                    )
                  })()}
                </div>

                {/* Working Capital & Efficiency Ratios */}
                <div>
                  <ReportSectionHeading n={3} title="Working Capital & Efficiency Ratios" />
                  <div className="border border-border rounded-xl overflow-hidden">
                    <table className="w-full text-xs">
                      <thead>
                        <tr className="bg-brand-600">
                          <th className="py-2.5 px-3 text-left font-semibold text-white">Efficiency Parameter</th>
                          <th className="py-2.5 px-3 text-center font-semibold text-white w-24">Value (Days / %)</th>
                          <th className="py-2.5 px-3 text-left font-semibold text-white">Strategic Assessment</th>
                        </tr>
                      </thead>
                      <tbody>
                        {([
                          { label: 'Days Sales Outstanding (DSO)',    value: cfoRatios?.dso  ?? null, suffix: ' Days', assess: dsoAssessment(cfoRatios?.dso ?? null),   badge: null as string | null },
                          { label: 'Days Inventory Outstanding (DIO)', value: cfoRatios?.dio  ?? null, suffix: ' Days', assess: dioAssessment(cfoRatios?.dio ?? null),   badge: null },
                          { label: 'Days Payables Outstanding (DPO)',  value: cfoRatios?.dpo  ?? null, suffix: ' Days', assess: dpoAssessment(cfoRatios?.dpo ?? null),   badge: null },
                          { label: 'Cash Conversion Cycle (CCC)',      value: cfoRatios?.ccc  ?? null, suffix: ' Days', assess: cccAssessment(cfoRatios?.ccc ?? null),
                            badge: cfoRatios?.ccc != null && cfoRatios.ccc <= 0 ? 'NEGATIVE' : null },
                          { label: 'Return on Capital Employed (ROCE)', value: cfoRatios?.roce ?? null, suffix: '%',     assess: roceAssessment(cfoRatios?.roce ?? null), badge: null },
                          { label: 'Return on Equity (ROE)',           value: cfoRatios?.roe  ?? null, suffix: '%',     assess: roeAssessment(cfoRatios?.roe ?? null),   badge: null },
                        ]).map((row, i) => (
                          <tr key={i} className={i % 2 === 1 ? 'bg-slate-50' : 'bg-card'}>
                            <td className="py-2.5 px-3 text-foreground font-semibold align-top">{row.label}</td>
                            <td className="py-2.5 px-3 text-center text-brand-700 font-bold whitespace-nowrap align-top">
                              {row.value != null ? `${row.value.toFixed(1)}${row.suffix}` : '—'}
                            </td>
                            <td className="py-2.5 px-3 text-muted-foreground leading-relaxed align-top">
                              {row.badge && (
                                <span className="inline-block mr-1.5 text-[10px] font-bold px-1.5 py-0.5 rounded bg-emerald-100 text-emerald-700 align-middle">{row.badge}</span>
                              )}
                              {row.assess}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                {/* Strategic Actions for Management */}
                <div>
                  <ReportSectionHeading n={4} title="Strategic Actions for Management" />
                  <div className="bg-card border border-border rounded-xl p-4">
                    <ul className="space-y-3">
                      {cfoReport.keyActionItems.map((item, i) => (
                        <li key={i} className="flex gap-2 text-sm text-foreground leading-relaxed">
                          <span className="text-brand-600 shrink-0">•</span>
                          <span>{renderActionItem(item)}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

      </div>
    </div>
  )
}
