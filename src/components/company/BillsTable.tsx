import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { FileText, ChevronLeft, ChevronRight, Trash2 } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { Badge } from '@/shadcn/components/ui/badge'
import { Button } from '@/shadcn/components/ui/button'
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/shadcn/components/ui/table'
import { EmptyState } from '@/components/ui/EmptyState'
import { cn, formatCurrency, formatDate, billNavType } from '@/lib/utils'
import { useBillStore, useAuthStore } from '@/store'
import type { Bill, BillStatus } from '@/types'

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

const statusBadgeMap: Record<BillStatus, { variant: 'default' | 'secondary' | 'destructive' | 'outline'; label: string }> = {
  synced:  { variant: 'default',     label: 'Synced'        },
  parsed:  { variant: 'secondary',   label: 'Parsed'        },
  mapped:  { variant: 'outline',     label: 'Ready to Sync' },
  pending: { variant: 'secondary',   label: 'Pending'       },
  error:   { variant: 'destructive', label: 'Sync Error'    },
}

function BillStatusBadge({ status }: { status: BillStatus }) {
  const { variant, label } = statusBadgeMap[status]
  return <Badge variant={variant}>{label}</Badge>
}

function cutoffDate(days: DayFilter): Date {
  const d = new Date()
  d.setDate(d.getDate() - days)
  d.setHours(0, 0, 0, 0)
  return d
}

const pillClass = (active: boolean) =>
  cn(
    'rounded-full px-3 py-1 text-xs font-medium transition-colors',
    active ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground hover:bg-muted/80',
  )

interface BillsTableProps {
  bills: Bill[]
  onUpload: () => void
}

export function BillsTable({ bills, onUpload }: BillsTableProps) {
  const navigate = useNavigate()
  const billPath = (bill: Bill) => {
    const type = billNavType(bill)
    return `/company/bills/${bill.id}${type ? `?type=${type}` : ''}`
  }
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
        action={<Button onClick={onUpload}>Upload Bill</Button>}
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
      <div className="flex flex-wrap items-center gap-2 px-2 pb-4">
        <div className="flex flex-wrap gap-2">
          {DAY_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => { setDayFilter(opt.value); setPage(1) }}
              className={pillClass(dayFilter === opt.value)}
            >
              {opt.label}
            </button>
          ))}
        </div>

        <span className="mx-1 w-px self-stretch bg-border" />

        <div className="flex flex-wrap gap-2">
          {STATUS_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => toggleStatus(opt.value)}
              className={pillClass(statusFilter.has(opt.value))}
            >
              {opt.label}
            </button>
          ))}
        </div>

        <span className="ml-auto text-xs text-muted-foreground">
          {filteredBills.length} bill{filteredBills.length !== 1 ? 's' : ''}
        </span>
      </div>

      {filteredBills.length === 0 ? (
        <div className="py-12 text-center text-sm text-muted-foreground">
          No bills match the selected filters.
        </div>
      ) : (
        <>
          <div className="overflow-x-auto">
            <Table className="min-w-[640px]" aria-label="Bills list">
              <TableHeader>
                <TableRow>
                  <TableHead>Bill No.</TableHead>
                  <TableHead>Vendor</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Action</TableHead>
                  <TableHead className="w-10" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageBills.map((bill) => (
                  <TableRow key={bill.id}>
                    <TableCell className="font-mono text-xs">
                      {bill.billNumber}
                      {bill.billType === 'misc' && (
                        <Badge variant="secondary" className="ml-1.5">Misc</Badge>
                      )}
                      {bill.billType === 'debit' && (
                        <Badge variant="secondary" className="ml-1.5">Debit Note</Badge>
                      )}
                      {bill.billType === 'credit' && (
                        <Badge variant="secondary" className="ml-1.5">Credit Note</Badge>
                      )}
                    </TableCell>
                    <TableCell className="font-medium">{bill.vendorName}</TableCell>
                    <TableCell className="text-muted-foreground">{formatDate(bill.billDate)}</TableCell>
                    <TableCell className="font-semibold">{formatCurrency(bill.totalAmount)}</TableCell>
                    <TableCell><BillStatusBadge status={bill.status} /></TableCell>
                    <TableCell className="text-right">
                      {(bill.status === 'parsed' || bill.status === 'mapped') && (
                        <Button size="sm" onClick={() => navigate(billPath(bill))}>
                          Map & Sync
                        </Button>
                      )}
                      {bill.status === 'error' && (
                        <Button variant="destructive" size="sm" onClick={() => navigate(billPath(bill))}>
                          Retry
                        </Button>
                      )}
                      {bill.status === 'synced' && (
                        <Button variant="outline" size="sm" onClick={() => navigate(billPath(bill))}>
                          View
                        </Button>
                      )}
                    </TableCell>
                    <TableCell>
                      <Button
                        variant="ghost"
                        size="icon-sm"
                        className="text-muted-foreground hover:text-destructive"
                        onClick={() => handleDelete(bill)}
                        disabled={deleting === bill.id}
                        title="Delete bill"
                      >
                        <Trash2 className="size-3.5" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>

          {totalPages > 1 && (
            <div className="mt-4 flex flex-col gap-2 px-2 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-xs text-muted-foreground">
                Showing {start}–{end} of {filteredBills.length} bills
              </p>
              <div className="flex items-center gap-1">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={page === 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                >
                  <ChevronLeft className="size-3.5" />
                  Previous
                </Button>

                {buildPageNumbers(page, totalPages).map((p, i) =>
                  p === '…' ? (
                    <span key={`ellipsis-${i}`} className="px-2 text-xs text-muted-foreground select-none">…</span>
                  ) : (
                    <Button
                      key={p}
                      variant={p === page ? 'default' : 'outline'}
                      size="sm"
                      className="w-7 p-0"
                      onClick={() => setPage(p as number)}
                    >
                      {p}
                    </Button>
                  )
                )}

                <Button
                  variant="outline"
                  size="sm"
                  disabled={page === totalPages}
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                >
                  Next
                  <ChevronRight className="size-3.5" />
                </Button>
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
