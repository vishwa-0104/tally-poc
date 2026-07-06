import { useState, useCallback, useEffect, useRef } from 'react'
import { toast } from 'react-hot-toast'
import {
  XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, BarChart, Bar, Cell,
} from 'recharts'
import {
  TrendingUp, TrendingDown, AlertCircle,
  Lightbulb, AlertTriangle, CheckCircle,
  ArrowUpRight, ArrowDownRight, RefreshCw, Settings, Wallet, Building2,
  Users, Store, Download, Zap,
} from 'lucide-react'
import { useAuthStore, useCompanyStore, useDaybookSyncStore } from '@/store'
import { fetchDaybook, fetchSlowMovingStock, fetchLedgerBalances, fetchGroupBalances, fetchStockValue, fetchLedgerAmounts, type SlowStockItem, type TallyVoucher, type TopItem, type SalesPartyRow } from '@/services/tallyService'
import {
  fetchSalesTargets, fetchDashboardSettings,
  fetchCachedVouchers, saveVouchers, fetchDashboardSnapshot, saveDashboardSnapshot,
  type DashboardSnapshotPatch,
} from '@/lib/api'
import type { DashboardSettings } from '@/types'
import { getTallyUrl } from './CompanySettings'
import { formatCurrency } from '@/lib/utils'
import { useExtensionStatus } from '@/hooks/useExtension'
import { SalesTargetModal } from '@/components/company/SalesTargetModal'
import { classifyVouchers, computeCreditSalesTotal } from '@/lib/voucherClassification'

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


// ── Target helpers ────────────────────────────────────────────────────────────

function getCurrentFyYear() {
  const today = new Date()
  return today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1
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

// ── Static data for Analysis + CFO tabs ───────────────────────────────────────

const dummySalesByCategory = [
  { name: 'Electronics', value: 4200 },
  { name: 'FMCG',        value: 3100 },
  { name: 'Apparel',     value: 2200 },
  { name: 'Pharma',      value: 1800 },
  { name: 'Others',      value: 900  },
]

const cfoSuggestions = [
  {
    type: 'warning' as const,
    title: 'Receivables Aging Risk',
    body: 'Outstanding receivables above 60 days have increased by 18% this quarter. Consider initiating collection calls for your top 5 overdue accounts.',
    impact: 'High',
  },
  {
    type: 'alert' as const,
    title: 'Inventory Overstocking Detected',
    body: '47 stock items have not moved in 30+ days, tying up an estimated ₹3.2L in working capital. Review slow-moving SKUs for discounting or returns.',
    impact: 'Medium',
  },
  {
    type: 'success' as const,
    title: 'Gross Margin Improving',
    body: 'Gross profit margin improved from 28% to 31% compared to last quarter, driven by reduced procurement costs in Electronics and FMCG categories.',
    impact: 'Positive',
  },
  {
    type: 'warning' as const,
    title: 'Operating Expense Overrun',
    body: 'Total operating expenses are 8% above monthly budget. Utility and logistics costs are the primary drivers — review vendor contracts.',
    impact: 'Medium',
  },
]

// ── Sub-components ────────────────────────────────────────────────────────────

function KpiCard({ title, value, subtitle, icon: Icon, trend, placeholder = false, targetInfo, prevValue }: {
  title: string
  value: string | number
  subtitle: string
  icon: React.ElementType
  trend?: { value: number }
  placeholder?: boolean
  targetInfo?: { target: number; achieved: number } | null
  prevValue?: { amount: number; current: number } | null
}) {
  const DisplayIcon = targetInfo
    ? targetInfo.achieved >= 100 ? CheckCircle
    : targetInfo.achieved >= 75  ? TrendingUp
    : targetInfo.achieved >= 50  ? AlertTriangle
    : TrendingDown
    : Icon
  const iconBg = targetInfo
    ? targetInfo.achieved >= 100 ? 'bg-green-50'
    : targetInfo.achieved >= 75  ? 'bg-amber-50'
    : targetInfo.achieved >= 50  ? 'bg-orange-50'
    : 'bg-red-50'
    : 'bg-blue-50'
  const iconColor = targetInfo
    ? targetInfo.achieved >= 100 ? 'text-green-600'
    : targetInfo.achieved >= 75  ? 'text-amber-500'
    : targetInfo.achieved >= 50  ? 'text-orange-500'
    : 'text-red-500'
    : 'text-blue-600'

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-3">
        <div className={`p-2 ${iconBg} rounded-lg`}>
          <DisplayIcon className={`w-4 h-4 ${iconColor}`} />
        </div>
        {trend !== undefined && (
          <span className={`text-xs font-semibold flex items-center gap-0.5 ${trend.value >= 0 ? 'text-green-600' : 'text-red-500'}`}>
            {trend.value >= 0
              ? <ArrowUpRight className="w-3 h-3" />
              : <ArrowDownRight className="w-3 h-3" />}
            {Math.abs(trend.value)}%
          </span>
        )}
      </div>
      <p className={`text-lg font-bold tracking-tight mb-0.5 ${placeholder ? 'text-gray-300' : 'text-gray-900'}`}>
        {placeholder ? '—' : value}
      </p>
      <p className="text-[11px] font-semibold text-gray-600">{title}</p>
      <p className="text-[10px] text-gray-400 mt-0.5 leading-tight">{subtitle}</p>
      {targetInfo && (
        <div className="mt-2 pt-2 border-t border-gray-100 space-y-0.5">
          <div className="flex justify-between text-[11px]">
            <span className="text-gray-500">Target Achievement</span>
            <span className={`font-semibold ${targetInfo.achieved >= 100 ? 'text-green-600' : 'text-red-500'}`}>
              {targetInfo.achieved.toFixed(1)}%
            </span>
          </div>
          <div className="flex justify-between text-[11px]">
            <span className="text-gray-500">Target</span>
            <span className="text-gray-600">{formatCurrency(targetInfo.target)}</span>
          </div>
          <div className="w-full bg-gray-100 rounded-full h-1 mt-1">
            <div
              className={`h-1 rounded-full transition-all ${targetInfo.achieved >= 100 ? 'bg-green-500' : 'bg-red-400'}`}
              style={{ width: `${Math.min(100, targetInfo.achieved)}%` }}
            />
          </div>
        </div>
      )}
      {prevValue != null && (
        <div className="mt-2 pt-2 border-t border-gray-100 flex items-center justify-between">
          <span className="text-[11px] text-gray-400">Previous day</span>
          <div className="flex items-center gap-1">
            {prevValue.current >= prevValue.amount
              ? <ArrowUpRight className="w-3 h-3 text-green-500" />
              : <ArrowDownRight className="w-3 h-3 text-red-400" />}
            <span className="text-[11px] text-gray-600 font-medium">{formatCurrency(prevValue.amount)}</span>
          </div>
        </div>
      )}
    </div>
  )
}

function BarTip({ active, payload, label }: { active?: boolean; payload?: { value: number; name: string }[]; label?: string }) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white border border-gray-200 rounded-lg shadow px-3 py-2 text-xs space-y-0.5">
      <p className="font-semibold text-gray-600 mb-1">{label}</p>
      {payload.map((p, i) => (
        <p key={i} className="text-gray-700">{p.name}: {formatCurrency(p.value)}</p>
      ))}
    </div>
  )
}

function CashCard({ inflow, outflow, inHand }: {
  inflow:  number | null
  outflow: number | null
  inHand:  number | null
}) {
  const val = (v: number | null) => v !== null ? formatCurrency(v) : '—'
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-2">
        <div className="p-1.5 bg-emerald-50 rounded-lg">
          <Wallet className="w-3.5 h-3.5 text-emerald-600" />
        </div>
      </div>
      <p className="text-sm font-bold text-gray-900 mb-2">Cash</p>
      <div className="space-y-1.5">
        <div className="flex items-center gap-2">
          <span className="text-[11px] text-gray-500 flex-1">Cash Inflow</span>
          <span className="text-[11px] font-semibold text-emerald-600 shrink-0 whitespace-nowrap">{val(inflow)}</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-[11px] text-gray-500 flex-1">Cash Outflow</span>
          <span className="text-[11px] font-semibold text-red-500 shrink-0 whitespace-nowrap">{val(outflow)}</span>
        </div>
        <div className="flex items-center gap-2 border-t border-gray-100 pt-1.5">
          <span className="text-[11px] text-gray-500 flex-1">Cash In Hand</span>
          <span className="text-[11px] font-semibold text-gray-800 shrink-0 whitespace-nowrap">{val(inHand)}</span>
        </div>
      </div>
    </div>
  )
}

function BankCard({ inflow, outflow, balance }: {
  inflow:   number | null
  outflow:  number | null
  balance:  number | null
}) {
  const val = (v: number | null) => v !== null ? formatCurrency(v) : '—'
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-2">
        <div className="p-1.5 bg-blue-50 rounded-lg">
          <Building2 className="w-3.5 h-3.5 text-blue-600" />
        </div>
      </div>
      <p className="text-sm font-bold text-gray-900 mb-2">Banks</p>
      <div className="space-y-1.5">
        <div className="flex items-center gap-2">
          <span className="text-[11px] text-gray-500 flex-1">Bank Inflow</span>
          <span className="text-[11px] font-semibold text-emerald-600 shrink-0 whitespace-nowrap">{val(inflow)}</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-[11px] text-gray-500 flex-1">Bank Outflow</span>
          <span className="text-[11px] font-semibold text-red-500 shrink-0 whitespace-nowrap">{val(outflow)}</span>
        </div>
        <div className="flex items-center gap-2 border-t border-gray-100 pt-1.5">
          <span className="text-[11px] text-gray-500 flex-1">Balance in Bank</span>
          <span className="text-[11px] font-semibold text-gray-800 shrink-0 whitespace-nowrap">{val(balance)}</span>
        </div>
      </div>
    </div>
  )
}

function ReceivablesCard({ balance }: { balance: number | null }) {
  const val = (v: number | null) => v !== null ? formatCurrency(v) : '—'
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-2">
        <div className="p-1.5 bg-violet-50 rounded-lg">
          <Users className="w-3.5 h-3.5 text-violet-600" />
        </div>
      </div>
      <p className={`text-lg font-bold tracking-tight mb-0.5 ${balance === null ? 'text-gray-300' : 'text-gray-900'}`}>
        {val(balance)}
      </p>
      <p className="text-[11px] font-semibold text-gray-600">Receivables</p>
      <p className="text-[10px] text-gray-400 mt-0.5 leading-tight">Sundry Debtors</p>
    </div>
  )
}

function PayablesCard({ balance }: { balance: number | null }) {
  const val = (v: number | null) => v !== null ? formatCurrency(v) : '—'
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-2">
        <div className="p-1.5 bg-orange-50 rounded-lg">
          <Store className="w-3.5 h-3.5 text-orange-600" />
        </div>
      </div>
      <p className={`text-lg font-bold tracking-tight mb-0.5 ${balance === null ? 'text-gray-300' : 'text-gray-900'}`}>
        {val(balance)}
      </p>
      <p className="text-[11px] font-semibold text-gray-600">Payables</p>
      <p className="text-[10px] text-gray-400 mt-0.5 leading-tight">Sundry Creditors</p>
    </div>
  )
}

// Analysis tab's 9 ratio KPI cards. Reuses KpiCard's exact visual language.
// noData renders only the heading + "No data available" — never a fabricated
// number — for whichever inputs genuinely aren't fetchable for this company.
function RatioKpiCard({ title, value, subtitle, icon: Icon, suffix = '' }: {
  title:    string
  value:    number | null
  subtitle: string
  icon:     React.ElementType
  suffix?:  string
}) {
  const noData = value == null
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-3">
        <div className="p-2 bg-blue-50 rounded-lg">
          <Icon className="w-4 h-4 text-blue-600" />
        </div>
      </div>
      {noData ? (
        <p className="text-xs font-semibold text-gray-400 italic mb-0.5">No data available</p>
      ) : (
        <p className="text-lg font-bold tracking-tight mb-0.5 text-gray-900">
          {value.toLocaleString('en-IN', { maximumFractionDigits: 1 })}{suffix}
        </p>
      )}
      <p className="text-[11px] font-semibold text-gray-600">{title}</p>
      <p className="text-[10px] text-gray-400 mt-0.5 leading-tight">{subtitle}</p>
    </div>
  )
}

function GrossMarginCard({ value, pct, targetPct }: {
  value:     number | null
  pct:       number | null
  targetPct: number | null
}) {
  const achieved = (pct !== null && targetPct) ? (pct / targetPct) * 100 : null
  const iconBg    = achieved === null ? 'bg-blue-50'
    : achieved >= 100 ? 'bg-green-50' : achieved >= 75 ? 'bg-amber-50' : 'bg-red-50'
  const iconColor = achieved === null ? 'text-blue-600'
    : achieved >= 100 ? 'text-green-600' : achieved >= 75 ? 'text-amber-500' : 'text-red-500'
  const Icon = achieved === null ? TrendingUp
    : achieved >= 100 ? CheckCircle : achieved >= 75 ? TrendingUp : TrendingDown

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-3">
        <div className={`p-2 ${iconBg} rounded-lg`}>
          <Icon className={`w-4 h-4 ${iconColor}`} />
        </div>
      </div>
      <p className={`text-lg font-bold tracking-tight mb-0.5 ${value === null ? 'text-gray-300' : 'text-gray-900'}`}>
        {value !== null ? formatCurrency(value) : '—'}
      </p>
      <p className="text-[11px] font-semibold text-gray-600">Gross Margin</p>
      <p className="text-[10px] text-gray-400 mt-0.5 leading-tight">Sales − Purchases (excl. GST)</p>
      {pct !== null && (
        <div className="mt-2 pt-2 border-t border-gray-100 space-y-0.5">
          <div className="flex justify-between text-[11px]">
            <span className="text-gray-500">Margin %</span>
            <span className="font-semibold text-gray-700">{pct.toFixed(1)}%</span>
          </div>
          {achieved !== null && (
            <>
              <div className="flex justify-between text-[11px]">
                <span className="text-gray-500">Target</span>
                <span className="text-gray-600">{targetPct!.toFixed(1)}%</span>
              </div>
              <div className="flex justify-between text-[11px]">
                <span className="text-gray-500">Target Achievement</span>
                <span className={`font-semibold ${achieved >= 100 ? 'text-green-600' : 'text-red-500'}`}>
                  {achieved.toFixed(1)}%
                </span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-1 mt-1">
                <div
                  className={`h-1 rounded-full transition-all ${achieved >= 100 ? 'bg-green-500' : 'bg-red-400'}`}
                  style={{ width: `${Math.min(100, achieved)}%` }}
                />
              </div>
            </>
          )}
        </div>
      )}
    </div>
  )
}

function NetProfitCard({ value, pct }: { value: number | null; pct: number | null }) {
  const color = value === null ? 'text-gray-300' : value >= 0 ? 'text-gray-900' : 'text-red-600'
  const Icon  = value === null || value >= 0 ? TrendingUp : TrendingDown
  const iconBg    = value === null ? 'bg-purple-50' : value >= 0 ? 'bg-green-50' : 'bg-red-50'
  const iconColor = value === null ? 'text-purple-500' : value >= 0 ? 'text-green-600' : 'text-red-500'
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-3">
        <div className={`p-2 ${iconBg} rounded-lg`}>
          <Icon className={`w-4 h-4 ${iconColor}`} />
        </div>
      </div>
      <p className={`text-lg font-bold tracking-tight mb-0.5 ${color}`}>
        {value !== null ? formatCurrency(value) : '—'}
      </p>
      <p className="text-[11px] font-semibold text-gray-600">Net Profit</p>
      <p className="text-[10px] text-gray-400 mt-0.5 leading-tight">Gross Margin − Indirect Exp + Indirect Inc</p>
      {pct !== null && (
        <div className="mt-2 pt-2 border-t border-gray-100">
          <div className="flex justify-between text-[11px]">
            <span className="text-gray-500">Net Margin %</span>
            <span className={`font-semibold ${pct >= 0 ? 'text-gray-700' : 'text-red-500'}`}>{pct.toFixed(1)}%</span>
          </div>
        </div>
      )}
    </div>
  )
}

function EbitdaCard({ value, pct }: { value: number | null; pct: number | null }) {
  const color     = value === null ? 'text-gray-300' : value >= 0 ? 'text-gray-900' : 'text-red-600'
  const Icon      = value === null || value >= 0 ? TrendingUp : TrendingDown
  const iconBg    = value === null ? 'bg-indigo-50' : value >= 0 ? 'bg-indigo-50' : 'bg-red-50'
  const iconColor = value === null ? 'text-indigo-400' : value >= 0 ? 'text-indigo-600' : 'text-red-500'
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-start justify-between mb-3">
        <div className={`p-2 ${iconBg} rounded-lg`}>
          <Icon className={`w-4 h-4 ${iconColor}`} />
        </div>
      </div>
      <p className={`text-lg font-bold tracking-tight mb-0.5 ${color}`}>
        {value !== null ? formatCurrency(value) : '—'}
      </p>
      <p className="text-[11px] font-semibold text-gray-600">EBITDA</p>
      <p className="text-[10px] text-gray-400 mt-0.5 leading-tight">Earnings before interest, tax, depreciation</p>
      {pct !== null && (
        <div className="mt-2 pt-2 border-t border-gray-100">
          <div className="flex justify-between text-[11px]">
            <span className="text-gray-500">EBITDA Margin %</span>
            <span className={`font-semibold ${pct >= 0 ? 'text-gray-700' : 'text-red-500'}`}>{pct.toFixed(1)}%</span>
          </div>
        </div>
      )}
    </div>
  )
}

function DataTableCard({
  title,
  columns,
  rows,
  loading = false,
}: {
  title:   string
  columns: { label: string; right?: boolean }[]
  rows?:   { cells: (string | React.ReactNode)[]; dim?: boolean }[]
  loading?: boolean
}) {
  const showSkeleton = loading || !rows || rows.length === 0
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <p className="text-xs font-bold text-gray-700 mb-3">{title}</p>
      <table className="w-full text-xs">
        <thead>
          <tr className="border-b border-gray-100">
            {columns.map((col, i) => (
              <th key={i} className={`pb-2 px-2 text-[11px] font-semibold text-gray-400 ${col.right ? 'text-right' : 'text-left'}`}>
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {showSkeleton
            ? Array.from({ length: 6 }).map((_, ri) => (
                <tr key={ri}>
                  {columns.map((_, ci) => (
                    <td key={ci} className="py-2.5 px-2">
                      <div className={`h-2 bg-gray-100 rounded-full animate-pulse ${ci === 0 ? 'w-4/5' : 'w-1/2'}`} />
                    </td>
                  ))}
                </tr>
              ))
            : rows!.map((row, ri) => (
                <tr key={ri} className="border-b border-gray-50 last:border-0 hover:bg-gray-50">
                  {row.cells.map((cell, ci) => (
                    <td key={ci} className={`py-1.5 px-2 ${row.dim ? 'text-gray-400' : 'text-gray-700'} ${columns[ci]?.right ? 'text-right font-medium' : ''}`}>
                      {cell}
                    </td>
                  ))}
                </tr>
              ))}
        </tbody>
      </table>
    </div>
  )
}

// ── Main component ────────────────────────────────────────────────────────────

const TABS: { key: Tab; label: string }[] = [
  { key: 'performance', label: 'Performance'     },
  { key: 'analysis',    label: 'Analysis'        },
  { key: 'cfo',         label: 'CFO Suggestions' },
]

const FILTERS: { key: FilterPreset; label: string }[] = [
  { key: 'today',   label: 'Today'        },
  { key: 'quarter', label: 'This Quarter' },
  { key: 'ytd',     label: 'YTD'          },
  { key: 'custom',  label: 'Custom'       },
]

// Analysis tab's own filter — independent of the Performance tab's FILTERS/
// filterPreset state above, so switching one never affects the other.
const ANALYSIS_FILTERS: { key: FilterPreset; label: string }[] = [
  { key: 'today',  label: 'Today'  },
  { key: 'ytd',    label: 'YTD'    },
  { key: 'custom', label: 'Custom' },
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
  purchases:                   number | null
  directExpenses:              number | null
  cash:                        number | null
  bank:                        number | null
  investments:                 number | null
  currentLiabilities:          number | null
  bankOD:                      number | null
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
  purchases: null, directExpenses: null, cash: null, bank: null, investments: null,
  currentLiabilities: null, bankOD: null, longTermBorrowings: null, roceEquity: null,
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
// skews a different card.
function computeRatios(i: AnalysisInputs): RatioResults {
  const dso = i.debtors != null && i.creditSales
    ? (i.debtors / i.creditSales) * 365 : null

  const cogs = i.openingStock != null && i.purchases != null && i.directExpenses != null && i.closingStock != null
    ? i.openingStock + i.purchases + i.directExpenses - i.closingStock : null
  const dio = i.closingStock != null && cogs
    ? (i.closingStock / cogs) * 365 : null

  const dpo = i.creditors != null && i.purchases
    ? (i.creditors / i.purchases) * 365 : null

  const ccc = dso != null && dio != null && dpo != null ? dso + dio - dpo : null

  const currentRatio = i.closingStock != null && i.debtors != null && i.creditors
    ? (i.closingStock + i.debtors) / i.creditors : null

  // Trade Receivables uses Closing Sundry Debtors (same input as DSO) —
  // the bill-wise 90-day ageing fetch was never verified against live Tally
  // and has been dropped in favor of this already-proven figure.
  const quickNumerator = i.cash != null && i.bank != null && i.investments != null && i.debtors != null
    ? i.cash + i.bank + i.investments + i.debtors : null
  const quickDenominator = i.currentLiabilities != null && i.bankOD != null
    ? i.currentLiabilities - i.bankOD : null
  const quickRatio = quickNumerator != null && quickDenominator
    ? quickNumerator / quickDenominator : null

  // Tax Payment, Long Term Borrowings, and Non-Operating Investment default
  // to 0 when their ledger-list setting is left empty — per the user, these
  // three are legitimately zero for companies with no such activity, unlike
  // Equity/Net Profit/Interest Expense/Non-Operating Income below, which stay
  // strictly null-gated ("No data available") since a real company is never
  // actually zero on those, and silently defaulting them to 0 would badly
  // distort ROCE rather than just omitting it.
  const ebit = i.netProfit != null && i.interestExpense != null
    ? i.netProfit - i.interestExpense - (i.taxPayment ?? 0) : null
  const roceNumerator = ebit != null && i.nonOperatingIncome != null ? ebit - i.nonOperatingIncome : null
  const roceDenominator = i.roceEquity != null
    ? i.roceEquity + (i.longTermBorrowings ?? 0) - (i.nonOperatingInvestment ?? 0) : null
  const roce = roceNumerator != null && roceDenominator ? (roceNumerator / roceDenominator) * 100 : null

  // ROE numerator reuses the existing Net Profit (YTD) figure — no separate
  // setting. Internal Borrowings/Intangible Assets default to 0 when
  // unconfigured (commonly genuinely zero); Equity stays required.
  const roeDenominator = i.roeEquity != null
    ? i.roeEquity + (i.internalBorrowings ?? 0) - (i.intangibleAssets ?? 0) : null
  const roe = i.netProfit != null && roeDenominator ? i.netProfit / roeDenominator : null

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
  const debtEquity = debtEquityNumerator != null && debtEquityDenominator
    ? debtEquityNumerator / debtEquityDenominator : null

  return { dso, dio, dpo, ccc, currentRatio, quickRatio, roce, roe, debtEquity }
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

  const [activeTab,       setActiveTab]       = useState<Tab>('performance')
  const [filterPreset,    setFilterPreset]    = useState<FilterPreset>('today')
  const [customFrom,      setCustomFrom]      = useState(todayStr())
  const [customTo,        setCustomTo]        = useState(todayStr())
  const [showTargetModal, setShowTargetModal] = useState(false)
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
  const [slowStock,         setSlowStock]         = useState<SlowStockItem[]>([])
  const [purchaseVouchers,  setPurchaseVouchers]  = useState<(TallyVoucher & { role: 'Included' | 'Excluded' })[]>([])
  const [loading,       setLoading]       = useState(false)
  const [fetched,       setFetched]       = useState(false)
  const [error,         setError]         = useState<string | null>(null)
  const [activePeriod,  setActivePeriod]  = useState<{ from: string; to: string } | null>(null)
  const [uncachedRange, setUncachedRange] = useState(false) // true when the DB has never seen this range — hints "click Apply"

  // ── Analysis tab — fully independent filter/state from the Performance tab above ──
  const [analysisFilterPreset, setAnalysisFilterPreset] = useState<FilterPreset>('ytd')
  const [analysisCustomFrom,   setAnalysisCustomFrom]   = useState(todayStr())
  const [analysisCustomTo,     setAnalysisCustomTo]     = useState(todayStr())
  const [analysisLoading,      setAnalysisLoading]      = useState(false)
  const [analysisFetched,      setAnalysisFetched]      = useState(false)
  const [analysisUncachedRange, setAnalysisUncachedRange] = useState(false)
  const [analysisActivePeriod, setAnalysisActivePeriod] = useState<{ from: string; to: string } | null>(null)
  const [analysisInputs,       setAnalysisInputs]       = useState<AnalysisInputs>(emptyAnalysisInputs)

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
      let latestCashInHand:  number | null = null
      let latestBankBalance: number | null = null
      let latestReceivables: number | null = null
      let latestPayables:    number | null = null
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
        const directExpenses = directExpResult.status === 'fulfilled' ? (directExpResult.value ?? 0) : 0

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
        snapshotPatch.cashInHand  = latestCashInHand
        snapshotPatch.bankBalance = latestBankBalance
        snapshotPatch.receivables = latestReceivables
        snapshotPatch.payables    = latestPayables
      }
      if (preset === 'ytd' && stockResult.status === 'fulfilled' && stockResult.value) {
        snapshotPatch.openingStock       = stockResult.value.openingStock
        snapshotPatch.closingStock       = stockResult.value.closingStock
        snapshotPatch.directExpenseTotal = directExpResult.status === 'fulfilled' ? (directExpResult.value ?? 0) : 0
      }
      void saveDashboardSnapshot(companyId, snapshotPatch).catch((err: unknown) => console.error('[Dashboard] Failed to persist snapshot:', err))
    } catch (err) {
      console.error('[Dashboard] fetchData failed:', err)
      setError('no-data')
      toast.error('No data found. Please check that Tally is open and try again.')
    } finally {
      setLoading(false)
    }
  }, [connected, tallyUrl, tallyCompany, dashboardSettings])

  // Reads whatever's cached in the DB for the given range — never touches
  // Tally. Used for every tab/filter switch; Apply and the initial mount's
  // one-time backfill are the only paths that go live (see fetchData above).
  const loadFromDb = useCallback(async (preset: FilterPreset, cfrom: string, cto: string): Promise<{ fetchedDates: string[] }> => {
    if (!companyId) return { fetchedDates: [] }
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

      const purchaseTotal = preset === 'ytd' ? computePurchaseTotal(all, dashboardSettings.ytd) : 0

      setCashInflow(cashFlow.inflow)
      setCashOutflow(cashFlow.outflow)
      setBankInflow(bankFlow.inflow)
      setBankOutflow(bankFlow.outflow)

      // Top debtors — same logic as the live path in fetchData
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
      }

      // Snapshot fields — cached "current value" data, only meaningful for today/ytd-relevant views
      if (to === todayStr()) {
        setCashInHand(snapshot?.cashInHand ?? null)
        setBankBalance(snapshot?.bankBalance ?? null)
        setReceivables(snapshot?.receivables ?? null)
        setPayables(snapshot?.payables ?? null)
      } else {
        setCashInHand(null)
        setBankBalance(null)
        setReceivables(null)
        setPayables(null)
      }
      setSlowStock(snapshot?.slowStockItems ?? [])

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
      return { fetchedDates }
    } catch (err) {
      console.error('[Dashboard] loadFromDb failed:', err)
      setError('no-data')
      return { fetchedDates: [] }
    } finally {
      setLoading(false)
    }
  }, [companyId, dashboardSettings])

  // ── Analysis tab — DB-only read, mirrors loadFromDb above but for the 9
  // ratio KPIs. Never touches Tally. Balance-sheet inputs (debtors, creditors,
  // cash, bank, investments, current liabilities, bank OD, equity, total
  // loans) only apply when `to` is today — same Tally "ClosingBalance ignores
  // SVTODATE" limitation loadFromDb already works around for
  // receivables/payables/cash/bank.
  const loadAnalysisFromDb = useCallback(async (preset: FilterPreset, cfrom: string, cto: string): Promise<{ fetchedDates: string[] }> => {
    if (!companyId) return { fetchedDates: [] }
    const { from, to } = getFilterDates(preset, cfrom, cto)
    const isCurrent = to === todayStr()

    setAnalysisLoading(true)
    try {
      const [{ vouchers: all, fetchedDates }, snapshot] = await Promise.all([
        fetchCachedVouchers(companyId, from, to),
        fetchDashboardSnapshot(companyId),
      ])

      const purchaseTotal = computePurchaseTotal(all, dashboardSettings.ytd)
      // Analysis tab's own Sales definition — deliberately independent of the
      // Performance tab's `today.salesAccounts`/include/exclude settings.
      const analysisSalesFilter: SalesFilterSettings = {
        salesAccounts:        dashboardSettings.ytd?.analysisSalesAccounts,
        salesIncludeVouchers: dashboardSettings.ytd?.analysisSalesIncludeVouchers,
        salesExcludeVouchers: dashboardSettings.ytd?.analysisSalesExcludeVouchers,
      }
      const creditSales   = computeCreditSalesTotal(all, analysisSalesFilter)
      const totalSales    = computeSalesTotal(all, analysisSalesFilter)
      console.log('[Analysis][DB] Sales settings:', analysisSalesFilter)
      console.log(`[Analysis][DB] Total Sales: ${totalSales} | Credit Sales (for DSO): ${creditSales} | vouchers in range: ${all.length}`)

      let netProfit: number | null = null
      if (snapshot?.openingStock != null && snapshot?.closingStock != null && snapshot?.directExpenseTotal != null) {
        const { indExpTotal, indIncTotal } = classifyVouchers(
          all,
          {
            indirectExpenseLedgers:         dashboardSettings.ytd?.indirectExpenseLedgers,
            indirectExpenseIncludeVouchers: dashboardSettings.ytd?.indirectExpenseIncludeVouchers,
            indirectExpenseExcludeVouchers: dashboardSettings.ytd?.indirectExpenseExcludeVouchers,
            indirectIncomeLedgers:          dashboardSettings.ytd?.indirectIncomeLedgers,
            indirectIncomeIncludeVouchers:  dashboardSettings.ytd?.indirectIncomeIncludeVouchers,
            indirectIncomeExcludeVouchers:  dashboardSettings.ytd?.indirectIncomeExcludeVouchers,
          },
          from, to,
        )
        const gm = (totalSales + snapshot.closingStock) - (snapshot.openingStock + purchaseTotal + snapshot.directExpenseTotal)
        netProfit = gm - indExpTotal + indIncTotal
      }

      // DIO = Closing Stock / COGS * 365, COGS = Opening Stock + Purchases + Direct Expenses − Closing Stock
      {
        const openingStock   = snapshot?.openingStock ?? null
        const closingStock   = snapshot?.closingStock ?? null
        const directExpenses = snapshot?.directExpenseTotal ?? null
        const cogs = openingStock != null && directExpenses != null && closingStock != null
          ? openingStock + purchaseTotal + directExpenses - closingStock : null
        const dioDays = closingStock != null && cogs ? (closingStock / cogs) * 365 : null
        console.log(`[Analysis][DB] DIO — Opening Stock: ${openingStock} | Closing Stock: ${closingStock} | Purchases: ${purchaseTotal} | Direct Expenses: ${directExpenses}`)
        console.log(`[Analysis][DB] DIO — COGS: ${cogs} | DIO (days): ${dioDays}`)
      }

      // Quick Ratio = (Cash + Bank + Investments + Debtors) / (Current Liabilities − Bank OD)
      {
        const dbCash               = isCurrent ? (snapshot?.cashInHand ?? null) : null
        const dbBank               = isCurrent ? (snapshot?.bankBalance ?? null) : null
        const dbDebtors            = isCurrent ? (snapshot?.receivables ?? null) : null
        const dbInvestments        = isCurrent ? (snapshot?.investments ?? null) : null
        const dbCurrentLiabilities = isCurrent ? (snapshot?.currentLiabilities ?? null) : null
        const dbBankOD             = isCurrent ? (snapshot?.bankOD ?? null) : null
        const quickNum = dbCash != null && dbBank != null && dbInvestments != null && dbDebtors != null
          ? dbCash + dbBank + dbInvestments + dbDebtors : null
        const quickDen = dbCurrentLiabilities != null && dbBankOD != null
          ? dbCurrentLiabilities - dbBankOD : null
        const quickRatioVal = quickNum != null && quickDen ? quickNum / quickDen : null
        console.log(`[Analysis][DB] Quick Ratio — isCurrent: ${isCurrent} | snapshot: ${snapshot ? 'present' : 'null (never fetched)'}`)
        console.log(`[Analysis][DB] Quick Ratio — Cash: ${dbCash} | Bank: ${dbBank} | Investments: ${dbInvestments} | Debtors: ${dbDebtors}`)
        console.log(`[Analysis][DB] Quick Ratio — Current Liabilities: ${dbCurrentLiabilities} | Bank OD: ${dbBankOD}`)
        console.log(`[Analysis][DB] Quick Ratio — numerator: ${quickNum} | denominator: ${quickDen} | ratio: ${quickRatioVal}`)
      }

      // ROCE = (EBIT − Non-Operating Income) / (Equity + Long Term Borrowings − Non-Operating Investment) * 100
      // EBIT = Net Profit − Interest Expense − Tax Payment
      {
        const dbRoceEquity         = snapshot?.roceEquity ?? null
        const dbLongTermBorrowings = snapshot?.longTermBorrowings ?? null
        const dbInterestExpense    = snapshot?.interestExpenseTotal ?? null
        const dbTaxPayment         = snapshot?.taxPaymentTotal ?? null
        const dbNonOpIncome        = snapshot?.nonOperatingIncomeTotal ?? null
        const dbNonOpInvestment    = snapshot?.nonOperatingInvestmentTotal ?? null
        const dbEbit = netProfit != null && dbInterestExpense != null && dbTaxPayment != null
          ? netProfit - dbInterestExpense - dbTaxPayment : null
        const roceNum = dbEbit != null && dbNonOpIncome != null ? dbEbit - dbNonOpIncome : null
        const roceDen = dbRoceEquity != null && dbLongTermBorrowings != null && dbNonOpInvestment != null
          ? dbRoceEquity + dbLongTermBorrowings - dbNonOpInvestment : null
        const roceVal = roceNum != null && roceDen ? (roceNum / roceDen) * 100 : null
        console.log(`[Analysis][DB] ROCE — Net Profit: ${netProfit} | Interest Expense: ${dbInterestExpense} | Tax Payment: ${dbTaxPayment} | EBIT: ${dbEbit}`)
        console.log(`[Analysis][DB] ROCE — Non-Operating Income: ${dbNonOpIncome} | Equity: ${dbRoceEquity} | Long Term Borrowings: ${dbLongTermBorrowings} | Non-Operating Investment: ${dbNonOpInvestment}`)
        console.log(`[Analysis][DB] ROCE — numerator: ${roceNum} | denominator: ${roceDen} | ROCE (%): ${roceVal}`)
      }

      // ROE = Net Profit / (Equity + Internal Borrowings − Intangible Assets)
      {
        const dbRoeEquity          = snapshot?.roeEquity ?? null
        const dbInternalBorrowings = snapshot?.internalBorrowings ?? null
        const dbIntangibleAssets   = snapshot?.intangibleAssets ?? null
        const roeDen = dbRoeEquity != null
          ? dbRoeEquity + (dbInternalBorrowings ?? 0) - (dbIntangibleAssets ?? 0) : null
        const roeVal = netProfit != null && roeDen ? netProfit / roeDen : null
        console.log(`[Analysis][DB] ROE — Net Profit: ${netProfit} | Equity: ${dbRoeEquity} | Internal Borrowings: ${dbInternalBorrowings} | Intangible Assets: ${dbIntangibleAssets}`)
        console.log(`[Analysis][DB] ROE — denominator: ${roeDen} | ROE: ${roeVal}`)
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
        const deVal = deNum != null && deDen ? deNum / deDen : null
        console.log(`[Analysis][DB] Debt/Equity — Loans: ${dbDebtEquityLoans} | Cash: ${dbDebtEquityCash} | Bank: ${dbDebtEquityBank}`)
        console.log(`[Analysis][DB] Debt/Equity — Equity: ${dbDebtEquityEquity} | Director Loans: ${dbDirectorLoans}`)
        console.log(`[Analysis][DB] Debt/Equity — numerator: ${deNum} | denominator: ${deDen} | ratio: ${deVal}`)
      }

      setAnalysisInputs({
        debtors:               isCurrent ? (snapshot?.receivables ?? null) : null,
        creditors:             isCurrent ? (snapshot?.payables ?? null) : null,
        creditSales,
        openingStock:          snapshot?.openingStock ?? null,
        closingStock:          snapshot?.closingStock ?? null,
        purchases:             purchaseTotal,
        directExpenses:        snapshot?.directExpenseTotal ?? null,
        cash:                  isCurrent ? (snapshot?.cashInHand ?? null) : null,
        bank:                  isCurrent ? (snapshot?.bankBalance ?? null) : null,
        investments:           isCurrent ? (snapshot?.investments ?? null) : null,
        currentLiabilities:    isCurrent ? (snapshot?.currentLiabilities ?? null) : null,
        bankOD:                isCurrent ? (snapshot?.bankOD ?? null) : null,
        longTermBorrowings:     snapshot?.longTermBorrowings ?? null,
        roceEquity:             snapshot?.roceEquity ?? null,
        netProfit,
        interestExpense:        snapshot?.interestExpenseTotal ?? null,
        taxPayment:             snapshot?.taxPaymentTotal ?? null,
        nonOperatingIncome:     snapshot?.nonOperatingIncomeTotal ?? null,
        nonOperatingInvestment: snapshot?.nonOperatingInvestmentTotal ?? null,
        directorLoans:          snapshot?.directorLoansTotal ?? null,
        roeEquity:              snapshot?.roeEquity ?? null,
        internalBorrowings:     snapshot?.internalBorrowings ?? null,
        intangibleAssets:       snapshot?.intangibleAssets ?? null,
        debtEquityLoans:        snapshot?.debtEquityLoans ?? null,
        debtEquityCash:         snapshot?.debtEquityCash ?? null,
        debtEquityBank:         snapshot?.debtEquityBank ?? null,
        debtEquityEquity:       snapshot?.debtEquityEquity ?? null,
      })
      setAnalysisActivePeriod({ from, to })
      setAnalysisFetched(true)
      return { fetchedDates }
    } catch (err) {
      console.error('[Dashboard] loadAnalysisFromDb failed:', err)
      return { fetchedDates: [] }
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
    const fetchLedgerTotal = (names?: string[]): Promise<number | null> =>
      names?.length
        ? fetchLedgerAmounts(fFrom, fTo, tallyUrl, tallyCompany, names)
        : Promise.resolve(null)

    setAnalysisLoading(true)
    try {
      const [
        daybookResult, stockResult, directExpResult,
        groupBalResult, ledgerBalResult,
        interestExpenseTotal, taxPaymentTotal, nonOperatingIncomeTotal, nonOperatingInvestmentTotal, directorLoansTotal,
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
        }),
        fetchStockValue(fFrom, fTo, tallyUrl, tallyCompany),
        fetchLedgerAmounts(fFrom, fTo, tallyUrl, tallyCompany, dashboardSettings.ytd?.directExpenseLedgers),
        isCurrent ? fetchGroupBalances(tallyUrl, tallyCompany) : Promise.resolve(null),
        isCurrent ? fetchLedgerBalances(tallyUrl, tallyCompany, toTallyDate(todayStr())) : Promise.resolve(null),
        fetchLedgerTotal(dashboardSettings.ytd?.interestExpenseLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.taxPaymentLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.nonOperatingIncomeLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.nonOperatingInvestmentLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.directorLoanLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.longTermBorrowingLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.equityLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.roeEquityLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.internalBorrowingLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.intangibleAssetLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.debtEquityLoanLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.debtEquityCashLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.debtEquityBankLedgers),
        fetchLedgerTotal(dashboardSettings.ytd?.debtEquityEquityLedgers),
      ])

      const { vouchers: all, indExpTotal, indIncTotal } = daybookResult
      const purchaseTotal = computePurchaseTotal(all, dashboardSettings.ytd)
      // Analysis tab's own Sales definition — deliberately independent of the
      // Performance tab's `today.salesAccounts`/include/exclude settings.
      const analysisSalesFilter: SalesFilterSettings = {
        salesAccounts:        dashboardSettings.ytd?.analysisSalesAccounts,
        salesIncludeVouchers: dashboardSettings.ytd?.analysisSalesIncludeVouchers,
        salesExcludeVouchers: dashboardSettings.ytd?.analysisSalesExcludeVouchers,
      }
      const creditSales   = computeCreditSalesTotal(all, analysisSalesFilter)
      const totalSales    = computeSalesTotal(all, analysisSalesFilter)
      console.log('[Analysis][Live] Sales settings:', analysisSalesFilter)
      console.log(`[Analysis][Live] Total Sales: ${totalSales} | Credit Sales (for DSO): ${creditSales} | vouchers in range: ${all.length}`)

      const { openingStock, closingStock } = stockResult
      const directExpenses = directExpResult
      const gm = (totalSales + closingStock) - (openingStock + purchaseTotal + directExpenses)
      const netProfit = gm - indExpTotal + indIncTotal

      // DIO = Closing Stock / COGS * 365, COGS = Opening Stock + Purchases + Direct Expenses − Closing Stock
      {
        const cogs = openingStock + purchaseTotal + directExpenses - closingStock
        const dioDays = cogs ? (closingStock / cogs) * 365 : null
        console.log(`[Analysis][Live] DIO — Opening Stock: ${openingStock} | Closing Stock: ${closingStock} | Purchases: ${purchaseTotal} | Direct Expenses: ${directExpenses}`)
        console.log(`[Analysis][Live] DIO — COGS: ${cogs} | DIO (days): ${dioDays}`)
      }

      let cash: number | null = null
      let bank: number | null = null
      if (isCurrent && ledgerBalResult && ledgerBalResult.rawLedgers.length > 0) {
        const cashLedgers = ledgerBalResult.rawLedgers.filter(l => l.group.toLowerCase().includes('cash'))
        const bankLedgers = ledgerBalResult.rawLedgers.filter(l => l.group.toLowerCase().includes('bank'))
        cash = -cashLedgers.reduce((s, l) => s + l.balance, 0)
        bank = -bankLedgers.reduce((s, l) => s + l.balance, 0)
      }

      const debtors             = isCurrent && groupBalResult ? groupBalResult.receivables : null
      const creditors           = isCurrent && groupBalResult ? groupBalResult.payables : null
      const investments         = isCurrent && groupBalResult ? groupBalResult.investments : null
      const currentLiabilities  = isCurrent && groupBalResult ? groupBalResult.currentLiabilities : null
      const bankOD              = isCurrent && groupBalResult ? groupBalResult.bankOD : null

      // Quick Ratio = (Cash + Bank + Investments + Debtors) / (Current Liabilities − Bank OD)
      {
        const quickNum = cash != null && bank != null && investments != null && debtors != null
          ? cash + bank + investments + debtors : null
        const quickDen = currentLiabilities != null && bankOD != null
          ? currentLiabilities - bankOD : null
        const quickRatioVal = quickNum != null && quickDen ? quickNum / quickDen : null
        console.log(`[Analysis][Live] Quick Ratio — isCurrent: ${isCurrent} | groupBalResult: ${groupBalResult ? 'fetched' : 'null (fetch skipped or failed)'} | ledgerBalResult: ${ledgerBalResult ? 'fetched' : 'null (fetch skipped or failed)'}`)
        console.log(`[Analysis][Live] Quick Ratio — Cash: ${cash} | Bank: ${bank} | Investments: ${investments} | Debtors: ${debtors}`)
        console.log(`[Analysis][Live] Quick Ratio — Current Liabilities: ${currentLiabilities} | Bank OD: ${bankOD}`)
        console.log(`[Analysis][Live] Quick Ratio — numerator: ${quickNum} | denominator: ${quickDen} | ratio: ${quickRatioVal}`)
      }

      // ROCE = (EBIT − Non-Operating Income) / (Equity + Long Term Borrowings − Non-Operating Investment) * 100
      // EBIT = Net Profit − Interest Expense − Tax Payment
      {
        const ebitVal = netProfit != null && interestExpenseTotal != null && taxPaymentTotal != null
          ? netProfit - interestExpenseTotal - taxPaymentTotal : null
        const roceNum = ebitVal != null && nonOperatingIncomeTotal != null ? ebitVal - nonOperatingIncomeTotal : null
        const roceDen = roceEquityTotal != null && longTermBorrowingsTotal != null && nonOperatingInvestmentTotal != null
          ? roceEquityTotal + longTermBorrowingsTotal - nonOperatingInvestmentTotal : null
        const roceVal = roceNum != null && roceDen ? (roceNum / roceDen) * 100 : null
        console.log(`[Analysis][Live] ROCE — Net Profit: ${netProfit} | Interest Expense: ${interestExpenseTotal} | Tax Payment: ${taxPaymentTotal} | EBIT: ${ebitVal}`)
        console.log(`[Analysis][Live] ROCE — Non-Operating Income: ${nonOperatingIncomeTotal} | Equity: ${roceEquityTotal} | Long Term Borrowings: ${longTermBorrowingsTotal} | Non-Operating Investment: ${nonOperatingInvestmentTotal}`)
        console.log(`[Analysis][Live] ROCE — numerator: ${roceNum} | denominator: ${roceDen} | ROCE (%): ${roceVal}`)
      }

      // ROE = Net Profit / (Equity + Internal Borrowings − Intangible Assets)
      {
        const roeDen = roeEquityTotal != null
          ? roeEquityTotal + (internalBorrowingsTotal ?? 0) - (intangibleAssetsTotal ?? 0) : null
        const roeVal = netProfit != null && roeDen ? netProfit / roeDen : null
        console.log(`[Analysis][Live] ROE — Net Profit: ${netProfit} | Equity: ${roeEquityTotal} | Internal Borrowings: ${internalBorrowingsTotal} | Intangible Assets: ${intangibleAssetsTotal}`)
        console.log(`[Analysis][Live] ROE — denominator: ${roeDen} | ROE: ${roeVal}`)
      }

      // Debt/Equity = (Loans − Cash − Bank) / (Equity + Director Loans)
      {
        const deNum = debtEquityLoansTotal != null
          ? debtEquityLoansTotal - (debtEquityCashTotal ?? 0) - (debtEquityBankTotal ?? 0) : null
        const deDen = debtEquityEquityTotal != null
          ? debtEquityEquityTotal + (directorLoansTotal ?? 0) : null
        const deVal = deNum != null && deDen ? deNum / deDen : null
        console.log(`[Analysis][Live] Debt/Equity — Loans: ${debtEquityLoansTotal} | Cash: ${debtEquityCashTotal} | Bank: ${debtEquityBankTotal}`)
        console.log(`[Analysis][Live] Debt/Equity — Equity: ${debtEquityEquityTotal} | Director Loans: ${directorLoansTotal}`)
        console.log(`[Analysis][Live] Debt/Equity — numerator: ${deNum} | denominator: ${deDen} | ratio: ${deVal}`)
      }

      setAnalysisInputs({
        debtors, creditors, creditSales, openingStock, closingStock,
        purchases: purchaseTotal, directExpenses, cash, bank, investments,
        currentLiabilities, bankOD, longTermBorrowings: longTermBorrowingsTotal,
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
      }
      if (isCurrent) {
        snapshotPatch.receivables        = debtors
        snapshotPatch.payables           = creditors
        snapshotPatch.cashInHand         = cash
        snapshotPatch.bankBalance        = bank
        snapshotPatch.investments        = investments
        snapshotPatch.currentLiabilities = currentLiabilities
        snapshotPatch.bankOD             = bankOD
      }
      if (interestExpenseTotal        != null) snapshotPatch.interestExpenseTotal        = interestExpenseTotal
      if (taxPaymentTotal             != null) snapshotPatch.taxPaymentTotal             = taxPaymentTotal
      if (nonOperatingIncomeTotal     != null) snapshotPatch.nonOperatingIncomeTotal     = nonOperatingIncomeTotal
      if (nonOperatingInvestmentTotal != null) snapshotPatch.nonOperatingInvestmentTotal = nonOperatingInvestmentTotal
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
    fetchAnalysisData(analysisFilterPreset, analysisCustomFrom, analysisCustomTo)
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
    fetchData(filterPreset, customFrom, customTo)
  }

  const exportPurchasesToXls = () => {
    if (purchaseVouchers.length === 0) { toast.error('No purchase vouchers to export'); return }

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

    const tsv = rows.map(r => r.join('\t')).join('\n')
    const blob = new Blob(['﻿' + tsv], { type: 'application/vnd.ms-excel;charset=utf-8' })
    const url  = URL.createObjectURL(blob)
    const a    = document.createElement('a')
    const period = activePeriod ? `${activePeriod.from}_${activePeriod.to}` : 'export'
    a.href     = url
    a.download = `vouchers_${period}.xls`
    a.click()
    URL.revokeObjectURL(url)
  }

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div className="flex flex-col h-full overflow-y-auto bg-gray-50">

      {/* ── Header bar with tabs ── */}
      <div className="bg-white border-b border-gray-200 px-6 py-3 shrink-0">
        <div className="flex items-center justify-between max-w-6xl mx-auto">
          <h1 className="text-base font-bold text-gray-900">Dashboard</h1>

          {/* Tabs — centred */}
          <div className="flex items-center gap-1 bg-gray-100 rounded-lg p-1">
            {TABS.map(t => (
              <button
                key={t.key}
                onClick={() => handleTabChange(t.key)}
                className={`px-4 py-1.5 rounded-md text-xs font-semibold transition-all ${
                  activeTab === t.key
                    ? 'bg-white text-gray-900 shadow-sm'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                {t.label}
              </button>
            ))}
          </div>

          {/* Right side: connection badge + configure */}
          <div className="flex items-center gap-2">
            {!connected && (
              <span className="text-[11px] text-amber-600 bg-amber-50 border border-amber-200 rounded-full px-2.5 py-1">
                Extension not connected
              </span>
            )}
            <button
              onClick={() => setShowTargetModal(true)}
              title="Configure sales targets"
              className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-colors"
            >
              <Settings className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      <SalesTargetModal
        open={showTargetModal}
        onClose={() => {
          setShowTargetModal(false)
          reloadMeta()
        }}
        companyId={companyId}
        tallyUrl={tallyUrl}
        tallyCompany={tallyCompany}
      />

      {/* ── Page body ── */}
      <div className="px-6 py-5 max-w-6xl w-full mx-auto space-y-5">

        {/* ══════════════════ PERFORMANCE TAB ══════════════════ */}
        {activeTab === 'performance' && (
          <>
            {/* Filter bar */}
            <div className="flex items-center gap-2 flex-wrap">
              <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-lg p-1">
                {FILTERS.map(f => (
                  <button
                    key={f.key}
                    onClick={() => handleFilterChange(f.key)}
                    className={`px-3 py-1 rounded-md text-xs font-semibold transition-all ${
                      filterPreset === f.key
                        ? 'bg-blue-600 text-white'
                        : 'text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    {f.label}
                  </button>
                ))}
              </div>

              {filterPreset === 'custom' && (
                <>
                  <input
                    type="date" value={customFrom}
                    onChange={e => setCustomFrom(e.target.value)}
                    className="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white outline-none focus:border-blue-500"
                  />
                  <span className="text-gray-400 text-xs">to</span>
                  <input
                    type="date" value={customTo}
                    onChange={e => setCustomTo(e.target.value)}
                    className="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white outline-none focus:border-blue-500"
                  />
                  <button
                    onClick={handleApply}
                    disabled={loading}
                    className="px-3 py-1.5 bg-blue-600 text-white text-xs font-semibold rounded-lg hover:bg-blue-700 disabled:opacity-50"
                  >
                    Apply
                  </button>
                </>
              )}

              <button
                onClick={handleFetchLive}
                disabled={loading}
                title="Fetch the latest data from Tally and save it to the database"
                className="flex items-center gap-1 px-3 py-1.5 bg-amber-500 text-white text-xs font-semibold rounded-lg hover:bg-amber-600 disabled:opacity-50"
              >
                <Zap className="w-3 h-3" />
                Fetch Live
              </button>

              {fetched && purchaseVouchers.length > 0 && (
                <button
                  onClick={exportPurchasesToXls}
                  title={`Export ${purchaseVouchers.length} vouchers to XLS`}
                  className="flex items-center gap-1 px-3 py-1.5 bg-green-600 text-white text-xs font-semibold rounded-lg hover:bg-green-700"
                >
                  <Download className="w-3 h-3" />
                  Export ({purchaseVouchers.length})
                </button>
              )}

              {loading && <RefreshCw className="w-3.5 h-3.5 text-blue-500 animate-spin" />}
            </div>

            {/* KPI cards — row 1: Sales, Cash, Banks (+ Receivables, Payables for Today only) */}
            <div className={`grid gap-4 ${filterPreset === 'today' ? 'grid-cols-5' : filterPreset === 'ytd' ? 'grid-cols-4' : 'grid-cols-3'}`}>
              {(() => {
                const periodTarget = fetched
                  ? computeTargetForPeriod(filterPreset, customFrom, customTo, monthlyTargets)
                  : null
                const targetInfo = (periodTarget && total > 0)
                  ? { target: periodTarget, achieved: (total / periodTarget) * 100 }
                  : null
                return (
                  <KpiCard
                    title="Total Sales"
                    value={fetched ? formatCurrency(total) : '—'}
                    subtitle={
                      activePeriod
                        ? activePeriod.from === activePeriod.to
                          ? new Date(activePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
                          : `${new Date(activePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })} – ${new Date(activePeriod.to).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`
                        : 'Loading…'
                    }
                    icon={TrendingUp}
                    targetInfo={targetInfo}
                    prevValue={filterPreset === 'today' && fetched && prevDaySales !== null
                      ? { amount: prevDaySales, current: total }
                      : null}
                  />
                )
              })()}
              {filterPreset === 'ytd' && (
                <GrossMarginCard
                  value={fetched ? grossMargin : null}
                  pct={fetched ? grossMarginPct : null}
                  targetPct={dashboardSettings.ytd?.grossMarginTarget ?? null}
                />
              )}
              {filterPreset === 'ytd' && (
                <EbitdaCard
                  value={fetched ? ebitda : null}
                  pct={fetched ? ebitdaPct : null}
                />
              )}
              {filterPreset === 'ytd' && (
                <NetProfitCard
                  value={fetched ? netProfit : null}
                  pct={fetched ? netProfitPct : null}
                />
              )}
              <CashCard
                inflow={fetched ? cashInflow : null}
                outflow={fetched ? cashOutflow : null}
                inHand={fetched ? cashInHand : null}
              />
              <BankCard
                inflow={fetched ? bankInflow : null}
                outflow={fetched ? bankOutflow : null}
                balance={fetched ? bankBalance : null}
              />
              {filterPreset === 'today' && (
                <>
                  <ReceivablesCard balance={fetched ? receivables : null} />
                  <PayablesCard    balance={fetched ? payables    : null} />
                </>
              )}
            </div>

            {/* Table panels — Top Performing Items | Top Performing Debtors | Slow Moving Stocks */}
            <div className="grid grid-cols-3 gap-4">
              <DataTableCard
                title="Top Performing Items"
                columns={[
                  { label: 'Description' },
                  { label: 'Qty',     right: true },
                  { label: 'Amt (₹)', right: true },
                ]}
                loading={!fetched}
                rows={fetched && topItems.length > 0
                  ? topItems.map(item => ({
                      cells: [
                        item.name,
                        `${item.qty % 1 === 0 ? item.qty : item.qty.toFixed(2)}${item.unit ? ' ' + item.unit : ''}`,
                        formatCurrency(item.amount),
                      ],
                    }))
                  : fetched
                    ? [{ cells: ['No items found', '', ''], dim: true }]
                    : undefined}
              />
              <DataTableCard
                title="Top Performing Debtors"
                columns={[
                  { label: 'Party' },
                  { label: 'Amt (₹)', right: true },
                ]}
                loading={!fetched}
                rows={fetched && topDebtors.length > 0
                  ? topDebtors.slice(0, 8).map((d, i) => ({
                      cells: [
                        `${i + 1}. ${d.name}`,
                        formatCurrency(d.amount),
                      ],
                    }))
                  : fetched
                    ? [{ cells: ['No debtors found', ''], dim: true }]
                    : undefined}
              />
              <DataTableCard
                title="Slow Moving Stocks"
                columns={[
                  { label: 'Stocks' },
                  { label: 'Days', right: true },
                ]}
                loading={!fetched}
                rows={fetched && slowStock.length > 0
                  ? slowStock.slice(0, 8).map(item => ({
                      cells: [
                        item.name,
                        <span className={item.daysSince >= 90 ? 'text-red-500' : item.daysSince >= 30 ? 'text-amber-500' : 'text-gray-500'}>
                          {item.daysSince}d
                        </span>,
                      ],
                    }))
                  : fetched
                    ? [{ cells: ['No slow-moving items found', ''], dim: true }]
                    : undefined}
              />
            </div>

            {/* Error */}
            {error && (
              <div className="flex items-center gap-3 bg-red-50 border border-red-200 rounded-xl px-4 py-3">
                <AlertCircle className="w-4 h-4 text-red-500 shrink-0" />
                <p className="text-xs text-red-600">No data available. Please ensure Tally is open and click Refresh.</p>
              </div>
            )}

            {/* Uncached range hint — DB has never seen this range; distinct from "genuinely zero vouchers" */}
            {!error && !loading && fetched && uncachedRange && (
              <div className="flex items-center gap-3 bg-amber-50 border border-amber-200 rounded-xl px-4 py-3">
                <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0" />
                <p className="text-xs text-amber-700">No cached data for this range yet — click Fetch Live to pull it from Tally.</p>
              </div>
            )}

          </>
        )}

        {/* ══════════════════ ANALYSIS TAB ══════════════════ */}
        {activeTab === 'analysis' && (
          <div className="space-y-5">

            {/* Filter bar — fully independent of the Performance tab's filter above */}
            <div className="flex items-center gap-2 flex-wrap">
              <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-lg p-1">
                {ANALYSIS_FILTERS.map(f => (
                  <button
                    key={f.key}
                    onClick={() => handleAnalysisFilterChange(f.key)}
                    className={`px-3 py-1 rounded-md text-xs font-semibold transition-all ${
                      analysisFilterPreset === f.key
                        ? 'bg-blue-600 text-white'
                        : 'text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    {f.label}
                  </button>
                ))}
              </div>

              {analysisFilterPreset === 'custom' && (
                <>
                  <input
                    type="date" value={analysisCustomFrom}
                    onChange={e => setAnalysisCustomFrom(e.target.value)}
                    className="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white outline-none focus:border-blue-500"
                  />
                  <span className="text-gray-400 text-xs">to</span>
                  <input
                    type="date" value={analysisCustomTo}
                    onChange={e => setAnalysisCustomTo(e.target.value)}
                    className="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white outline-none focus:border-blue-500"
                  />
                  <button
                    onClick={handleAnalysisApply}
                    disabled={analysisLoading}
                    className="px-3 py-1.5 bg-blue-600 text-white text-xs font-semibold rounded-lg hover:bg-blue-700 disabled:opacity-50"
                  >
                    Apply
                  </button>
                </>
              )}

              <button
                onClick={handleAnalysisFetchLive}
                disabled={analysisLoading}
                title="Fetch the latest data from Tally and save it to the database"
                className="flex items-center gap-1 px-3 py-1.5 bg-amber-500 text-white text-xs font-semibold rounded-lg hover:bg-amber-600 disabled:opacity-50"
              >
                <Zap className="w-3 h-3" />
                Fetch Live
              </button>

              {analysisLoading && <RefreshCw className="w-3.5 h-3.5 text-blue-500 animate-spin" />}
            </div>

            {!analysisLoading && analysisFetched && analysisUncachedRange && (
              <div className="flex items-center gap-2 px-3 py-2 bg-amber-50 border border-amber-200 rounded-lg">
                <AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                <p className="text-xs text-amber-700">No cached data for this range yet — click Fetch Live to pull it from Tally.</p>
              </div>
            )}

            {analysisActivePeriod && (
              <p className="text-xs text-gray-400">
                Showing: {analysisActivePeriod.from === analysisActivePeriod.to
                  ? new Date(analysisActivePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
                  : `${new Date(analysisActivePeriod.from).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })} – ${new Date(analysisActivePeriod.to).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`}
              </p>
            )}

            {/* 9 ratio KPI cards */}
            <div className="grid grid-cols-3 gap-4">
              {(() => {
                const r = computeRatios(analysisInputs)
                return (
                  <>
                    <RatioKpiCard title="DSO" subtitle="Days Sales Outstanding" icon={Users} value={r.dso} suffix=" days" />
                    <RatioKpiCard title="DIO" subtitle="Days Inventory Outstanding" icon={Store} value={r.dio} suffix=" days" />
                    <RatioKpiCard title="DPO" subtitle="Days Payables Outstanding" icon={Building2} value={r.dpo} suffix=" days" />
                    <RatioKpiCard title="CCC" subtitle="Cash Conversion Cycle" icon={RefreshCw} value={r.ccc} suffix=" days" />
                    <RatioKpiCard title="Current Ratio" subtitle="(Inventory + Debtors) / Creditors" icon={CheckCircle} value={r.currentRatio} />
                    <RatioKpiCard title="Quick Ratio" subtitle="Liquid Assets / Current Liabilities" icon={Zap} value={r.quickRatio} />
                    <RatioKpiCard title="ROCE" subtitle="Return on Capital Employed" icon={TrendingUp} value={r.roce} suffix="%" />
                    <RatioKpiCard title="ROE" subtitle="Return on Equity" icon={Wallet} value={r.roe} suffix="%" />
                    <RatioKpiCard title="Debt/Equity" subtitle="Borrowings vs Equity" icon={AlertTriangle} value={r.debtEquity} />
                  </>
                )
              })()}
            </div>

            <div className="grid grid-cols-1 gap-5">

              {/* Sales by Category */}
              <div className="bg-white rounded-xl border border-gray-200 p-4">
                <p className="text-sm font-semibold text-gray-700 mb-4">Sales by Category</p>
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={dummySalesByCategory} barCategoryGap="32%">
                    <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" vertical={false} />
                    <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#9CA3AF' }} tickLine={false} axisLine={false} />
                    <YAxis tick={{ fontSize: 10, fill: '#9CA3AF' }} tickLine={false} axisLine={false} width={44}
                      tickFormatter={(v: number) => `₹${(v / 1000).toFixed(0)}k`} />
                    <Tooltip content={<BarTip />} />
                    <Bar dataKey="value" name="Sales" radius={[4, 4, 0, 0]}>
                      {dummySalesByCategory.map((_, i) => (
                        <Cell key={i} fill={['#1D4ED8','#2563EB','#3B82F6','#60A5FA','#93C5FD'][i]} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

          </div>
        )}

        {/* ══════════════════ CFO SUGGESTIONS TAB ══════════════════ */}
        {activeTab === 'cfo' && (
          <div className="space-y-3">
            <div className="flex items-center gap-2 mb-1">
              <Lightbulb className="w-4 h-4 text-amber-500" />
              <p className="text-sm font-semibold text-gray-700">AI-Powered Financial Insights</p>
              <span className="ml-auto text-[10px] text-gray-400 bg-gray-100 border border-gray-200 px-2 py-0.5 rounded-full">
                Demo data · Live integration coming soon
              </span>
            </div>

            {cfoSuggestions.map((s, i) => {
              const isSuccess = s.type === 'success'
              const Icon = isSuccess ? CheckCircle : AlertTriangle
              const style = {
                warning: { wrap: 'border-amber-200 bg-amber-50', icon: 'text-amber-500', badge: 'bg-amber-100 text-amber-700' },
                alert:   { wrap: 'border-red-200 bg-red-50',     icon: 'text-red-500',   badge: 'bg-red-100 text-red-700'   },
                success: { wrap: 'border-green-200 bg-green-50', icon: 'text-green-600', badge: 'bg-green-100 text-green-700' },
              }[s.type]

              return (
                <div key={i} className={`rounded-xl border ${style.wrap} p-4`}>
                  <div className="flex items-start gap-3">
                    <Icon className={`w-4 h-4 mt-0.5 shrink-0 ${style.icon}`} />
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="text-sm font-semibold text-gray-800">{s.title}</p>
                        <span className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${style.badge}`}>
                          {s.impact}
                        </span>
                      </div>
                      <p className="text-xs text-gray-600 leading-relaxed">{s.body}</p>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}

      </div>
    </div>
  )
}
