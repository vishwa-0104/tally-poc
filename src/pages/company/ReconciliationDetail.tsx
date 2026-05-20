import { useState } from 'react'
import { useParams, useNavigate, Navigate } from 'react-router-dom'
import { ArrowLeft, CheckCircle2, ChevronLeft, ChevronRight, BarChart2, X, Loader2 } from 'lucide-react'
import { useAuthStore, useCompanyStore } from '@/store'
import { useReconciliationStore } from '@/store/reconciliationStore'
import type { ReconciliationRow } from '@/store/reconciliationStore'
import { formatCurrency, formatDate } from '@/lib/utils'
import { COMPANY_FEATURES } from '@/types'
import { api } from '@/lib/api'

const PAGE_SIZE = 15

type FilterMode = 'all' | 'matched' | 'missing' | 'extra'

const FILTERS: { label: string; value: FilterMode }[] = [
  { label: 'All',              value: 'all'     },
  { label: 'Matched',          value: 'matched' },
  { label: 'Missing from Books', value: 'missing' },
  { label: 'Extra in Books',   value: 'extra'   },
]

function rowStatus(row: ReconciliationRow): { label: string; cls: string } {
  if (row.matched)                           return { label: 'Matched',           cls: 'bg-emerald-100 text-emerald-700' }
  if (row.source === 'bank' && !row.matched) return { label: 'Missing from Books', cls: 'bg-red-100 text-red-700'         }
  return                                            { label: 'Extra in Books',     cls: 'bg-amber-100 text-amber-700'    }
}

export default function ReconciliationDetail() {
  const { reportId }           = useParams<{ reportId: string }>()
  const navigate               = useNavigate()
  const { activeCompanyId }    = useAuthStore()
  const { getCompany, companiesLoaded } = useCompanyStore()
  const { getRecord }          = useReconciliationStore()

  const [filter,         setFilter]         = useState<FilterMode>('all')
  const [page,           setPage]           = useState(1)
  const [summaryOpen,    setSummaryOpen]    = useState(false)
  const [summaryLoading, setSummaryLoading] = useState(false)
  const [summaryText,    setSummaryText]    = useState<string | null>(null)
  const [summaryError,   setSummaryError]   = useState<string | null>(null)

  const companyId = activeCompanyId ?? ''
  const company   = getCompany(companyId) ?? null

  const hasBankReconcile = (company?.features ?? []).some(
    (f) => f.feature === COMPANY_FEATURES.BANK_RECONCILE && f.enabled,
  )

  if (!companiesLoaded) return null
  if (!hasBankReconcile) return <Navigate to="/company" replace />

  const record = getRecord(reportId ?? '')

  if (!record) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-3 text-gray-400">
        <p className="text-sm">Reconciliation report not found.</p>
        <button onClick={() => navigate('/company/reconcile')} className="text-xs text-teal-600 hover:underline">
          ← Back to Reconciliation
        </button>
      </div>
    )
  }

  const filteredRows = record.rows.filter((r) => {
    if (filter === 'matched') return r.matched
    if (filter === 'missing') return r.source === 'bank'  && !r.matched
    if (filter === 'extra')   return r.source === 'books' && !r.matched
    return true
  })

  const totalPages = Math.max(1, Math.ceil(filteredRows.length / PAGE_SIZE))
  const pageRows   = filteredRows.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)
  const start      = (page - 1) * PAGE_SIZE + 1
  const end        = Math.min(page * PAGE_SIZE, filteredRows.length)

  const setFilterAndReset = (f: FilterMode) => { setFilter(f); setPage(1) }

  const filterCount = (f: FilterMode) => {
    if (f === 'all')     return record.rows.length
    if (f === 'matched') return record.rows.filter((r) => r.matched).length
    if (f === 'missing') return record.rows.filter((r) => r.source === 'bank'  && !r.matched).length
    return                      record.rows.filter((r) => r.source === 'books' && !r.matched).length
  }

  const handleSummary = async () => {
    setSummaryOpen(true)
    if (summaryText !== null) return
    setSummaryLoading(true)
    setSummaryError(null)
    try {
      const missingFromBooks = record.rows.filter((r) => r.source === 'bank'  && !r.matched)
      const extraInBooks     = record.rows.filter((r) => r.source === 'books' && !r.matched)
      const { data } = await api.post('/reconcile/analyze', {
        companyId,
        bankName:       record.bankName,
        booksName:      record.booksName,
        missingFromBooks,
        extraInBooks,
      })
      setSummaryText(data.summary ?? '')
    } catch {
      setSummaryError('Failed to generate summary. Please try again.')
    } finally {
      setSummaryLoading(false)
    }
  }

  const SummaryButton = () => (
    <button
      onClick={handleSummary}
      className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-lg border transition-colors bg-blue-600 text-white border-blue-600 hover:bg-blue-700"
    >
      <BarChart2 className="w-3.5 h-3.5" />
      Summary
    </button>
  )

  return (
    <div className="flex flex-col h-full overflow-hidden">

      {/* AI Summary Modal */}
      {summaryOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[80vh] flex flex-col">
            {/* Modal header */}
            <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 flex-shrink-0">
              <div className="flex items-center gap-2">
                <BarChart2 className="w-4 h-4 text-blue-600" />
                <span className="text-sm font-semibold text-gray-900">Reconciliation Summary</span>
                <span className="text-xs text-gray-400 ml-1">{record.bankName} vs {record.booksName}</span>
              </div>
              <button
                onClick={() => setSummaryOpen(false)}
                className="p-1.5 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-700 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Modal body */}
            <div className="flex-1 overflow-y-auto px-5 py-4">
              {summaryLoading && (
                <div className="flex flex-col items-center justify-center py-16 gap-3 text-gray-400">
                  <Loader2 className="w-8 h-8 animate-spin text-blue-500" />
                  <p className="text-sm">Analyzing discrepancies…</p>
                </div>
              )}
              {summaryError && !summaryLoading && (
                <div className="flex flex-col items-center justify-center py-10 gap-3">
                  <p className="text-sm text-red-600">{summaryError}</p>
                  <button
                    onClick={() => { setSummaryText(null); handleSummary() }}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    Retry
                  </button>
                </div>
              )}
              {summaryText !== null && !summaryLoading && (
                <div className="prose prose-sm max-w-none text-gray-800 whitespace-pre-wrap text-sm leading-relaxed">
                  {summaryText}
                </div>
              )}
            </div>

            {/* Modal footer */}
            <div className="flex justify-end px-5 py-3 border-t border-gray-100 flex-shrink-0">
              <button
                onClick={() => setSummaryOpen(false)}
                className="px-4 py-1.5 text-xs font-medium rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Top bar */}
      <div className="flex items-center gap-3 px-6 py-3 border-b border-gray-100 bg-white flex-shrink-0">
        <button
          onClick={() => navigate('/company/reconcile')}
          className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-gray-800 transition-colors"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          Reconciliation
        </button>
        <span className="text-gray-300">|</span>
        <div className="flex items-center gap-2 min-w-0 flex-1">
          <h1 className="text-sm font-bold text-gray-900 truncate">
            {record.bankName} <span className="text-gray-400 font-normal">vs</span> {record.booksName}
          </h1>
          <span className="text-xs text-gray-400 hidden sm:inline flex-shrink-0">· {formatDate(record.createdAt)}</span>
        </div>

        {/* Summary chips */}
        <div className="hidden md:flex items-center gap-2 flex-shrink-0">
          <span className="flex items-center gap-1 text-[11px] text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-full px-2 py-0.5">
            <CheckCircle2 className="w-3 h-3" /> {record.stats.matched} matched
          </span>
          {record.stats.missingFromBooks > 0 && (
            <span className="text-[11px] text-red-700 bg-red-50 border border-red-200 rounded-full px-2 py-0.5">
              {record.stats.missingFromBooks} missing
            </span>
          )}
          {record.stats.extraInBooks > 0 && (
            <span className="text-[11px] text-amber-700 bg-amber-50 border border-amber-200 rounded-full px-2 py-0.5">
              {record.stats.extraInBooks} extra
            </span>
          )}
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex items-center gap-1 px-4 py-2 border-b border-gray-100 bg-gray-50/60 flex-shrink-0">
        {FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => setFilterAndReset(f.value)}
            className={`px-3 py-1 text-xs rounded-full font-medium border transition-colors ${
              filter === f.value
                ? f.value === 'matched' ? 'bg-emerald-100 border-emerald-300 text-emerald-700'
                : f.value === 'missing' ? 'bg-red-100 border-red-300 text-red-700'
                : f.value === 'extra'   ? 'bg-amber-100 border-amber-300 text-amber-700'
                :                        'bg-teal-100 border-teal-300 text-teal-700'
                : 'bg-white border-gray-200 text-gray-400 hover:text-gray-600'
            }`}
          >
            {f.label}
            <span className="ml-1 opacity-60">({filterCount(f.value)})</span>
          </button>
        ))}
        <span className="ml-auto text-xs text-gray-400 mr-2">
          {filteredRows.length} row{filteredRows.length !== 1 ? 's' : ''}
        </span>
        <SummaryButton />
      </div>

      {/* Table */}
      <div className="flex-1 overflow-y-auto overflow-x-hidden">
        <table className="w-full text-xs border-collapse table-fixed">
          <colgroup>
            <col className="w-[9%]"  /> {/* date */}
            <col />                     {/* description */}
            <col className="w-[18%]" /> {/* source + tick */}
            <col className="w-[10%]" /> {/* received */}
            <col className="w-[10%]" /> {/* paid */}
            <col className="w-[16%]" /> {/* status */}
          </colgroup>
          <thead className="sticky top-0 z-10 bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-3 py-2.5 text-left font-semibold text-gray-600">Date</th>
              <th className="px-3 py-2.5 text-left font-semibold text-gray-600">Description</th>
              <th className="px-3 py-2.5 text-left font-semibold text-gray-600">Source</th>
              <th className="px-2 py-2.5 text-right font-semibold text-gray-600">Received</th>
              <th className="px-2 py-2.5 text-right font-semibold text-gray-600">Paid</th>
              <th className="px-3 py-2.5 text-center font-semibold text-gray-600">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {pageRows.map((row) => {
              const { label, cls } = rowStatus(row)
              return (
                <tr
                  key={row.id}
                  className={
                    row.matched          ? 'bg-emerald-50/30 hover:bg-emerald-50/60'
                    : row.source === 'bank' ? 'bg-red-50/30 hover:bg-red-50/60'
                    :                        'bg-amber-50/30 hover:bg-amber-50/60'
                  }
                >
                  <td className="px-3 py-2.5 text-gray-600 tabular-nums whitespace-nowrap">{row.date}</td>
                  <td className="px-3 py-2.5 text-gray-800 max-w-0">
                    <span className="block truncate" title={row.description}>{row.description || '—'}</span>
                  </td>
                  <td className="px-3 py-2.5">
                    <div className="flex items-center gap-1.5">
                      {row.matched
                        ? <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 flex-shrink-0" />
                        : <span className="w-3.5 flex-shrink-0 inline-block" />
                      }
                      {row.source === 'bank' ? (
                        <span className="inline-block px-2 py-0.5 rounded-full text-[10px] font-medium bg-sky-100 text-sky-700">From Bank</span>
                      ) : (
                        <span className="inline-block px-2 py-0.5 rounded-full text-[10px] font-medium bg-violet-100 text-violet-700">From Books</span>
                      )}
                    </div>
                  </td>
                  <td className="px-2 py-2.5 text-right tabular-nums text-emerald-700"
                    title={row.debit != null ? formatCurrency(row.debit) : undefined}>
                    {row.debit != null ? formatCurrency(row.debit) : <span className="text-gray-300">—</span>}
                  </td>
                  <td className="px-2 py-2.5 text-right tabular-nums text-red-600"
                    title={row.credit != null ? formatCurrency(row.credit) : undefined}>
                    {row.credit != null ? formatCurrency(row.credit) : <span className="text-gray-300">—</span>}
                  </td>
                  <td className="px-3 py-2.5 text-center">
                    <span className={`inline-block px-2 py-0.5 rounded-full text-[10px] font-medium ${cls}`}>
                      {label}
                    </span>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* Between table and footer: Summary button row */}
      <div className="flex items-center justify-end px-4 py-2 border-t border-gray-100 bg-gray-50/60 flex-shrink-0">
        <SummaryButton />
      </div>

      {/* Footer: pagination */}
      <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-white flex-shrink-0">
        <span className="text-xs text-gray-400">
          {filteredRows.length === 0 ? 'No rows' : `Showing ${start}–${end} of ${filteredRows.length}`}
        </span>
        {totalPages > 1 && (
          <div className="flex items-center gap-1">
            <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1}
              className="p-1 rounded hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed">
              <ChevronLeft className="w-4 h-4 text-gray-500" />
            </button>
            {Array.from({ length: totalPages }, (_, i) => i + 1)
              .filter((p) => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
              .reduce<(number | '...')[]>((acc, p, i, arr) => {
                if (i > 0 && (p as number) - (arr[i - 1] as number) > 1) acc.push('...')
                acc.push(p)
                return acc
              }, [])
              .map((p, i) =>
                p === '...' ? (
                  <span key={`e${i}`} className="px-1 text-xs text-gray-400">…</span>
                ) : (
                  <button key={p} onClick={() => setPage(p as number)}
                    className={`w-6 h-6 rounded text-xs font-medium transition-colors ${
                      page === p ? 'bg-teal-600 text-white' : 'hover:bg-gray-100 text-gray-600'
                    }`}>
                    {p}
                  </button>
                )
              )}
            <button onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages}
              className="p-1 rounded hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed">
              <ChevronRight className="w-4 h-4 text-gray-500" />
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
