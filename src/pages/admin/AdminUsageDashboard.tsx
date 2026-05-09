import { useState, useEffect, useMemo } from 'react'
import { Activity } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { api } from '@/lib/api'
import { cn } from '@/lib/utils'
import { useCompanyStore } from '@/store/companyStore'

interface ModelStat {
  model:           string
  requests:        number
  successRequests: number
  inputTokens:     number
  outputTokens:    number
  costInr:         number
  costPerBill:     number
}

interface DashboardData {
  period:  string
  byModel: ModelStat[]
  total:   ModelStat
}

type Period = '1d' | '7d' | 'mtd' | 'ytd' | 'all'

const PERIODS: { key: Period; label: string }[] = [
  { key: '1d',  label: 'Today'         },
  { key: '7d',  label: 'Last 7 Days'   },
  { key: 'mtd', label: 'Month to Date' },
  { key: 'ytd', label: 'Year to Date'  },
  { key: 'all', label: 'All Time'      },
]

function fmtTokens(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(2)}M`
  if (n >= 1_000)     return `${(n / 1_000).toFixed(1)}K`
  return String(n)
}

function fmtInr(n: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency', currency: 'INR', minimumFractionDigits: 2, maximumFractionDigits: 2,
  }).format(n)
}

function modelLabel(raw: string): string {
  return raw
    .replace('claude-', 'Claude ')
    .replace('gemini-', 'Gemini ')
    .replace(/-latest$/, '')
    .replace(/-(\d{8})$/, '')
    .replace(/-/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase())
    .trim()
}

function sumRows(rows: ModelStat[]): ModelStat {
  const base = { model: 'total', requests: 0, successRequests: 0, inputTokens: 0, outputTokens: 0, costInr: 0, costPerBill: 0 }
  const s = rows.reduce((acc, m) => ({
    ...acc,
    requests:        acc.requests        + m.requests,
    successRequests: acc.successRequests + m.successRequests,
    inputTokens:     acc.inputTokens     + m.inputTokens,
    outputTokens:    acc.outputTokens    + m.outputTokens,
    costInr:         parseFloat((acc.costInr + m.costInr).toFixed(2)),
  }), base)
  s.costPerBill = s.requests > 0 ? parseFloat((s.costInr / s.requests).toFixed(4)) : 0
  return s
}

function SummaryCard({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 px-5 py-4">
      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">{label}</p>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
      {sub && <p className="text-xs text-gray-400 mt-0.5">{sub}</p>}
    </div>
  )
}

export default function AdminUsageDashboard() {
  const [period, setPeriod]               = useState<Period>('7d')
  const [selectedModel, setSelectedModel] = useState<string>('')
  const [companyId, setCompanyId]         = useState<string>('')
  const [data, setData]                   = useState<DashboardData | null>(null)
  const [loading, setLoading]             = useState(true)
  const [error, setError]                 = useState<string | null>(null)

  const { companies } = useCompanyStore()

  useEffect(() => {
    setLoading(true)
    setError(null)
    const params = new URLSearchParams({ period })
    if (companyId) params.set('companyId', companyId)
    api.get<DashboardData>(`/admin/usage-dashboard?${params}`)
      .then((r) => {
        setData(r.data)
        const flash = r.data.byModel.find((m) => m.model.toLowerCase().includes('flash'))
        setSelectedModel(flash?.model ?? r.data.byModel[0]?.model ?? '')
      })
      .catch(() => setError('Failed to load usage data'))
      .finally(() => setLoading(false))
  }, [period, companyId])

  const visibleRows = useMemo(() => {
    if (!data?.byModel.length) return []
    if (!selectedModel) return data.byModel
    return data.byModel.filter((m) => m.model === selectedModel)
  }, [data, selectedModel])

  const displayTotal = useMemo(() => sumRows(visibleRows), [visibleRows])

  const availableModels = data?.byModel ?? []

  return (
    <>
      <PageHeader
        title="Usage Dashboard"
        subtitle={companyId ? `AI parse usage — ${companies.find((c) => c.id === companyId)?.name ?? ''}` : 'AI parse token consumption and cost across all companies'}
        actions={
          <div className="flex items-center gap-3 flex-wrap">
            {/* Company selector */}
            <select
              value={companyId}
              onChange={(e) => setCompanyId(e.target.value)}
              className="text-xs border border-gray-200 rounded-lg px-3 py-1.5 bg-white text-gray-700 font-medium focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400"
            >
              <option value="">All Companies</option>
              {companies.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>

            {/* Model selector */}
            <select
              value={selectedModel}
              onChange={(e) => setSelectedModel(e.target.value)}
              disabled={loading || !availableModels.length}
              className="text-xs border border-gray-200 rounded-lg px-3 py-1.5 bg-white text-gray-700 font-medium focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400 disabled:opacity-50"
            >
              <option value="">All Models</option>
              {availableModels.map((m) => (
                <option key={m.model} value={m.model}>{modelLabel(m.model)}</option>
              ))}
            </select>

            {/* Period selector */}
            <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
              {PERIODS.map((p) => (
                <button
                  key={p.key}
                  onClick={() => setPeriod(p.key)}
                  className={cn(
                    'px-3 py-1.5 text-xs font-semibold rounded-md transition-colors',
                    period === p.key
                      ? 'bg-white text-gray-900 shadow-sm'
                      : 'text-gray-500 hover:text-gray-700',
                  )}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>
        }
      />

      <div className="p-4 md:p-7 space-y-6">
        {/* Summary cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <SummaryCard
            label="Total Requests"
            value={loading ? '—' : String(displayTotal.requests)}
            sub={loading ? undefined : `${displayTotal.successRequests} successful`}
          />
          <SummaryCard
            label="Input Tokens"
            value={loading ? '—' : fmtTokens(displayTotal.inputTokens)}
          />
          <SummaryCard
            label="Output Tokens"
            value={loading ? '—' : fmtTokens(displayTotal.outputTokens)}
          />
          <SummaryCard
            label="Total Cost"
            value={loading ? '—' : fmtInr(displayTotal.costInr)}
            sub={loading ? undefined : `${fmtInr(displayTotal.costPerBill)} / bill`}
          />
        </div>

        {/* Per-model table */}
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-100 flex items-center gap-2">
            <Activity className="w-4 h-4 text-teal-500" />
            <span className="text-sm font-semibold text-gray-800">
              {selectedModel ? `${modelLabel(selectedModel)} — Detail` : 'Breakdown by Model'}
            </span>
          </div>

          {error && (
            <div className="p-6 text-sm text-red-600 text-center">{error}</div>
          )}

          {!error && (
            <div className="overflow-x-auto">
              <table className="w-full text-sm border-collapse">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-100">
                    <th className="px-5 py-2.5 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Model</th>
                    <th className="px-4 py-2.5 text-right text-xs font-bold text-gray-500 uppercase tracking-wider">Requests</th>
                    <th className="px-4 py-2.5 text-right text-xs font-bold text-gray-500 uppercase tracking-wider">Success</th>
                    <th className="px-4 py-2.5 text-right text-xs font-bold text-gray-500 uppercase tracking-wider">Input Tokens</th>
                    <th className="px-4 py-2.5 text-right text-xs font-bold text-gray-500 uppercase tracking-wider">Output Tokens</th>
                    <th className="px-4 py-2.5 text-right text-xs font-bold text-gray-500 uppercase tracking-wider">Cost (₹)</th>
                    <th className="px-4 py-2.5 text-right text-xs font-bold text-gray-500 uppercase tracking-wider">Cost / Bill</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && (
                    <tr>
                      <td colSpan={7} className="px-5 py-8 text-center text-sm text-gray-400">Loading…</td>
                    </tr>
                  )}
                  {!loading && !visibleRows.length && (
                    <tr>
                      <td colSpan={7} className="px-5 py-8 text-center text-sm text-gray-400">No data for this period.</td>
                    </tr>
                  )}
                  {!loading && visibleRows.map((m) => {
                    const successPct = m.requests > 0
                      ? Math.round((m.successRequests / m.requests) * 100)
                      : 0
                    return (
                      <tr key={m.model} className="border-b border-gray-50 hover:bg-gray-50/50 transition-colors">
                        <td className="px-5 py-3 font-medium text-gray-900">
                          {modelLabel(m.model)}
                          <span className="ml-1.5 text-xs text-gray-400 font-mono">{m.model}</span>
                        </td>
                        <td className="px-4 py-3 text-right text-gray-700">{m.requests.toLocaleString('en-IN')}</td>
                        <td className="px-4 py-3 text-right">
                          <span className={cn(
                            'text-xs font-semibold px-2 py-0.5 rounded-full',
                            successPct >= 90 ? 'bg-emerald-50 text-emerald-700' :
                            successPct >= 70 ? 'bg-amber-50 text-amber-700' :
                                               'bg-red-50 text-red-700',
                          )}>
                            {successPct}%
                          </span>
                        </td>
                        <td className="px-4 py-3 text-right text-gray-700 font-mono text-xs">{fmtTokens(m.inputTokens)}</td>
                        <td className="px-4 py-3 text-right text-gray-700 font-mono text-xs">{fmtTokens(m.outputTokens)}</td>
                        <td className="px-4 py-3 text-right font-semibold text-gray-900">{fmtInr(m.costInr)}</td>
                        <td className="px-4 py-3 text-right text-gray-600">{fmtInr(m.costPerBill)}</td>
                      </tr>
                    )
                  })}
                </tbody>
                {!loading && visibleRows.length > 1 && (
                  <tfoot className="bg-gray-50 border-t-2 border-gray-200">
                    <tr>
                      <td className="px-5 py-2.5 text-xs font-bold text-gray-700 uppercase tracking-wide">Total</td>
                      <td className="px-4 py-2.5 text-right text-xs font-bold text-gray-700">{displayTotal.requests.toLocaleString('en-IN')}</td>
                      <td className="px-4 py-2.5 text-right">
                        {displayTotal.requests > 0 && (
                          <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">
                            {Math.round((displayTotal.successRequests / displayTotal.requests) * 100)}%
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-2.5 text-right text-xs font-bold text-gray-700 font-mono">{fmtTokens(displayTotal.inputTokens)}</td>
                      <td className="px-4 py-2.5 text-right text-xs font-bold text-gray-700 font-mono">{fmtTokens(displayTotal.outputTokens)}</td>
                      <td className="px-4 py-2.5 text-right text-xs font-bold text-teal-700">{fmtInr(displayTotal.costInr)}</td>
                      <td className="px-4 py-2.5 text-right text-xs font-bold text-gray-700">{fmtInr(displayTotal.costPerBill)}</td>
                    </tr>
                  </tfoot>
                )}
              </table>
            </div>
          )}
        </div>

        <p className="text-xs text-gray-400">
          Gemini Flash: $0.25/1M input · $1.50/1M output. USD → INR at ₹85. Output tokens include thinking (chain-of-thought) tokens billed at the same rate.
        </p>
      </div>
    </>
  )
}
