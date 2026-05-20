import { useState } from 'react'
import { useParams, useNavigate, Navigate } from 'react-router-dom'
import { ArrowLeft, CheckCircle2, ChevronLeft, ChevronRight, BarChart2, X } from 'lucide-react'
import { useAuthStore, useCompanyStore } from '@/store'
import { useReconciliationStore } from '@/store/reconciliationStore'
import type { ReconciliationRow } from '@/store/reconciliationStore'
import { formatCurrency, formatDate } from '@/lib/utils'
import { COMPANY_FEATURES } from '@/types'

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

function sumRows(rows: ReconciliationRow[]) {
  return {
    received: rows.reduce((s, r) => s + (r.debit  ?? 0), 0),
    paid:     rows.reduce((s, r) => s + (r.credit ?? 0), 0),
  }
}

interface SummaryModalProps {
  onClose: () => void
  bankName: string
  booksName: string
  createdAt: string
  missingRows: ReconciliationRow[]
  extraRows:   ReconciliationRow[]
  matchedRows: ReconciliationRow[]
}

function SummaryModal({ onClose, bankName, booksName, createdAt, missingRows, extraRows, matchedRows }: SummaryModalProps) {
  const missingTotals = sumRows(missingRows)
  const extraTotals   = sumRows(extraRows)
  const matchedTotals = sumRows(matchedRows)

  const netDiff = (missingTotals.received - missingTotals.paid) - (extraTotals.received - extraTotals.paid)

  const EntryTable = ({
    rows,
    emptyMsg,
    headerCls,
    headerText,
    badge,
  }: {
    rows: ReconciliationRow[]
    emptyMsg: string
    headerCls: string
    headerText: string
    badge: string
  }) => {
    const totals = sumRows(rows)
    return (
      <div className="mb-5">
        <div className={`flex items-center gap-2 px-3 py-2 rounded-t-lg ${headerCls}`}>
          <span className="text-xs font-bold tracking-wide">{headerText}</span>
          <span className={`ml-auto text-[10px] font-semibold px-2 py-0.5 rounded-full ${badge}`}>
            {rows.length} {rows.length === 1 ? 'entry' : 'entries'}
          </span>
        </div>
        <div className="border border-t-0 border-gray-200 rounded-b-lg overflow-hidden">
          {rows.length === 0 ? (
            <div className="py-4 text-center text-xs text-gray-400 bg-white">{emptyMsg}</div>
          ) : (
            <table className="w-full text-xs border-collapse">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  <th className="px-3 py-2 text-left font-semibold text-gray-500 w-[90px]">Date</th>
                  <th className="px-3 py-2 text-left font-semibold text-gray-500">Description</th>
                  <th className="px-3 py-2 text-right font-semibold text-gray-500 w-[100px]">Received (₹)</th>
                  <th className="px-3 py-2 text-right font-semibold text-gray-500 w-[100px]">Paid (₹)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {rows.map((r, i) => (
                  <tr key={r.id} className={i % 2 === 0 ? 'bg-white' : 'bg-gray-50/40'}>
                    <td className="px-3 py-2 tabular-nums text-gray-500 whitespace-nowrap">{r.date}</td>
                    <td className="px-3 py-2 text-gray-800 max-w-0">
                      <span className="block truncate" title={r.description}>{r.description || '—'}</span>
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-emerald-700 font-medium">
                      {r.debit  != null ? formatCurrency(r.debit)  : <span className="text-gray-300">—</span>}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-red-600 font-medium">
                      {r.credit != null ? formatCurrency(r.credit) : <span className="text-gray-300">—</span>}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="bg-gray-100 border-t border-gray-200 font-semibold">
                  <td colSpan={2} className="px-3 py-2 text-xs text-gray-600">Total</td>
                  <td className="px-3 py-2 text-right tabular-nums text-emerald-700">
                    {totals.received > 0 ? formatCurrency(totals.received) : '—'}
                  </td>
                  <td className="px-3 py-2 text-right tabular-nums text-red-600">
                    {totals.paid > 0 ? formatCurrency(totals.paid) : '—'}
                  </td>
                </tr>
              </tfoot>
            </table>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-3xl max-h-[90vh] flex flex-col">

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 flex-shrink-0">
          <div>
            <div className="flex items-center gap-2">
              <BarChart2 className="w-4 h-4 text-blue-600" />
              <span className="text-sm font-bold text-gray-900">Bank Reconciliation Statement</span>
            </div>
            <p className="text-[11px] text-gray-400 mt-0.5">
              {bankName} <span className="mx-1 text-gray-300">vs</span> {booksName}
              <span className="mx-2 text-gray-300">·</span>{formatDate(createdAt)}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-700 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Scrollable body */}
        <div className="flex-1 overflow-y-auto px-5 py-4">

          {/* Missing from Books */}
          <EntryTable
            rows={missingRows}
            emptyMsg="No missing entries — all bank transactions are recorded in books."
            headerCls="bg-red-50 text-red-800"
            headerText="Missing from Books — recorded in bank, absent in books"
            badge="bg-red-100 text-red-700"
          />

          {/* Extra in Books */}
          <EntryTable
            rows={extraRows}
            emptyMsg="No extra entries — books contain no unmatched transactions."
            headerCls="bg-amber-50 text-amber-800"
            headerText="Extra in Books — recorded in books, absent in bank"
            badge="bg-amber-100 text-amber-700"
          />

          {/* Matched summary row */}
          <div className="mb-5 border border-emerald-200 rounded-lg overflow-hidden">
            <div className="flex items-center gap-2 px-3 py-2 bg-emerald-50 text-emerald-800">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
              <span className="text-xs font-bold tracking-wide">Matched Entries</span>
              <span className="ml-auto text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-700">
                {matchedRows.length} {matchedRows.length === 1 ? 'entry' : 'entries'}
              </span>
            </div>
            <div className="flex items-center gap-6 px-4 py-2.5 bg-white text-xs text-gray-600">
              <span>Total Received: <span className="font-semibold text-emerald-700">{formatCurrency(matchedTotals.received)}</span></span>
              <span>Total Paid: <span className="font-semibold text-red-600">{formatCurrency(matchedTotals.paid)}</span></span>
            </div>
          </div>

          {/* Bank Reconciliation Statement — traditional two-column format */}
          <div className="mb-5 rounded-lg border border-gray-300 overflow-hidden bg-white">
            {/* Title */}
            <div className="text-center py-2.5 border-b border-gray-200">
              <span className="text-sm font-semibold text-gray-800 tracking-wide">Bank Reconciliation Statement</span>
            </div>

            <table className="w-full border-collapse text-sm">
              <colgroup>
                <col className="w-[50%]" />
                <col className="w-[25%]" />
                <col className="w-[25%]" />
              </colgroup>
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="px-4 py-1.5 text-left text-xs font-normal text-gray-400"> </th>
                  <th className="px-4 py-1.5 text-right text-xs font-semibold text-gray-500">₹</th>
                  <th className="px-4 py-1.5 text-right text-xs font-semibold text-gray-500">₹</th>
                </tr>
              </thead>
              <tbody>

                {/* Balance as per Books */}
                <tr>
                  <td className="px-4 pt-3 pb-2 text-sm text-gray-800">
                    Balance as per Books <span className="text-xs text-gray-400">(matched entries)</span>
                  </td>
                  <td />
                  <td className="px-4 pt-3 pb-2 text-right tabular-nums font-medium text-gray-900">
                    {formatCurrency(matchedTotals.received - matchedTotals.paid)}
                  </td>
                </tr>

                {/* Add: Missing from Books */}
                <tr>
                  <td className="px-4 pt-2 pb-1 text-sm font-semibold text-gray-700" colSpan={3}>
                    Add: Missing from Books
                    <span className="ml-1.5 text-[11px] font-normal text-gray-400">
                      (recorded in bank, absent in books)
                    </span>
                  </td>
                </tr>
                {missingRows.length === 0 ? (
                  <tr>
                    <td className="pl-8 pr-4 py-1 text-xs text-gray-400 italic" colSpan={3}>None</td>
                  </tr>
                ) : missingRows.map((r) => {
                  const amt = r.debit ?? r.credit ?? 0
                  const isReceipt = r.debit != null
                  return (
                    <tr key={r.id}>
                      <td className="pl-8 pr-4 py-1 text-xs text-gray-600">
                        <span className="text-gray-400 mr-1.5">{r.date}</span>
                        <span className="truncate">{r.description || '—'}</span>
                      </td>
                      <td className={`px-4 py-1 text-right text-xs tabular-nums ${isReceipt ? 'text-emerald-700' : 'text-red-600'}`}>
                        {formatCurrency(amt)}
                      </td>
                      <td />
                    </tr>
                  )
                })}
                {/* Missing sub-total line */}
                <tr className="border-t border-gray-400">
                  <td />
                  <td />
                  <td className="px-4 py-1.5 text-right tabular-nums font-medium text-gray-900">
                    {formatCurrency(missingTotals.received - missingTotals.paid)}
                  </td>
                </tr>
                {/* Running total after Add */}
                <tr className="border-b border-gray-300">
                  <td />
                  <td />
                  <td className="px-4 pb-2.5 text-right tabular-nums font-medium text-gray-900 border-t border-gray-400">
                    {formatCurrency(
                      (matchedTotals.received - matchedTotals.paid) +
                      (missingTotals.received - missingTotals.paid)
                    )}
                  </td>
                </tr>

                {/* Less: Extra in Books */}
                <tr>
                  <td className="px-4 pt-3 pb-1 text-sm font-semibold text-gray-700" colSpan={3}>
                    Less: Extra in Books
                    <span className="ml-1.5 text-[11px] font-normal text-gray-400">
                      (recorded in books, absent in bank)
                    </span>
                  </td>
                </tr>
                {extraRows.length === 0 ? (
                  <tr>
                    <td className="pl-8 pr-4 py-1 text-xs text-gray-400 italic" colSpan={3}>None</td>
                  </tr>
                ) : extraRows.map((r) => {
                  const amt = r.debit ?? r.credit ?? 0
                  const isReceipt = r.debit != null
                  return (
                    <tr key={r.id}>
                      <td className="pl-8 pr-4 py-1 text-xs text-gray-600">
                        <span className="text-gray-400 mr-1.5">{r.date}</span>
                        <span className="truncate">{r.description || '—'}</span>
                      </td>
                      <td className={`px-4 py-1 text-right text-xs tabular-nums ${isReceipt ? 'text-emerald-700' : 'text-red-600'}`}>
                        {formatCurrency(amt)}
                      </td>
                      <td />
                    </tr>
                  )
                })}
                {/* Extra sub-total line */}
                <tr className="border-t border-gray-400">
                  <td />
                  <td />
                  <td className="px-4 py-1.5 text-right tabular-nums font-medium text-gray-900">
                    {formatCurrency(extraTotals.received - extraTotals.paid)}
                  </td>
                </tr>

                {/* Balance as per Bank Statement */}
                <tr className="border-t-2 border-gray-800">
                  <td className="px-4 py-3 text-sm font-bold text-gray-900">
                    {netDiff === 0 ? '✓ Balance as per Bank Statement' : 'Net Unreconciled Difference'}
                  </td>
                  <td />
                  <td className={`px-4 py-3 text-right text-sm font-bold tabular-nums border-t border-b-2 border-gray-800 ${netDiff === 0 ? 'text-emerald-700' : 'text-amber-600'}`}>
                    {netDiff === 0
                      ? formatCurrency(matchedTotals.received - matchedTotals.paid + missingTotals.received - missingTotals.paid - (extraTotals.received - extraTotals.paid))
                      : <>{formatCurrency(Math.abs(netDiff))}<span className="ml-1.5 text-xs font-normal">({netDiff > 0 ? 'Books short' : 'Books excess'})</span></>
                    }
                  </td>
                </tr>

              </tbody>
            </table>
          </div>
         

        </div>

        {/* Footer */}
        <div className="flex justify-end gap-2 px-5 py-3 border-t border-gray-100 flex-shrink-0 bg-gray-50/60">
          <button
            onClick={onClose}
            className="px-4 py-1.5 text-xs font-medium rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-100 transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  )
}

export default function ReconciliationDetail() {
  const { reportId }           = useParams<{ reportId: string }>()
  const navigate               = useNavigate()
  const { activeCompanyId }    = useAuthStore()
  const { getCompany, companiesLoaded } = useCompanyStore()
  const { getRecord }          = useReconciliationStore()

  const [filter,      setFilter]      = useState<FilterMode>('all')
  const [page,        setPage]        = useState(1)
  const [summaryOpen, setSummaryOpen] = useState(false)

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

  const missingRows = record.rows.filter((r) => r.source === 'bank'  && !r.matched)
  const extraRows   = record.rows.filter((r) => r.source === 'books' && !r.matched)
  // Books-only for matched — use as canonical row; avoids double-counting in summary
  const matchedRows = record.rows.filter((r) => r.source === 'books' && r.matched)

  // Collapse matched pairs: hide the bank side, keep only the books row
  const displayRows = record.rows.filter((r) => !(r.source === 'bank' && r.matched))

  const filteredRows = displayRows.filter((r) => {
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
    if (f === 'all')     return displayRows.length
    if (f === 'matched') return matchedRows.length
    if (f === 'missing') return missingRows.length
    return                      extraRows.length
  }

  const SummaryBtn = () => (
    <button
      onClick={() => setSummaryOpen(true)}
      className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-lg border transition-colors bg-blue-600 text-white border-blue-600 hover:bg-blue-700"
    >
      <BarChart2 className="w-3.5 h-3.5" />
      Summary
    </button>
  )

  return (
    <div className="flex flex-col h-full overflow-hidden">

      {summaryOpen && (
        <SummaryModal
          onClose={() => setSummaryOpen(false)}
          bankName={record.bankName}
          booksName={record.booksName}
          createdAt={record.createdAt}
          missingRows={missingRows}
          extraRows={extraRows}
          matchedRows={matchedRows}
        />
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

      {/* Filter tabs + top Summary button */}
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
        <SummaryBtn />
      </div>

      {/* Table */}
      <div className="flex-1 overflow-y-auto overflow-x-hidden">
        <table className="w-full text-xs border-collapse table-fixed">
          <colgroup>
            <col className="w-[9%]"  />
            <col />
            <col className="w-[18%]" />
            <col className="w-[10%]" />
            <col className="w-[10%]" />
            <col className="w-[16%]" />
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
                    row.matched             ? 'bg-emerald-50/30 hover:bg-emerald-50/60'
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
                      <div className="flex flex-col gap-0.5 min-w-0">
                        {row.source === 'bank' ? (
                          <span className="inline-block px-2 py-0.5 rounded-full text-[10px] font-medium bg-sky-100 text-sky-700 w-fit">From Bank</span>
                        ) : (
                          <span className="inline-block px-2 py-0.5 rounded-full text-[10px] font-medium bg-violet-100 text-violet-700 w-fit">From Books</span>
                        )}
                        {row.matched && row.matchBasis === 'ref' && row.matchToken && (
                          <span className="text-[9px] text-emerald-600 font-mono truncate max-w-[120px]" title={`Matched on UTR/Ref: ${row.matchToken}`}>
                            UTR {row.matchToken.length > 10 ? `…${row.matchToken.slice(-8)}` : row.matchToken}
                          </span>
                        )}
                        {row.matched && row.matchBasis === 'desc' && (
                          <span className="text-[9px] text-blue-500">Desc match</span>
                        )}
                        {row.matched && row.matchBasis === 'amount' && (
                          <span className="text-[9px] text-amber-500">Amt only ⚠</span>
                        )}
                      </div>
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

      {/* Bottom Summary button row */}
      <div className="flex items-center justify-end px-4 py-2 border-t border-gray-100 bg-gray-50/60 flex-shrink-0">
        <SummaryBtn />
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
