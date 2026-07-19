import { useState } from 'react'
import { useParams, useNavigate, Navigate } from 'react-router-dom'
import { ArrowLeft, CheckCircle2, ChevronLeft, ChevronRight, BarChart2, X } from 'lucide-react'
import { useAuthStore, useCompanyStore } from '@/store'
import { useVendorReconciliationStore } from '@/store/vendorReconciliationStore'
import type { VendorReconciliationRow } from '@/store/vendorReconciliationStore'
import { cn, formatCurrency, formatDate } from '@/lib/utils'
import { COMPANY_FEATURES } from '@/types'
import { VendorMissingEntriesModal } from '@/components/company/VendorMissingEntriesModal'
import { CompanyPageHeader } from '@/shadcn/components/company-page-header'
import { Button } from '@/shadcn/components/ui/button'
import { Badge } from '@/shadcn/components/ui/badge'

const PAGE_SIZE = 15

type FilterMode = 'all' | 'matched' | 'missing' | 'extra'

const FILTERS: { label: string; value: FilterMode }[] = [
  { label: 'All',                value: 'all'     },
  { label: 'Matched',            value: 'matched' },
  { label: 'Missing from Books', value: 'missing' },
  { label: 'Extra in Books',     value: 'extra'   },
]

function rowStatus(row: VendorReconciliationRow): { label: string; cls: string } {
  if (row.matched)                           return { label: 'Matched',           cls: 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400' }
  if (row.source === 'bank' && !row.matched) return { label: 'Missing from Books', cls: 'bg-red-500/15 text-red-700 dark:text-red-400'             }
  return                                            { label: 'Extra in Books',     cls: 'bg-amber-500/15 text-amber-700 dark:text-amber-400'       }
}

function sumRows(rows: VendorReconciliationRow[]) {
  return {
    received: rows.reduce((s, r) => s + (r.debit  ?? 0), 0),
    paid:     rows.reduce((s, r) => s + (r.credit ?? 0), 0),
  }
}

interface SummaryModalProps {
  onClose:     () => void
  recordId:    string
  companyId:   string
  bankName:    string
  booksName:   string
  createdAt:   string
  missingRows: VendorReconciliationRow[]
  extraRows:   VendorReconciliationRow[]
  matchedRows: VendorReconciliationRow[]
}

function SummaryModal({ onClose, recordId, companyId, bankName, booksName, createdAt, missingRows, extraRows, matchedRows }: SummaryModalProps) {
  const [missingEntriesOpen, setMissingEntriesOpen] = useState(false)
  const matchedTotals = sumRows(matchedRows)
  const extraTotals   = sumRows(extraRows)

  const booksClosing = (matchedTotals.received - matchedTotals.paid) + (extraTotals.received - extraTotals.paid)

  const missingReceipts      = missingRows.filter((r) => r.debit  != null)
  const missingPayments      = missingRows.filter((r) => r.credit != null)
  const missingReceiptsTotal = missingReceipts.reduce((s, r) => s + (r.debit  ?? 0), 0)
  const missingPaymentsTotal = missingPayments.reduce((s, r) => s + (r.credit ?? 0), 0)

  const extraReceipts      = extraRows.filter((r) => r.debit  != null)
  const extraPayments      = extraRows.filter((r) => r.credit != null)
  const extraReceiptsTotal = extraReceipts.reduce((s, r) => s + (r.debit  ?? 0), 0)
  const extraPaymentsTotal = extraPayments.reduce((s, r) => s + (r.credit ?? 0), 0)

  const afterAddReceipts  = booksClosing      + missingReceiptsTotal
  const afterLessPayments = afterAddReceipts  - missingPaymentsTotal
  const afterLessExtra    = afterLessPayments - extraReceiptsTotal
  const vendorBalance     = afterLessExtra    + extraPaymentsTotal

  const EntryTable = ({
    rows,
    emptyMsg,
    headerCls,
    headerText,
    badge,
  }: {
    rows: VendorReconciliationRow[]
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
        <div className="border border-t-0 border-border rounded-b-lg overflow-hidden">
          {rows.length === 0 ? (
            <div className="py-4 text-center text-xs text-muted-foreground bg-card">{emptyMsg}</div>
          ) : (
            <table className="w-full text-xs border-collapse">
              <thead>
                <tr className="bg-muted border-b border-border">
                  <th className="px-3 py-2 text-left font-semibold text-muted-foreground w-[90px]">Date</th>
                  <th className="px-3 py-2 text-left font-semibold text-muted-foreground">Description</th>
                  <th className="px-3 py-2 text-right font-semibold text-muted-foreground w-[100px]">Received (₹)</th>
                  <th className="px-3 py-2 text-right font-semibold text-muted-foreground w-[100px]">Paid (₹)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {rows.map((r, i) => (
                  <tr key={r.id} className={i % 2 === 0 ? 'bg-card' : 'bg-muted/40'}>
                    <td className="px-3 py-2 tabular-nums text-muted-foreground whitespace-nowrap">{r.date}</td>
                    <td className="px-3 py-2 text-foreground max-w-0">
                      <span className="block truncate" title={r.description}>{r.description || '—'}</span>
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-emerald-600 dark:text-emerald-400 font-medium">
                      {r.debit  != null ? formatCurrency(r.debit)  : <span className="text-muted-foreground/50">—</span>}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums text-red-600 dark:text-red-400 font-medium">
                      {r.credit != null ? formatCurrency(r.credit) : <span className="text-muted-foreground/50">—</span>}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="bg-muted border-t border-border font-semibold">
                  <td colSpan={2} className="px-3 py-2 text-xs text-muted-foreground">Total</td>
                  <td className="px-3 py-2 text-right tabular-nums text-emerald-600 dark:text-emerald-400">
                    {totals.received > 0 ? formatCurrency(totals.received) : '—'}
                  </td>
                  <td className="px-3 py-2 text-right tabular-nums text-red-600 dark:text-red-400">
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
      <div className="bg-card text-card-foreground border border-border rounded-xl shadow-2xl w-full max-w-3xl max-h-[90vh] flex flex-col">

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border flex-shrink-0">
          <div>
            <div className="flex items-center gap-2">
              <BarChart2 className="w-4 h-4 text-primary" />
              <span className="text-sm font-bold text-foreground">Vendor Reconciliation Statement</span>
            </div>
            <p className="text-[11px] text-muted-foreground mt-0.5">
              {bankName} <span className="mx-1">vs</span> {booksName}
              <span className="mx-2">·</span>{formatDate(createdAt)}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded hover:bg-muted text-muted-foreground hover:text-foreground transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Scrollable body */}
        <div className="flex-1 overflow-y-auto px-5 py-4">

          <EntryTable
            rows={missingRows}
            emptyMsg="No missing entries — all my ledger transactions are recorded in vendor ledger."
            headerCls="bg-red-500/15 text-red-700 dark:text-red-400"
            headerText="Missing from Books — recorded in my ledger, absent in vendor ledger"
            badge="bg-red-500/20 text-red-700 dark:text-red-400"
          />

          <EntryTable
            rows={extraRows}
            emptyMsg="No extra entries — vendor ledger contains no unmatched transactions."
            headerCls="bg-amber-500/15 text-amber-700 dark:text-amber-400"
            headerText="Extra in Books — recorded in vendor ledger, absent in my ledger"
            badge="bg-amber-500/20 text-amber-700 dark:text-amber-400"
          />

          <div className="mb-5 border border-emerald-500/30 rounded-lg overflow-hidden">
            <div className="flex items-center gap-2 px-3 py-2 bg-emerald-500/15 text-emerald-700 dark:text-emerald-400">
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span className="text-xs font-bold tracking-wide">Matched Entries</span>
              <span className="ml-auto text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-500/20">
                {matchedRows.length} {matchedRows.length === 1 ? 'entry' : 'entries'}
              </span>
            </div>
            <div className="flex items-center gap-6 px-4 py-2.5 bg-card text-xs text-muted-foreground">
              <span>Total Received: <span className="font-semibold text-emerald-600 dark:text-emerald-400">{formatCurrency(matchedTotals.received)}</span></span>
              <span>Total Paid: <span className="font-semibold text-red-600 dark:text-red-400">{formatCurrency(matchedTotals.paid)}</span></span>
            </div>
          </div>

          {/* Vendor Reconciliation Statement */}
          <div className="mb-5 rounded-lg border border-border overflow-hidden bg-card">
            <div className="text-center py-2.5 border-b border-border">
              <span className="text-sm font-semibold text-foreground tracking-wide">Vendor Reconciliation Statement</span>
            </div>

            <table className="w-full border-collapse table-fixed text-sm">
              <colgroup>
                <col />
                <col style={{ width: 120 }} />
                <col style={{ width: 140 }} />
              </colgroup>
              <thead>
                <tr className="border-b border-border">
                  <th className="px-4 py-1.5 text-left text-xs font-normal text-muted-foreground"> </th>
                  <th className="px-3 py-1.5 text-right text-xs font-semibold text-muted-foreground">₹</th>
                  <th className="px-4 py-1.5 text-right text-xs font-semibold text-muted-foreground">₹</th>
                </tr>
              </thead>
              <tbody>

                <tr className="border-b border-border">
                  <td className="px-4 py-2.5 text-sm text-foreground">
                    Balance as per Books <span className="text-xs text-muted-foreground">(closing balance)</span>
                  </td>
                  <td />
                  <td className="px-4 py-2.5 text-right tabular-nums font-semibold text-foreground whitespace-nowrap">
                    {formatCurrency(booksClosing)}
                  </td>
                </tr>

                {missingReceipts.length > 0 && <>
                  <tr>
                    <td className="px-4 pt-3 pb-1 text-sm font-semibold text-foreground" colSpan={3}>
                      Add: Missing Receipts
                      <span className="ml-1.5 text-[11px] font-normal text-muted-foreground">(credit side — book will receive amount)</span>
                    </td>
                  </tr>
                  {missingReceipts.map((r) => (
                    <tr key={r.id}>
                      <td className="pl-8 pr-2 py-1 text-xs text-muted-foreground max-w-0">
                        <div className="flex items-baseline gap-2 min-w-0">
                          <span className="text-muted-foreground whitespace-nowrap flex-shrink-0">{r.date}</span>
                          <span className="truncate">{r.description || '—'}</span>
                        </div>
                      </td>
                      <td className="px-3 py-1 text-right text-xs tabular-nums whitespace-nowrap font-medium text-emerald-600 dark:text-emerald-400">
                        {formatCurrency(r.debit ?? 0)}
                      </td>
                      <td />
                    </tr>
                  ))}
                  <tr className="border-b border-border">
                    <td />
                    <td className="px-3 py-1 text-right tabular-nums text-xs font-semibold text-foreground border-t border-border whitespace-nowrap">
                      {formatCurrency(missingReceiptsTotal)}
                    </td>
                    <td className="px-4 py-1 text-right tabular-nums font-semibold text-foreground whitespace-nowrap border-t border-border">
                      {formatCurrency(afterAddReceipts)}
                    </td>
                  </tr>
                </>}

                {missingPayments.length > 0 && <>
                  <tr>
                    <td className="px-4 pt-3 pb-1 text-sm font-semibold text-foreground" colSpan={3}>
                      Less: Missing Payments
                      <span className="ml-1.5 text-[11px] font-normal text-muted-foreground">(debit side — reduces book balance)</span>
                    </td>
                  </tr>
                  {missingPayments.map((r) => (
                    <tr key={r.id}>
                      <td className="pl-8 pr-2 py-1 text-xs text-muted-foreground max-w-0">
                        <div className="flex items-baseline gap-2 min-w-0">
                          <span className="text-muted-foreground whitespace-nowrap flex-shrink-0">{r.date}</span>
                          <span className="truncate">{r.description || '—'}</span>
                        </div>
                      </td>
                      <td className="px-3 py-1 text-right text-xs tabular-nums whitespace-nowrap font-medium text-red-600 dark:text-red-400">
                        {formatCurrency(r.credit ?? 0)}
                      </td>
                      <td />
                    </tr>
                  ))}
                  <tr className="border-b border-border">
                    <td />
                    <td className="px-3 py-1 text-right tabular-nums text-xs font-semibold text-foreground border-t border-border whitespace-nowrap">
                      {formatCurrency(missingPaymentsTotal)}
                    </td>
                    <td className="px-4 py-1 text-right tabular-nums font-semibold text-foreground whitespace-nowrap border-t border-border">
                      {formatCurrency(afterLessPayments)}
                    </td>
                  </tr>
                </>}

                {extraReceipts.length > 0 && <>
                  <tr>
                    <td className="px-4 pt-3 pb-1 text-sm font-semibold text-foreground" colSpan={3}>
                      Less: Extra Receipts in Books
                      <span className="ml-1.5 text-[11px] font-normal text-muted-foreground">(credit side — to be reversed)</span>
                    </td>
                  </tr>
                  {extraReceipts.map((r) => (
                    <tr key={r.id}>
                      <td className="pl-8 pr-2 py-1 text-xs text-muted-foreground max-w-0">
                        <div className="flex items-baseline gap-2 min-w-0">
                          <span className="text-muted-foreground whitespace-nowrap flex-shrink-0">{r.date}</span>
                          <span className="truncate">{r.description || '—'}</span>
                        </div>
                      </td>
                      <td className="px-3 py-1 text-right text-xs tabular-nums whitespace-nowrap font-medium text-red-600 dark:text-red-400">
                        {formatCurrency(r.debit ?? 0)}
                      </td>
                      <td />
                    </tr>
                  ))}
                  <tr className="border-b border-border">
                    <td />
                    <td className="px-3 py-1 text-right tabular-nums text-xs font-semibold text-foreground border-t border-border whitespace-nowrap">
                      {formatCurrency(extraReceiptsTotal)}
                    </td>
                    <td className="px-4 py-1 text-right tabular-nums font-semibold text-foreground whitespace-nowrap border-t border-border">
                      {formatCurrency(afterLessExtra)}
                    </td>
                  </tr>
                </>}

                {extraPayments.length > 0 && <>
                  <tr>
                    <td className="px-4 pt-3 pb-1 text-sm font-semibold text-foreground" colSpan={3}>
                      Add: Extra Payments in Books
                      <span className="ml-1.5 text-[11px] font-normal text-muted-foreground">(debit side — to be reversed)</span>
                    </td>
                  </tr>
                  {extraPayments.map((r) => (
                    <tr key={r.id}>
                      <td className="pl-8 pr-2 py-1 text-xs text-muted-foreground max-w-0">
                        <div className="flex items-baseline gap-2 min-w-0">
                          <span className="text-muted-foreground whitespace-nowrap flex-shrink-0">{r.date}</span>
                          <span className="truncate">{r.description || '—'}</span>
                        </div>
                      </td>
                      <td className="px-3 py-1 text-right text-xs tabular-nums whitespace-nowrap font-medium text-emerald-600 dark:text-emerald-400">
                        {formatCurrency(r.credit ?? 0)}
                      </td>
                      <td />
                    </tr>
                  ))}
                  <tr className="border-b border-border">
                    <td />
                    <td className="px-3 py-1 text-right tabular-nums text-xs font-semibold text-foreground border-t border-border whitespace-nowrap">
                      {formatCurrency(extraPaymentsTotal)}
                    </td>
                    <td className="px-4 py-1 text-right tabular-nums font-semibold text-foreground whitespace-nowrap border-t border-border">
                      {formatCurrency(vendorBalance)}
                    </td>
                  </tr>
                </>}

                <tr className="border-t-2 border-foreground/80 bg-foreground text-background">
                  <td className="px-4 py-3 text-sm font-bold">
                    Balance as per Vendor Statement
                  </td>
                  <td />
                  <td className="px-4 py-3 text-right text-sm font-bold tabular-nums whitespace-nowrap">
                    {formatCurrency(vendorBalance)}
                  </td>
                </tr>

              </tbody>
            </table>
          </div>

        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-5 py-3 border-t border-border flex-shrink-0 bg-muted/40">
          {missingRows.length > 0 ? (
            <button
              onClick={() => setMissingEntriesOpen(true)}
              className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-lg border border-primary/30 text-primary bg-primary/10 hover:bg-primary/15 transition-colors"
            >
              Add missing entries in Book
              <span className="ml-1 px-1.5 py-0.5 rounded-full bg-primary/20 text-primary text-[10px] font-bold">
                {missingRows.length}
              </span>
            </button>
          ) : <span />}
          <Button variant="outline" size="sm" onClick={onClose}>
            Close
          </Button>
        </div>
      </div>

      {missingEntriesOpen && (
        <VendorMissingEntriesModal
          recordId={recordId}
          companyId={companyId}
          missingRows={missingRows}
          onClose={() => setMissingEntriesOpen(false)}
        />
      )}
    </div>
  )
}

export default function VendorReconciliationDetail() {
  const { reportId }                    = useParams<{ reportId: string }>()
  const navigate                        = useNavigate()
  const { activeCompanyId }             = useAuthStore()
  const { getCompany, companiesLoaded } = useCompanyStore()
  const { getRecord }                   = useVendorReconciliationStore()

  const [filter,      setFilter]      = useState<FilterMode>('all')
  const [page,        setPage]        = useState(1)
  const [summaryOpen, setSummaryOpen] = useState(false)

  const companyId = activeCompanyId ?? ''
  const company   = getCompany(companyId) ?? null

  const hasVendorReconcile = (company?.features ?? []).some(
    (f) => f.feature === COMPANY_FEATURES.VENDOR_RECONCILE && f.enabled,
  )

  if (!companiesLoaded) return null
  if (!hasVendorReconcile) return <Navigate to="/company" replace />

  const record = getRecord(reportId ?? '')

  if (!record) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-3 text-muted-foreground">
        <p className="text-sm">Vendor reconciliation report not found.</p>
        <button onClick={() => navigate('/company/vendor-reconcile')} className="text-xs text-primary hover:underline">
          ← Back to Vendor Reconciliation
        </button>
      </div>
    )
  }

  const missingRows = record.rows.filter((r) => r.source === 'bank'  && !r.matched)
  const extraRows   = record.rows.filter((r) => r.source === 'books' && !r.matched)
  const matchedRows = record.rows.filter((r) => r.source === 'books' && r.matched)

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
    <Button size="sm" onClick={() => setSummaryOpen(true)}>
      <BarChart2 className="w-3.5 h-3.5" />
      Summary
    </Button>
  )

  const filterPillClass = (f: FilterMode) => {
    const active = filter === f
    if (!active) return 'bg-muted border-transparent text-muted-foreground hover:text-foreground'
    if (f === 'matched') return 'bg-emerald-500/15 border-emerald-500/30 text-emerald-700 dark:text-emerald-400'
    if (f === 'missing') return 'bg-red-500/15 border-red-500/30 text-red-700 dark:text-red-400'
    if (f === 'extra')   return 'bg-amber-500/15 border-amber-500/30 text-amber-700 dark:text-amber-400'
    return 'bg-primary/15 border-primary/30 text-primary'
  }

  return (
    <div className="flex flex-col h-full overflow-hidden">

      {summaryOpen && (
        <SummaryModal
          onClose={() => setSummaryOpen(false)}
          recordId={record.id}
          companyId={companyId}
          bankName={record.bankName}
          booksName={record.booksName}
          createdAt={record.createdAt}
          missingRows={missingRows}
          extraRows={extraRows}
          matchedRows={matchedRows}
        />
      )}

      <CompanyPageHeader
        title="Vendor Reconciliation"
        subtitle={`${record.bankName} vs ${record.booksName} · ${formatDate(record.createdAt)}`}
        actions={
          <Button variant="outline" size="sm" onClick={() => navigate('/company/vendor-reconcile')}>
            <ArrowLeft className="w-3.5 h-3.5" />
            Back
          </Button>
        }
      />

      {/* Stats + filter tabs */}
      <div className="flex flex-wrap items-center gap-2 px-4 py-2.5 border-b border-border bg-muted/40 flex-shrink-0">
        <span className="flex items-center gap-1 text-[11px] text-emerald-700 dark:text-emerald-400 bg-emerald-500/15 border border-emerald-500/30 rounded-full px-2 py-0.5">
          <CheckCircle2 className="w-3 h-3" /> {record.stats.matched} matched
        </span>
        {record.stats.missingFromBooks > 0 && (
          <span className="text-[11px] text-red-700 dark:text-red-400 bg-red-500/15 border border-red-500/30 rounded-full px-2 py-0.5">
            {record.stats.missingFromBooks} missing
          </span>
        )}
        {record.stats.extraInBooks > 0 && (
          <span className="text-[11px] text-amber-700 dark:text-amber-400 bg-amber-500/15 border border-amber-500/30 rounded-full px-2 py-0.5">
            {record.stats.extraInBooks} extra
          </span>
        )}

        <span className="mx-1 h-4 w-px self-center bg-border" />

        {FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => setFilterAndReset(f.value)}
            className={cn('px-3 py-1 text-xs rounded-full font-medium border transition-colors', filterPillClass(f.value))}
          >
            {f.label}
            <span className="ml-1 opacity-60">({filterCount(f.value)})</span>
          </button>
        ))}
        <span className="ml-auto text-xs text-muted-foreground mr-2">
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
          <thead className="sticky top-0 z-10 bg-muted border-b border-border">
            <tr>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Date</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Description</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Source</th>
              <th className="px-2 py-2.5 text-right font-semibold text-muted-foreground">Received</th>
              <th className="px-2 py-2.5 text-right font-semibold text-muted-foreground">Paid</th>
              <th className="px-3 py-2.5 text-center font-semibold text-muted-foreground">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {pageRows.map((row) => {
              const { label, cls } = rowStatus(row)
              return (
                <tr
                  key={row.id}
                  className={
                    row.matched             ? 'bg-emerald-500/5 hover:bg-emerald-500/10'
                    : row.source === 'bank' ? 'bg-red-500/5 hover:bg-red-500/10'
                    :                        'bg-amber-500/5 hover:bg-amber-500/10'
                  }
                >
                  <td className="px-3 py-2.5 text-muted-foreground tabular-nums whitespace-nowrap">{row.date}</td>
                  <td className="px-3 py-2.5 text-foreground max-w-0">
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
                          <Badge variant="secondary" className="w-fit">My Ledger</Badge>
                        ) : (
                          <Badge variant="outline" className="w-fit border-primary/30 text-primary">Vendor Ledger</Badge>
                        )}
                        {row.matched && row.matchBasis === 'ref' && row.matchToken && (
                          <span className="text-[9px] text-emerald-600 dark:text-emerald-400 font-mono truncate max-w-[120px]" title={`Matched on UTR/Ref: ${row.matchToken}`}>
                            UTR {row.matchToken.length > 10 ? `…${row.matchToken.slice(-8)}` : row.matchToken}
                          </span>
                        )}
                        {row.matched && row.matchBasis === 'desc' && (
                          <span className="text-[9px] text-blue-500 dark:text-blue-400">Desc match</span>
                        )}
                        {row.matched && row.matchBasis === 'amount' && (
                          <span className="text-[9px] text-amber-500 dark:text-amber-400">Amt only ⚠</span>
                        )}
                      </div>
                    </div>
                  </td>
                  <td className="px-2 py-2.5 text-right tabular-nums text-emerald-600 dark:text-emerald-400"
                    title={row.debit != null ? formatCurrency(row.debit) : undefined}>
                    {row.debit != null ? formatCurrency(row.debit) : <span className="text-muted-foreground/50">—</span>}
                  </td>
                  <td className="px-2 py-2.5 text-right tabular-nums text-red-600 dark:text-red-400"
                    title={row.credit != null ? formatCurrency(row.credit) : undefined}>
                    {row.credit != null ? formatCurrency(row.credit) : <span className="text-muted-foreground/50">—</span>}
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
      <div className="flex items-center justify-end px-4 py-2 border-t border-border bg-muted/40 flex-shrink-0">
        <SummaryBtn />
      </div>

      {/* Footer: pagination */}
      <div className="flex items-center justify-between px-4 py-3 border-t border-border bg-background flex-shrink-0">
        <span className="text-xs text-muted-foreground">
          {filteredRows.length === 0 ? 'No rows' : `Showing ${start}–${end} of ${filteredRows.length}`}
        </span>
        {totalPages > 1 && (
          <div className="flex items-center gap-1">
            <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1}
              className="p-1 rounded hover:bg-muted disabled:opacity-30 disabled:cursor-not-allowed">
              <ChevronLeft className="w-4 h-4 text-muted-foreground" />
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
                  <span key={`e${i}`} className="px-1 text-xs text-muted-foreground">…</span>
                ) : (
                  <button key={p} onClick={() => setPage(p as number)}
                    className={cn(
                      'w-6 h-6 rounded text-xs font-medium transition-colors',
                      page === p ? 'bg-primary text-primary-foreground' : 'hover:bg-muted text-muted-foreground',
                    )}>
                    {p}
                  </button>
                )
              )}
            <button onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages}
              className="p-1 rounded hover:bg-muted disabled:opacity-30 disabled:cursor-not-allowed">
              <ChevronRight className="w-4 h-4 text-muted-foreground" />
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
