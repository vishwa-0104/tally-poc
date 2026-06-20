import { useState, useCallback, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, BarChart, Bar, Cell,
} from 'recharts'
import {
  TrendingUp, TrendingDown, AlertCircle, PackageX,
  BarChart2, Lightbulb, AlertTriangle, CheckCircle,
  ArrowUpRight, ArrowDownRight, RefreshCw, Settings, Wallet, Building2,
} from 'lucide-react'
import { useAuthStore, useCompanyStore } from '@/store'
import { fetchDaybook, fetchTopDebtors, fetchSlowMovingStock, fetchLedgerBalances, type SlowStockItem, type TallyVoucher, type RawLedger } from '@/services/tallyService'
import { fetchSalesTargets, fetchDashboardSettings } from '@/lib/api'
import type { DashboardSettings } from '@/types'
import { getTallyUrl } from './CompanySettings'
import { formatCurrency } from '@/lib/utils'
import { useExtensionStatus } from '@/hooks/useExtension'
import { SalesTargetModal } from '@/components/company/SalesTargetModal'

// ── Types ─────────────────────────────────────────────────────────────────────

type Tab           = 'performance' | 'analysis' | 'cfo'
type FilterPreset  = 'today' | 'quarter' | 'year' | 'custom'
type Granularity   = 'daily' | 'weekly' | 'monthly'
interface ChartPoint { label: string; amount: number }

// ── Date helpers ──────────────────────────────────────────────────────────────

function toTallyDate(iso: string) { return iso.replace(/-/g, '') }
const fmt = (d: Date) => d.toISOString().slice(0, 10)
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
  if (preset === 'year') {
    const fyStart = today.getMonth() >= 3
      ? new Date(today.getFullYear(), 3, 1)
      : new Date(today.getFullYear() - 1, 3, 1)
    return { from: fmt(fyStart), to: fmt(today) }
  }
  return { from: cfrom, to: cto }
}

function autoGranularity(preset: FilterPreset): Granularity {
  if (preset === 'today')   return 'daily'
  if (preset === 'quarter') return 'weekly'
  return 'monthly'
}

function getWeekStart(d: Date): string {
  const day = d.getDay() || 7
  const mon = new Date(d)
  mon.setDate(d.getDate() - day + 1)
  return mon.toISOString().slice(0, 10)
}

function getWeekNumber(d: Date): number {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
  const day  = date.getUTCDay() || 7
  date.setUTCDate(date.getUTCDate() + 4 - day)
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  return Math.ceil((((date.getTime() - yearStart.getTime()) / 86400000) + 1) / 7)
}

function formatLabel(dateStr: string, granularity: Granularity): string {
  const d = new Date(dateStr)
  if (granularity === 'daily')   return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })
  if (granularity === 'weekly')  return `W${getWeekNumber(d)}`
  return d.toLocaleDateString('en-IN', { month: 'short', year: '2-digit' })
}

function groupVouchers(
  vouchers: { date: string; amount: number }[],
  granularity: Granularity,
  fromDate: string,
  toDate: string,
): ChartPoint[] {
  const map  = new Map<string, number>()
  const start = new Date(fromDate)
  const end   = new Date(toDate)

  if (granularity === 'daily') {
    for (const d = new Date(start); d <= end; d.setDate(d.getDate() + 1))
      map.set(d.toISOString().slice(0, 10), 0)
  } else if (granularity === 'weekly') {
    for (const d = new Date(start); d <= end; d.setDate(d.getDate() + 7))
      map.set(getWeekStart(d), 0)
  } else {
    for (const d = new Date(start); d <= end; d.setMonth(d.getMonth() + 1))
      map.set(d.toISOString().slice(0, 7), 0)
  }

  for (const v of vouchers) {
    const d   = new Date(v.date)
    const key =
      granularity === 'daily'  ? v.date :
      granularity === 'weekly' ? getWeekStart(d) :
                                 v.date.slice(0, 7)
    map.set(key, (map.get(key) ?? 0) + v.amount)
  }

  return [...map.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, amount]) => ({
      label:  formatLabel(granularity === 'monthly' ? key + '-01' : key, granularity),
      amount: parseFloat(amount.toFixed(2)),
    }))
}

// ── Dashboard settings helpers ────────────────────────────────────────────────

function isSalesVoucher(v: TallyVoucher, settings: DashboardSettings): boolean {
  const saved = settings.today?.salesVoucherTypes
  if (saved?.length) return saved.some(t => v.type.toLowerCase() === t.toLowerCase())
  return v.type.toLowerCase().includes('sales') && !v.type.toLowerCase().includes('credit')
}

// Parse rawXml from TBSVouchers (which now includes AllLedgerEntries.LedgerName)
// to compute cash inflow and outflow for the period.
function computeCashFlow(
  rawXml: string,
  rawLedgers: RawLedger[],
  settings: DashboardSettings,
): { inflow: number; outflow: number; inHand: number } {
  // Determine which ledger names are "cash" ledgers
  const savedInflow  = settings.today?.cashInflowLedgers
  const savedOutflow = settings.today?.cashOutflowLedgers
  const cashByGroup  = new Set(
    rawLedgers
      .filter(l => l.group.toLowerCase().includes('cash'))
      .map(l => l.name.toLowerCase()),
  )
  const inflowSet  = savedInflow?.length
    ? new Set(savedInflow.map(n => n.toLowerCase()))
    : cashByGroup
  const outflowSet = savedOutflow?.length
    ? new Set(savedOutflow.map(n => n.toLowerCase()))
    : cashByGroup

  // Parse <ALLLEDGERENTRIES.LIST> blocks from rawXml
  let inflow = 0, outflow = 0
  const entryRe = /<ALLLEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES\.LIST>/gi
  for (const [, block] of [...rawXml.matchAll(entryRe)]) {
    const nameM   = block.match(/<LEDGERNAME[^>]*>([\s\S]*?)<\/LEDGERNAME>/i)
    const amountM = block.match(/<AMOUNT[^>]*>([\s\S]*?)<\/AMOUNT>/i)
    if (!nameM || !amountM) continue
    const ledger = nameM[1].trim().toLowerCase()
    const amount = parseFloat(amountM[1].replace(/,/g, '')) || 0
    if (amount > 0 && inflowSet.has(ledger))  inflow  += amount
    if (amount < 0 && outflowSet.has(ledger)) outflow += Math.abs(amount)
  }

  // Cash In Hand = sum of closing balances of cash (or saved inflow) ledgers
  const inHandSet = savedInflow?.length ? inflowSet : cashByGroup
  const inHand = rawLedgers
    .filter(l => inHandSet.has(l.name.toLowerCase()))
    .reduce((s, l) => s + l.balance, 0)

  return { inflow, outflow, inHand }
}

function computeBankFlow(
  rawXml: string,
  rawLedgers: RawLedger[],
): { inflow: number; outflow: number; balance: number } {
  const bankByGroup = new Set(
    rawLedgers
      .filter(l => l.group.toLowerCase().includes('bank'))
      .map(l => l.name.toLowerCase()),
  )

  let inflow = 0, outflow = 0
  const entryRe = /<ALLLEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES\.LIST>/gi
  for (const [, block] of [...rawXml.matchAll(entryRe)]) {
    const nameM   = block.match(/<LEDGERNAME[^>]*>([\s\S]*?)<\/LEDGERNAME>/i)
    const amountM = block.match(/<AMOUNT[^>]*>([\s\S]*?)<\/AMOUNT>/i)
    if (!nameM || !amountM) continue
    const ledger = nameM[1].trim().toLowerCase()
    const amount = parseFloat(amountM[1].replace(/,/g, '')) || 0
    if (amount > 0 && bankByGroup.has(ledger)) inflow  += amount
    if (amount < 0 && bankByGroup.has(ledger)) outflow += Math.abs(amount)
  }

  const balance = rawLedgers
    .filter(l => bankByGroup.has(l.name.toLowerCase()))
    .reduce((s, l) => s + l.balance, 0)

  return { inflow, outflow, balance }
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
  if (preset === 'year')    months = [1,2,3,4,5,6,7,8,9,10,11,12]
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

const dummyYoY = [
  { month: 'Jan', thisYear: 7200, lastYear: 6800 },
  { month: 'Feb', thisYear: 6900, lastYear: 7100 },
  { month: 'Mar', thisYear: 8100, lastYear: 7600 },
  { month: 'Apr', thisYear: 7800, lastYear: 6900 },
  { month: 'May', thisYear: 8916, lastYear: 8200 },
  { month: 'Jun', thisYear: 0,    lastYear: 7900 },
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
      <p className={`text-2xl font-bold tracking-tight mb-0.5 ${placeholder ? 'text-gray-300' : 'text-gray-900'}`}>
        {placeholder ? '—' : value}
      </p>
      <p className="text-xs font-semibold text-gray-600">{title}</p>
      <p className="text-[11px] text-gray-400 mt-0.5">{subtitle}</p>
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

function SalesTip({ active, payload, label }: { active?: boolean; payload?: { value: number }[]; label?: string }) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white border border-gray-200 rounded-lg shadow px-3 py-2 text-xs">
      <p className="font-semibold text-gray-600 mb-0.5">{label}</p>
      <p className="text-blue-700 font-bold">{formatCurrency(payload[0].value)}</p>
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
      <div className="flex items-start justify-between mb-3">
        <div className="p-2 bg-emerald-50 rounded-lg">
          <Wallet className="w-4 h-4 text-emerald-600" />
        </div>
      </div>
      <p className="text-2xl font-bold tracking-tight text-gray-900 mb-0.5">Cash</p>
      <div className="mt-3 space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-500">Cash Inflow</span>
          <span className="text-xs font-semibold text-emerald-600">{val(inflow)}</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-500">Cash Outflow</span>
          <span className="text-xs font-semibold text-red-500">{val(outflow)}</span>
        </div>
        <div className="flex items-center justify-between border-t border-gray-100 pt-2">
          <span className="text-xs text-gray-500">Cash In Hand</span>
          <span className="text-xs font-semibold text-gray-800">{val(inHand)}</span>
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
      <div className="flex items-start justify-between mb-3">
        <div className="p-2 bg-blue-50 rounded-lg">
          <Building2 className="w-4 h-4 text-blue-600" />
        </div>
      </div>
      <p className="text-2xl font-bold tracking-tight text-gray-900 mb-0.5">Banks</p>
      <div className="mt-3 space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-500">Bank Inflow</span>
          <span className="text-xs font-semibold text-emerald-600">{val(inflow)}</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-500">Bank Outflow</span>
          <span className="text-xs font-semibold text-red-500">{val(outflow)}</span>
        </div>
        <div className="flex items-center justify-between border-t border-gray-100 pt-2">
          <span className="text-xs text-gray-500">Balance in Bank</span>
          <span className="text-xs font-semibold text-gray-800">{val(balance)}</span>
        </div>
      </div>
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
  { key: 'year',    label: 'This Year'    },
  { key: 'custom',  label: 'Custom'       },
]

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

  const [chartData,     setChartData]     = useState<ChartPoint[]>([])
  const [topParties,    setTopParties]    = useState<{ party: string; amount: number }[]>([])
  const [total,         setTotal]         = useState(0)
  const [prevDaySales,  setPrevDaySales]  = useState<number | null>(null)
  const [slowStock,     setSlowStock]     = useState<SlowStockItem[]>([])
  const [loading,       setLoading]       = useState(false)
  const [fetched,       setFetched]       = useState(false)
  const [error,         setError]         = useState<string | null>(null)
  const [activePeriod,  setActivePeriod]  = useState<{ from: string; to: string } | null>(null)

  const fetchData = useCallback(async (preset: FilterPreset, cfrom: string, cto: string) => {
    if (!connected) {
      toast.error('Extension not connected. Make sure Tally is running.')
      return
    }
    const { from, to } = getFilterDates(preset, cfrom, cto)
    const granularity  = autoGranularity(preset)

    setLoading(true)
    setError(null)
    try {
      const { vouchers: all, rawXml } = await fetchDaybook(toTallyDate(from), toTallyDate(to), tallyUrl, tallyCompany)

      // Debug: totals per voucher type
      const byType: Record<string, { preGst: number; gst: number; count: number }> = {}
      for (const v of all) {
        if (!byType[v.type]) byType[v.type] = { preGst: 0, gst: 0, count: 0 }
        byType[v.type].preGst += v.taxableAmount
        byType[v.type].gst    += v.amount - v.taxableAmount
        byType[v.type].count  += 1
      }
      console.log('[Voucher Totals by Type]', byType)

      const sales       = all.filter(v => isSalesVoucher(v, dashboardSettings))
      const creditNotes = all.filter(v => v.type.toLowerCase() === 'credit note')

      // Use taxableAmount (GST excluded); credit notes reduce net sales
      const chartVouchers = [
        ...sales.map(v => ({ ...v, amount: v.taxableAmount })),
        ...creditNotes.map(v => ({ ...v, amount: -v.taxableAmount })),
      ]
      setChartData(groupVouchers(chartVouchers, granularity, from, to))
      const salesTotal  = sales.reduce((s, v) => s + v.taxableAmount, 0)
      const creditTotal = creditNotes.reduce((s, v) => s + v.taxableAmount, 0)
      const todaySalesTotal = salesTotal - creditTotal
      setTotal(todaySalesTotal)
      setActivePeriod({ from, to })
      console.log('[Today] Total sales:', todaySalesTotal, '| date:', from)

      try {
        const debtors = await fetchTopDebtors(10)
        setTopParties(debtors.map(r => ({ party: r.name, amount: r.balance })))
      } catch { /* agent may not be running */ }

      try {
        const { items } = await fetchSlowMovingStock(tallyUrl, tallyCompany)
        setSlowStock(items)
      } catch { /* non-critical */ }

      // Fetch ledger balances for Cash/Bank — sequential, after slow stock
      try {
        const { rawLedgers } = await fetchLedgerBalances(tallyUrl, tallyCompany, toTallyDate(to))
        const cf = computeCashFlow(rawXml, rawLedgers, dashboardSettings)
        console.log('[CashFlow] inflow:', cf.inflow, '| outflow:', cf.outflow, '| inHand:', cf.inHand)
        setCashInflow(cf.inflow)
        setCashOutflow(cf.outflow)
        setCashInHand(cf.inHand)
        const bf = computeBankFlow(rawXml, rawLedgers)
        console.log('[BankFlow] inflow:', bf.inflow, '| outflow:', bf.outflow, '| balance:', bf.balance)
        setBankInflow(bf.inflow)
        setBankOutflow(bf.outflow)
        setBankBalance(bf.balance)
      } catch (err) {
        console.error('[CashFlow] fetchLedgerBalances failed:', err)
        setCashInflow(null); setCashOutflow(null); setCashInHand(null)
        setBankInflow(null); setBankOutflow(null); setBankBalance(null)
      }

      setFetched(true)

      // Yesterday fetch is LAST — after slow stock — so Tally isn't hit concurrently
      if (preset === 'today') {
        setPrevDaySales(null)
        const yDate = new Date(); yDate.setDate(yDate.getDate() - 1)
        const yd    = fmt(yDate)
        console.log('[PrevDay] Fetching yesterday sales. Date:', yd, 'TallyDate:', toTallyDate(yd))
        try {
          const { vouchers: yv } = await fetchDaybook(toTallyDate(yd), toTallyDate(yd), tallyUrl, tallyCompany)
          console.log('[PrevDay] Raw vouchers received:', yv.length, yv)
          const yS = yv.filter(v => isSalesVoucher(v, dashboardSettings))
          const yC = yv.filter(v => v.type.toLowerCase() === 'credit note')
          const yTotal = yS.reduce((s, v) => s + v.taxableAmount, 0) - yC.reduce((s, v) => s + v.taxableAmount, 0)
          console.log('[PrevDay] Sales vouchers:', yS.length, '| Credit notes:', yC.length, '| Total:', yTotal)
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
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch data'
      setError(msg)
      toast.error(msg)
    } finally {
      setLoading(false)
    }
  }, [connected, tallyUrl, tallyCompany])

  const reloadMeta = () => {
    if (!companyId) return
    fetchSalesTargets(companyId, fyYear)
      .then(rows => {
        const map: Record<number, number> = {}
        rows.forEach(r => { map[r.month] = r.target })
        setMonthlyTargets(map)
      })
      .catch(() => { /* optional */ })
    fetchDashboardSettings(companyId)
      .then(setDashboardSettings)
      .catch(() => { /* optional */ })
  }

  // Auto-fetch today + load targets/settings on mount
  useEffect(() => {
    fetchData('today', todayStr(), todayStr())
    reloadMeta()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const handleTabChange = (tab: Tab) => {
    setActiveTab(tab)
    if (tab === 'performance' && !fetched && !loading)
      fetchData('today', todayStr(), todayStr())
  }

  const handleFilterChange = (preset: FilterPreset) => {
    setFilterPreset(preset)
    if (preset !== 'custom')
      fetchData(preset, customFrom, customTo)
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
        onClose={() => { setShowTargetModal(false); reloadMeta() }}
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
                    onClick={() => fetchData('custom', customFrom, customTo)}
                    disabled={loading}
                    className="px-3 py-1.5 bg-blue-600 text-white text-xs font-semibold rounded-lg hover:bg-blue-700 disabled:opacity-50"
                  >
                    Apply
                  </button>
                </>
              )}

              {loading && <RefreshCw className="w-3.5 h-3.5 text-blue-500 animate-spin" />}
            </div>

            {/* KPI cards */}
            <div className="grid grid-cols-5 gap-4">
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
              <KpiCard
                title="EBITDA"
                value="—"
                subtitle="API integration coming soon"
                icon={BarChart2}
                placeholder
              />
              <KpiCard
                title="Slow Moving Stock"
                value={fetched ? slowStock.length : '—'}
                subtitle="Items with no recent sales"
                icon={PackageX}
                trend={fetched && slowStock.length > 0 ? { value: -3 } : undefined}
              />
            </div>

            {/* Error */}
            {error && (
              <div className="flex items-center gap-3 bg-red-50 border border-red-200 rounded-xl px-4 py-3">
                <AlertCircle className="w-4 h-4 text-red-500 shrink-0" />
                <p className="text-xs text-red-600">{error}</p>
              </div>
            )}

            {/* Sales trend chart */}
            <div className="bg-white rounded-xl border border-gray-200 p-4">
              <div className="flex items-center justify-between mb-4">
                <p className="text-sm font-semibold text-gray-700">Sales Trend</p>
                {fetched && (
                  <p className="text-xs text-gray-400">
                    {chartData.length} data point{chartData.length !== 1 ? 's' : ''}
                  </p>
                )}
              </div>

              {!fetched ? (
                <div className="flex flex-col items-center justify-center h-52 gap-2">
                  <TrendingUp className="w-8 h-8 text-gray-200" />
                  <p className="text-xs text-gray-400">
                    {loading ? 'Fetching data…' : 'Waiting for data'}
                  </p>
                </div>
              ) : chartData.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-52">
                  <p className="text-xs text-gray-400">No sales vouchers found for this period</p>
                </div>
              ) : (
                <ResponsiveContainer width="100%" height={240}>
                  <AreaChart data={chartData} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
                    <defs>
                      <linearGradient id="sg" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%"  stopColor="#2563EB" stopOpacity={0.15} />
                        <stop offset="95%" stopColor="#2563EB" stopOpacity={0}    />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" />
                    <XAxis dataKey="label" tick={{ fontSize: 11, fill: '#9CA3AF' }} tickLine={false} axisLine={false} interval="preserveStartEnd" />
                    <YAxis tick={{ fontSize: 11, fill: '#9CA3AF' }} tickLine={false} axisLine={false} tickFormatter={(v: number) => `₹${(v / 1000).toFixed(0)}k`} width={48} />
                    <Tooltip content={<SalesTip />} />
                    <Area type="monotone" dataKey="amount" name="Sales" stroke="#2563EB" strokeWidth={2} fill="url(#sg)" dot={{ r: 3, fill: '#2563EB', strokeWidth: 0 }} activeDot={{ r: 5 }} />
                  </AreaChart>
                </ResponsiveContainer>
              )}
            </div>

            {/* Top debtors */}
            {fetched && topParties.length > 0 && (
              <div className="bg-white rounded-xl border border-gray-200 p-4">
                <p className="text-sm font-semibold text-gray-700 mb-3">Top Debtors by Outstanding Balance</p>
                <table className="w-full text-xs border-collapse">
                  <thead>
                    <tr className="border-b border-gray-100">
                      <th className="text-left py-2 px-2 font-semibold text-gray-400">#</th>
                      <th className="text-left py-2 px-2 font-semibold text-gray-400">Customer</th>
                      <th className="text-right py-2 px-2 font-semibold text-gray-400">Outstanding</th>
                      <th className="text-right py-2 px-2 font-semibold text-gray-400">Share</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {topParties.map((p, i) => (
                      <tr key={p.party} className="hover:bg-gray-50">
                        <td className="py-2 px-2 text-gray-400">{i + 1}</td>
                        <td className="py-2 px-2 text-gray-800 font-medium">{p.party}</td>
                        <td className="py-2 px-2 text-right text-gray-800">{formatCurrency(p.amount)}</td>
                        <td className="py-2 px-2 text-right text-gray-500">
                          {total > 0 ? `${((p.amount / total) * 100).toFixed(1)}%` : '—'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </>
        )}

        {/* ══════════════════ ANALYSIS TAB ══════════════════ */}
        {activeTab === 'analysis' && (
          <div className="space-y-5">
            <div className="grid grid-cols-2 gap-5">

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

              {/* Year-over-Year */}
              <div className="bg-white rounded-xl border border-gray-200 p-4">
                <p className="text-sm font-semibold text-gray-700 mb-4">Year-over-Year Comparison</p>
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={dummyYoY} barGap={3} barCategoryGap="30%">
                    <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" vertical={false} />
                    <XAxis dataKey="month" tick={{ fontSize: 10, fill: '#9CA3AF' }} tickLine={false} axisLine={false} />
                    <YAxis tick={{ fontSize: 10, fill: '#9CA3AF' }} tickLine={false} axisLine={false} width={44}
                      tickFormatter={(v: number) => `₹${(v / 1000).toFixed(0)}k`} />
                    <Tooltip content={<BarTip />} />
                    <Bar dataKey="thisYear" name="This Year" fill="#2563EB" radius={[3, 3, 0, 0]} />
                    <Bar dataKey="lastYear" name="Last Year" fill="#E5E7EB" radius={[3, 3, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
                <div className="flex gap-4 justify-center mt-2">
                  <span className="flex items-center gap-1.5 text-[10px] text-gray-500">
                    <span className="w-3 h-3 rounded-sm bg-blue-600 inline-block" />This Year
                  </span>
                  <span className="flex items-center gap-1.5 text-[10px] text-gray-500">
                    <span className="w-3 h-3 rounded-sm bg-gray-200 inline-block" />Last Year
                  </span>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl border border-gray-200 p-5 text-center">
              <p className="text-sm font-semibold text-gray-600 mb-1">More analysis panels coming soon</p>
              <p className="text-xs text-gray-400">Gross margin trend, expense breakdown, and debtor aging analysis will appear here.</p>
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
