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

interface BillsTableProps {
  bills: Bill[]
  onUpload: () => void
}

export function BillsTable({ bills, onUpload }: BillsTableProps) {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [deleting, setDeleting] = useState<string | null>(null)

  const { user } = useAuthStore()
  const { deleteBill } = useBillStore()

  const handleDelete = async (bill: Bill) => {
    if (!user?.companyId) return
    if (!window.confirm(`Delete bill "${bill.billNumber}" from ${bill.vendorName}? This cannot be undone.`)) return
    setDeleting(bill.id)
    try {
      await deleteBill(user.companyId, bill.id)
      toast.success('Bill deleted')
    } catch {
      toast.error('Failed to delete bill')
    } finally {
      setDeleting(null)
    }
  }

  // Reset to page 1 when bill list changes (new upload, etc.)
  useEffect(() => { setPage(1) }, [bills.length])

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

  const totalPages = Math.ceil(bills.length / PAGE_SIZE)
  const pageBills  = bills.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)
  const start      = (page - 1) * PAGE_SIZE + 1
  const end        = Math.min(page * PAGE_SIZE, bills.length)

  return (
    <div>
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
                <td className="px-4 py-3"><StatusBadge status={bill.status} /></td>
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

      {/* Pagination bar */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-gray-50">
          <span className="text-xs text-gray-500">
            Showing {start}–{end} of {bills.length} bills
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
                <span key={`ellipsis-${i}`} className="px-2 text-xs text-gray-400 select-none">…</span>
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
