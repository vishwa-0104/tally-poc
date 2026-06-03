import { useState, useCallback } from 'react'
import { toast } from 'react-hot-toast'
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Legend,
} from 'recharts'
import { TrendingUp, RefreshCw, AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { useAuthStore, useCompanyStore } from '@/store'
import { fetchTallyVouchers } from '@/services/tallyService'
import { getTallyUrl } from './CompanySettings'
import { formatCurrency } from '@/lib/utils'
import { useExtensionStatus } from '@/hooks/useExtension'

// ── Date helpers ─────────────────────────────────────────────────────────────

function toTallyDate(iso: string) {
  return iso.replace(/-/g, '') // YYYY-MM-DD → YYYYMMDD
}

function formatLabel(dateStr: string, granularity: Granularity): string {
  const d = new Date(dateStr)
  if (granularity === 'daily')   return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })
  if (granularity === 'weekly')  return `W${getWeekNumber(d)} ${d.getFullYear()}`
  return d.toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })
}

function getWeekNumber(d: Date): number {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
  const day  = date.getUTCDay() || 7
  date.setUTCDate(date.getUTCDate() + 4 - day)
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  return Math.ceil((((date.getTime() - yearStart.getTime()) / 86400000) + 1) / 7)
}

function getWeekStart(d: Date): string {
  const day  = d.getDay() || 7
  const mon  = new Date(d)
  mon.setDate(d.getDate() - day + 1)
  return mon.toISOString().slice(0, 10)
}

type Granularity = 'daily' | 'weekly' | 'monthly'

interface ChartPoint { label: string; amount: number }

function groupVouchers(
  vouchers: { date: string; amount: number }[],
  granularity: Granularity,
  fromDate: string,
  toDate: string,
): ChartPoint[] {
  const map = new Map<string, number>()

  // Pre-fill every slot in the range with 0 so empty days/weeks/months show up
  const start = new Date(fromDate)
  const end   = new Date(toDate)
  if (granularity === 'daily') {
    for (const d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      map.set(d.toISOString().slice(0, 10), 0)
    }
  } else if (granularity === 'weekly') {
    for (const d = new Date(start); d <= end; d.setDate(d.getDate() + 7)) {
      map.set(getWeekStart(d), 0)
    }
  } else {
    for (const d = new Date(start); d <= end; d.setMonth(d.getMonth() + 1)) {
      map.set(d.toISOString().slice(0, 7), 0)
    }
  }

  for (const v of vouchers) {
    const d   = new Date(v.date)
    let   key = ''
    if (granularity === 'daily')        key = v.date
    else if (granularity === 'weekly')  key = getWeekStart(d)
    else                                key = v.date.slice(0, 7)
    map.set(key, (map.get(key) ?? 0) + v.amount)
  }

  return [...map.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, amount]) => ({
      label:  formatLabel(granularity === 'monthly' ? key + '-01' : key, granularity),
      amount: parseFloat(amount.toFixed(2)),
    }))
}

// ── Preset date ranges ────────────────────────────────────────────────────────

function getPreset(preset: string): { from: string; to: string } {
  const today = new Date()
  const fmt   = (d: Date) => d.toISOString().slice(0, 10)

  if (preset === 'today') {
    const s = fmt(today)
    return { from: s, to: s }
  }
  if (preset === 'this_week') {
    const mon = new Date(today)
    mon.setDate(today.getDate() - (today.getDay() || 7) + 1)
    return { from: fmt(mon), to: fmt(today) }
  }
  if (preset === 'this_month') {
    return { from: fmt(new Date(today.getFullYear(), today.getMonth(), 1)), to: fmt(today) }
  }
  if (preset === 'last_month') {
    const first = new Date(today.getFullYear(), today.getMonth() - 1, 1)
    const last  = new Date(today.getFullYear(), today.getMonth(), 0)
    return { from: fmt(first), to: fmt(last) }
  }
  if (preset === 'last_3_months') {
    const from = new Date(today)
    from.setMonth(from.getMonth() - 3)
    return { from: fmt(from), to: fmt(today) }
  }
  // this_year — financial year Apr–Mar
  const fyStart = today.getMonth() >= 3
    ? new Date(today.getFullYear(), 3, 1)
    : new Date(today.getFullYear() - 1, 3, 1)
  return { from: fmt(fyStart), to: fmt(today) }
}

const PRESETS = [
  { key: 'today',          label: 'Today' },
  { key: 'this_week',      label: 'This Week' },
  { key: 'this_month',     label: 'This Month' },
  { key: 'last_month',     label: 'Last Month' },
  { key: 'last_3_months',  label: 'Last 3 Months' },
  { key: 'this_year',      label: 'This FY' },
] as const

// ── Custom tooltip ────────────────────────────────────────────────────────────

function CustomTooltip({ active, payload, label }: { active?: boolean; payload?: { value: number }[]; label?: string }) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-white border border-gray-200 rounded-lg shadow-md px-3 py-2 text-xs">
      <p className="font-semibold text-gray-700 mb-1">{label}</p>
      <p className="text-brand-600 font-bold">{formatCurrency(payload[0].value)}</p>
    </div>
  )
}

// ── Main component ────────────────────────────────────────────────────────────

export default function Dashboard() {
  const { activeCompanyId }  = useAuthStore()
  const { getCompany }       = useCompanyStore()
  const { connected }        = useExtensionStatus()

  const companyId   = activeCompanyId ?? ''
  const company     = getCompany(companyId)
  const tallyUrl    = getTallyUrl(companyId, company?.port)
  const tallyCompany = company?.name ?? undefined

  const initPreset = 'this_month'
  const initDates  = getPreset(initPreset)

  const [preset,      setPreset]      = useState<string>(initPreset)
  const [fromDate,    setFromDate]    = useState(initDates.from)
  const [toDate,      setToDate]      = useState(initDates.to)
  const [granularity, setGranularity] = useState<Granularity>('daily')
  const [voucherType, setVoucherType] = useState('Sales')

  const [chartData,  setChartData]  = useState<ChartPoint[]>([])
  const [total,      setTotal]      = useState(0)
  const [loading,    setLoading]    = useState(false)
  const [fetched,    setFetched]    = useState(false)
  const [error,      setError]      = useState<string | null>(null)

  const handlePreset = (key: string) => {
    setPreset(key)
    const { from, to } = getPreset(key)
    setFromDate(from)
    setToDate(to)
  }

  const fetchData = useCallback(async () => {
    if (!connected) { toast.error('Extension not connected. Make sure Tally is running.'); return }
    setLoading(true)
    setError(null)
    try {
      const vouchers = await fetchTallyVouchers(
        toTallyDate(fromDate), toTallyDate(toDate), voucherType, tallyUrl, tallyCompany,
      )
      const grouped = groupVouchers(vouchers, granularity, fromDate, toDate)
      setChartData(grouped)
      setTotal(vouchers.reduce((s, v) => s + v.amount, 0))
      setFetched(true)
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch data'
      setError(msg)
      toast.error(msg)
    } finally {
      setLoading(false)
    }
  }, [connected, fromDate, toDate, voucherType, granularity, tallyUrl, tallyCompany])

  return (
    <div className="flex flex-col h-full overflow-y-auto bg-gray-50">
      <div className="px-6 py-5 max-w-6xl w-full mx-auto space-y-5">

        {/* Header */}
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-brand-600" />
            <h1 className="text-base font-bold text-gray-900">Sales Trend</h1>
          </div>
          {!connected && (
            <span className="text-xs text-amber-600 bg-amber-50 border border-amber-200 rounded px-2 py-1">
              Extension not connected — connect to load data
            </span>
          )}
        </div>

        {/* Filters card */}
        <div className="bg-white rounded-xl border border-gray-200 p-4 space-y-4">

          {/* Voucher type + granularity */}
          <div className="flex items-center gap-4 flex-wrap">
            <div className="flex items-center gap-2">
              <label className="text-xs font-semibold text-gray-600 whitespace-nowrap">Voucher Type</label>
              <select
                value={voucherType}
                onChange={(e) => setVoucherType(e.target.value)}
                className="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white outline-none focus:border-brand-500"
              >
                {['Sales', 'GST Sales', 'Purchase', 'GST Purchase', 'Receipt', 'Payment', 'Contra', 'Journal'].map((t) => (
                  <option key={t} value={t}>{t}</option>
                ))}
              </select>
            </div>

            <div className="flex items-center gap-1 ml-auto bg-gray-100 rounded-lg p-0.5">
              {(['daily', 'weekly', 'monthly'] as Granularity[]).map((g) => (
                <button
                  key={g}
                  onClick={() => setGranularity(g)}
                  className={`px-3 py-1 rounded-md text-xs font-semibold capitalize transition-all ${
                    granularity === g
                      ? 'bg-white text-brand-600 shadow-sm'
                      : 'text-gray-500 hover:text-gray-700'
                  }`}
                >
                  {g}
                </button>
              ))}
            </div>
          </div>

          {/* Preset buttons */}
          <div className="flex items-center gap-2 flex-wrap">
            {PRESETS.map((p) => (
              <button
                key={p.key}
                onClick={() => handlePreset(p.key)}
                className={`px-3 py-1 rounded-lg text-xs font-semibold border transition-all ${
                  preset === p.key
                    ? 'bg-brand-500 text-white border-brand-500'
                    : 'bg-white text-gray-600 border-gray-200 hover:border-brand-400'
                }`}
              >
                {p.label}
              </button>
            ))}
          </div>

          {/* Custom date range */}
          <div className="flex items-center gap-3 flex-wrap">
            <div className="flex items-center gap-2">
              <label className="text-xs font-semibold text-gray-600">From</label>
              <input
                type="date"
                value={fromDate}
                onChange={(e) => { setFromDate(e.target.value); setPreset('') }}
                className="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white outline-none focus:border-brand-500"
              />
            </div>
            <div className="flex items-center gap-2">
              <label className="text-xs font-semibold text-gray-600">To</label>
              <input
                type="date"
                value={toDate}
                onChange={(e) => { setToDate(e.target.value); setPreset('') }}
                className="text-xs border border-gray-200 rounded-lg px-2.5 py-1.5 bg-white outline-none focus:border-brand-500"
              />
            </div>
            <Button
              variant="primary"
              onClick={fetchData}
              loading={loading}
              disabled={loading || !connected}
              className="ml-auto"
            >
              <RefreshCw className="w-3.5 h-3.5 mr-1.5" />
              {fetched ? 'Refresh' : 'Load Data'}
            </Button>
          </div>
        </div>

        {/* Summary stat */}
        {fetched && !error && (
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            <div className="bg-white rounded-xl border border-gray-200 px-4 py-3">
              <p className="text-xs text-gray-500 mb-1">Total {voucherType}</p>
              <p className="text-lg font-bold text-gray-900">{formatCurrency(total)}</p>
            </div>
            <div className="bg-white rounded-xl border border-gray-200 px-4 py-3">
              <p className="text-xs text-gray-500 mb-1">Entries</p>
              <p className="text-lg font-bold text-gray-900">{chartData.length}</p>
            </div>
            <div className="bg-white rounded-xl border border-gray-200 px-4 py-3">
              <p className="text-xs text-gray-500 mb-1">Period</p>
              <p className="text-sm font-semibold text-gray-700">
                {new Date(fromDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}
                {' — '}
                {new Date(toDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
              </p>
            </div>
          </div>
        )}

        {/* Chart */}
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          {error ? (
            <div className="flex flex-col items-center justify-center h-64 gap-3 text-center">
              <AlertCircle className="w-8 h-8 text-red-400" />
              <p className="text-sm text-red-600 font-medium">Failed to load data</p>
              <p className="text-xs text-gray-500 max-w-sm">{error}</p>
            </div>
          ) : !fetched ? (
            <div className="flex flex-col items-center justify-center h-64 gap-2 text-center">
              <TrendingUp className="w-8 h-8 text-gray-300" />
              <p className="text-sm text-gray-400">Select a date range and click Load Data</p>
            </div>
          ) : chartData.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-64 gap-2">
              <p className="text-sm text-gray-400">No {voucherType} vouchers found for this period</p>
            </div>
          ) : (
            <>
              <p className="text-xs font-semibold text-gray-600 mb-4">{voucherType} — {granularity} view</p>
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={chartData} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
                  <defs>
                    <linearGradient id="salesGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%"  stopColor="#1A56B0" stopOpacity={0.15} />
                      <stop offset="95%" stopColor="#1A56B0" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" />
                  <XAxis
                    dataKey="label"
                    tick={{ fontSize: 11, fill: '#6B7280' }}
                    tickLine={false}
                    axisLine={false}
                    interval="preserveStartEnd"
                  />
                  <YAxis
                    tick={{ fontSize: 11, fill: '#6B7280' }}
                    tickLine={false}
                    axisLine={false}
                    tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}k`}
                    width={52}
                  />
                  <Tooltip content={<CustomTooltip />} />
                  <Legend wrapperStyle={{ fontSize: 11 }} />
                  <Area
                    type="monotone"
                    dataKey="amount"
                    name={voucherType}
                    stroke="#1A56B0"
                    strokeWidth={2}
                    fill="url(#salesGradient)"
                    dot={{ r: 3, fill: '#1A56B0', strokeWidth: 0 }}
                    activeDot={{ r: 5 }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </>
          )}
        </div>

      </div>
    </div>
  )
}
