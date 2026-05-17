import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Landmark, ChevronLeft, ChevronRight, Trash2 } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { EmptyState } from '@/components/ui/EmptyState'
import { formatCurrency, formatDate } from '@/lib/utils'
import { useBankStore } from '@/store/bankStore'
import type { BankStatementRecord, BankStatementStatus } from '@/store/bankStore'

const PAGE_SIZE = 10

type StatusFilter = 'pending' | 'synced' | 'error'

const STATUS_OPTIONS: { label: string; value: StatusFilter }[] = [
  { label: 'Pending', value: 'pending' },
  { label: 'Synced',  value: 'synced'  },
  { label: 'Error',   value: 'error'   },
]

function BankStatusBadge({ status }: { status: BankStatementStatus }) {
  const map: Record<BankStatementStatus, { variant: 'amber' | 'green' | 'red'; label: string }> = {
    pending: { variant: 'amber', label: 'Pending'    },
    synced:  { variant: 'green', label: 'Synced'     },
    error:   { variant: 'red',   label: 'Sync Error' },
  }
  const { variant, label } = map[status]
  return <Badge variant={variant}>{label}</Badge>
}

interface BankStatementsTableProps {
  statements: BankStatementRecord[]
  onUpload: () => void
}

export function BankStatementsTable({ statements, onUpload }: BankStatementsTableProps) {
  const navigate = useNavigate()
  const { removeStatement } = useBankStore()

  const [page, setPage]           = useState(1)
  const [statusFilter, setStatusFilter] = useState<Set<StatusFilter>>(new Set(['pending', 'error']))

  const toggleStatus = (s: StatusFilter) => {
    setStatusFilter((prev) => {
      const next = new Set(prev)
      if (next.has(s)) {
        if (next.size === 1) return prev
        next.delete(s)
      } else {
        next.add(s)
      }
      return next
    })
    setPage(1)
  }

  const filtered = statements.filter((r) => statusFilter.has(r.status))
  useEffect(() => { setPage(1) }, [statements.length, statusFilter])

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const pageRows   = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)
  const start      = (page - 1) * PAGE_SIZE + 1
  const end        = Math.min(page * PAGE_SIZE, filtered.length)

  const handleDelete = (r: BankStatementRecord) => {
    if (!window.confirm(`Delete "${r.bankName}" (${r.fileName})? This cannot be undone.`)) return
    removeStatement(r.id)
    toast.success('Bank statement deleted')
  }

  if (statements.length === 0) {
    return (
      <EmptyState
        icon={Landmark}
        title="No bank statements yet"
        description="Upload a CSV or PDF bank statement to get started"
        action={<Button variant="teal" onClick={onUpload}>Upload Statement</Button>}
      />
    )
  }

  return (
    <div>
      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-3 px-4 py-3 border-b border-gray-100 bg-gray-50">
        <div className="flex items-center gap-1.5">
          {STATUS_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => toggleStatus(opt.value)}
              className={`px-3 py-1 text-xs rounded-full font-medium border transition-colors ${
                statusFilter.has(opt.value)
                  ? opt.value === 'synced'
                    ? 'bg-emerald-100 border-emerald-300 text-emerald-700'
                    : opt.value === 'error'
                    ? 'bg-red-100 border-red-300 text-red-700'
                    : 'bg-amber-100 border-amber-300 text-amber-700'
                  : 'bg-white border-gray-200 text-gray-400 hover:text-gray-600'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>
        <span className="ml-auto text-xs text-gray-400">
          {filtered.length} statement{filtered.length !== 1 ? 's' : ''}
        </span>
      </div>

      {filtered.length === 0 ? (
        <div className="py-12 text-center text-sm text-gray-400">
          No statements match the selected filters.
        </div>
      ) : (
        <>
          <div className="overflow-x-auto">
            <table className="w-full border-collapse" aria-label="Bank statements">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  {['Bank', 'Account', 'Uploaded', 'Transactions', 'Total In', 'Total Out', 'Status', 'Action', ''].map((h, i) => (
                    <th key={i} className="px-4 py-2.5 text-left text-[10px] font-bold text-gray-500 uppercase tracking-widest whitespace-nowrap">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {pageRows.map((row) => (
                  <tr key={row.id} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 rounded-lg bg-teal-50 flex items-center justify-center flex-shrink-0">
                          <Landmark className="w-3.5 h-3.5 text-teal-600" />
                        </div>
                        <div>
                          <p className="text-sm font-semibold text-gray-800">{row.bankName}</p>
                          <p className="text-[10px] text-gray-400 truncate max-w-32">{row.fileName}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-500 font-mono">
                      {row.accountNumber ?? '—'}
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">
                      {formatDate(row.uploadedAt)}
                    </td>
                    <td className="px-4 py-3 text-sm font-semibold text-gray-700 text-center">
                      {row.totalCount}
                      {row.status === 'synced' && row.syncedCount > 0 && (
                        <span className="ml-1 text-[10px] text-gray-400">({row.syncedCount} synced)</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm font-semibold text-teal-700 text-right whitespace-nowrap">
                      {row.totalDebit > 0 ? formatCurrency(row.totalDebit) : '—'}
                    </td>
                    <td className="px-4 py-3 text-sm font-semibold text-red-600 text-right whitespace-nowrap">
                      {row.totalCredit > 0 ? formatCurrency(row.totalCredit) : '—'}
                    </td>
                    <td className="px-4 py-3">
                      <BankStatusBadge status={row.status} />
                    </td>
                    <td className="px-4 py-3">
                      {(row.status === 'pending' || row.status === 'error') && (
                        <Button
                          variant={row.status === 'error' ? 'danger' : 'teal'}
                          size="sm"
                          onClick={() => navigate(`/company/bank/${row.id}`)}
                        >
                          {row.status === 'error' ? 'Retry' : 'Map & Sync'}
                        </Button>
                      )}
                      {row.status === 'synced' && (
                        <Button variant="outline" size="sm" onClick={() => navigate(`/company/bank/${row.id}`)}>
                          View
                        </Button>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => handleDelete(row)}
                        className="p-1.5 rounded text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors"
                        title="Delete statement"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-gray-50">
              <span className="text-xs text-gray-500">
                Showing {start}–{end} of {filtered.length}
              </span>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-1.5 rounded hover:bg-gray-200 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                >
                  <ChevronLeft className="w-4 h-4 text-gray-600" />
                </button>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                  <button
                    key={p}
                    onClick={() => setPage(p)}
                    className={`w-7 h-7 text-xs rounded font-medium transition-colors ${
                      p === page ? 'bg-teal-600 text-white' : 'text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    {p}
                  </button>
                ))}
                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-1.5 rounded hover:bg-gray-200 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                >
                  <ChevronRight className="w-4 h-4 text-gray-600" />
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}
