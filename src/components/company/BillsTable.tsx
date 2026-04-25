import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { FileText, ChevronLeft, ChevronRight, Trash2 } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { StatusBadge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { EmptyState } from '@/components/ui/EmptyState'
import { formatCurrency, formatDate } from '@/lib/utils'
import { useBillStore, useAuthStore } from '@/store'
import type { Bill } from '@/types'

const PAGE_SIZE = 10

type DayFilter    = 7 | 30 | 90
type StatusFilter = 'unsynced' | 'synced' | 'failed'

const DAY_OPTIONS: { label: string; value: DayFilter }[] = [
  { label: '7 days',   value: 7  },
  { label: '30 days',  value: 30 },
  { label: '3 months', value: 90 },
]

const STATUS_OPTIONS: { label: string; value: StatusFilter }[] = [
  { label: 'Unsynced', value: 'unsynced' },
  { label: 'Synced',   value: 'synced'   },
  { label: 'Failed',   value: 'failed'   },
]

function cutoffDate(days: DayFilter): Date {
  const d = new Date()
  d.setDate(d.getDate() - days)
  d.setHours(0, 0, 0, 0)
  return d
}

interface BillsTableProps {
  bills: Bill[]
  onUpload: () => void
}

export function BillsTable({ bills, onUpload }: BillsTableProps) {
  const navigate = useNavigate()
  const [page, setPage]           = useState(1)
  const [deleting, setDeleting]   = useState<string | null>(null)
  const [dayFilter, setDayFilter] = useState<DayFilter>(7)
  const [statusFilter, setStatusFilter] = useState<Set<StatusFilter>>(new Set(['unsynced', 'failed']))

  const { activeCompanyId } = useAuthStore()
  const { deleteBill }      = useBillStore()

  const handleDelete = async (bill: Bill) => {
    if (!activeCompanyId) return
    if (!window.confirm(`Delete bill "${bill.billNumber}" from ${bill.vendorName}? This cannot be undone.`)) return
    setDeleting(bill.id)
    try {
      await deleteBill(activeCompanyId, bill.id)
      toast.success('Bill deleted')
    } catch {
      toast.error('Failed to delete bill')
    } finally {
      setDeleting(null)
    }
  }

  const toggleStatus = (s: StatusFilter) => {
    setStatusFilter((prev) => {
      const next = new Set(prev)
      if (next.has(s)) {
        if (next.size === 1) return prev // keep at least one selected
        next.delete(s)
      } else {
        next.add(s)
      }
      return next
    })
    setPage(1)
  }

  // Map status filter values to bill statuses
  const allowedStatuses = new Set<string>()
  if (statusFilter.has('unsynced')) { allowedStatuses.add('parsed'); allowedStatuses.add('mapped') }
  if (statusFilter.has('synced'))   allowedStatuses.add('synced')
  if (statusFilter.has('failed'))   allowedStatuses.add('error')

  const cutoff = cutoffDate(dayFilter)
  const filteredBills = bills.filter((b) => {
    if (!allowedStatuses.has(b.status)) return false
    const billDate = new Date(b.createdAt ?? b.billDate)
    return billDate >= cutoff
  })

  // Reset to page 1 when filters or bill list changes
  useEffect(() => { setPage(1) }, [bills.length, dayFilter, statusFilter])

  if (bills.length === 0) {
    return (
      <EmptyState
        icon={FileText}
        title="No bills yet"
        description="Upload your first purchase bill to get started"
        action={<Button variant="teal" onClick={onUpload}>Upload Bill</Button>}
      />
    )
  }

  const totalPages = Math.ceil(filteredBills.length / PAGE_SIZE)
  const pageBills  = filteredBills.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)
  const start      = (page - 1) * PAGE_SIZE + 1
  const end        = Math.min(page * PAGE_SIZE, filteredBills.length)

  return (
    <div>
      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-3 px-4 py-3 border-b border-gray-100 bg-gray-50">
        <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-lg p-0.5">
          {DAY_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => { setDayFilter(opt.value); setPage(1) }}
              className={`px-3 py-1 text-xs rounded-md font-medium transition-colors ${
                dayFilter === opt.value
                  ? 'bg-teal-600 text-white'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>

        <div className="w-px h-5 bg-gray-200" />

        <div className="flex items-center gap-1.5">
          {STATUS_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => toggleStatus(opt.value)}
              className={`px-3 py-1 text-xs rounded-full font-medium border transition-colors ${
                statusFilter.has(opt.value)
                  ? opt.value === 'synced'
                    ? 'bg-emerald-100 border-emerald-300 text-emerald-700'
                    : opt.value === 'failed'
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
          {filteredBills.length} bill{filteredBills.length !== 1 ? 's' : ''}
        </span>
      </div>

      {filteredBills.length === 0 ? (
        <div className="py-12 text-center text-sm text-gray-400">
          No bills match the selected filters.
        </div>
      ) : (
        <>
          <div className="overflow-x-auto">
            <table className="w-full border-collapse" aria-label="Bills list">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  {['Bill No.', 'Vendor', 'Date', 'Amount', 'Status', 'Action', ''].map((h, i) => (
                    <th key={i} className="px-4 py-2.5 text-left text-[10px] font-bold text-gray-500 uppercase tracking-widest">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {pageBills.map((bill) => (
                  <tr key={bill.id} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3 font-mono text-xs text-gray-600">{bill.billNumber}</td>
                    <td className="px-4 py-3 text-sm font-medium text-gray-800">{bill.vendorName}</td>
                    <td className="px-4 py-3 text-xs text-gray-500">{formatDate(bill.billDate)}</td>
                    <td className="px-4 py-3 text-sm font-semibold text-gray-800">{formatCurrency(bill.totalAmount)}</td>
                    <td className="px-4 py-3 text-center"><StatusBadge status={bill.status} /></td>
                    <td className="px-4 py-3">
                      {(bill.status === 'parsed' || bill.status === 'mapped') && (
                        <Button variant="teal" size="sm" onClick={() => navigate(`/company/bills/${bill.id}`)}>
                          Map & Sync
                        </Button>
                      )}
                      {bill.status === 'error' && (
                        <Button variant="danger" size="sm" onClick={() => navigate(`/company/bills/${bill.id}`)}>
                          Retry
                        </Button>
                      )}
                      {bill.status === 'synced' && (
                        <Button variant="outline" size="sm" onClick={() => navigate(`/company/bills/${bill.id}`)}>
                          View
                        </Button>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => handleDelete(bill)}
                        disabled={deleting === bill.id}
                        className="p-1.5 rounded text-gray-400 hover:text-red-500 hover:bg-red-50 disabled:opacity-40 transition-colors"
                        title="Delete bill"
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
                Showing {start}–{end} of {filteredBills.length} bills
              </span>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-1.5 rounded hover:bg-gray-200 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                  aria-label="Previous page"
                >
                  <ChevronLeft className="w-4 h-4 text-gray-600" />
                </button>

                {buildPageNumbers(page, totalPages).map((p, i) =>
                  p === '…' ? (
                    <span key={`ellipsis-${i}`} className="px-2 text-xs text-gray-500 select-none">…</span>
                  ) : (
                    <button
                      key={p}
                      onClick={() => setPage(p as number)}
                      className={`w-7 h-7 text-xs rounded font-medium transition-colors ${
                        p === page
                          ? 'bg-teal-600 text-white'
                          : 'text-gray-600 hover:bg-gray-200'
                      }`}
                    >
                      {p}
                    </button>
                  )
                )}

                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-1.5 rounded hover:bg-gray-200 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                  aria-label="Next page"
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

function buildPageNumbers(current: number, total: number): (number | '…')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1)

  const pages: (number | '…')[] = []
  const delta = 2

  for (let i = 1; i <= total; i++) {
    if (i === 1 || i === total || (i >= current - delta && i <= current + delta)) {
      pages.push(i)
    } else if (pages[pages.length - 1] !== '…') {
      pages.push('…')
    }
  }
  return pages
}
