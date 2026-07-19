import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { BookOpen, ChevronLeft, ChevronRight, Trash2 } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { Badge } from '@/shadcn/components/ui/badge'
import { Button } from '@/shadcn/components/ui/button'
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/shadcn/components/ui/table'
import { EmptyState } from '@/components/ui/EmptyState'
import { cn, formatCurrency, formatDate } from '@/lib/utils'
import { useCashBookStore } from '@/store/cashBookStore'
import type { CashBookRecord, CashBookStatus } from '@/store/cashBookStore'

const PAGE_SIZE = 10

type StatusFilter = 'pending' | 'synced' | 'partially_synced' | 'error'

const STATUS_OPTIONS: { label: string; value: StatusFilter }[] = [
  { label: 'Pending',  value: 'pending'          },
  { label: 'Partial',  value: 'partially_synced' },
  { label: 'Synced',   value: 'synced'           },
  { label: 'Error',    value: 'error'            },
]

const statusBadgeMap: Record<CashBookStatus, { variant: 'default' | 'secondary' | 'destructive' | 'outline'; label: string }> = {
  pending:          { variant: 'secondary',   label: 'Pending'      },
  partially_synced: { variant: 'outline',     label: 'Partial Sync' },
  synced:           { variant: 'default',     label: 'Synced'       },
  error:            { variant: 'destructive', label: 'Sync Error'   },
}

function CashBookStatusBadge({ status }: { status: CashBookStatus }) {
  const { variant, label } = statusBadgeMap[status]
  return <Badge variant={variant}>{label}</Badge>
}

const pillClass = (active: boolean) =>
  cn(
    'rounded-full px-3 py-1 text-xs font-medium transition-colors',
    active ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground hover:bg-muted/80',
  )

interface CashBookTableProps {
  records: CashBookRecord[]
  onUpload: () => void
}

export function CashBookTable({ records, onUpload }: CashBookTableProps) {
  const navigate = useNavigate()
  const { removeRecord } = useCashBookStore()

  const [page, setPage]                   = useState(1)
  const [statusFilter, setStatusFilter]   = useState<Set<StatusFilter>>(new Set(['pending', 'partially_synced', 'error']))

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

  const filtered = records.filter((r) => statusFilter.has(r.status))
  useEffect(() => { setPage(1) }, [records.length, statusFilter])

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const pageRows   = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)
  const start      = (page - 1) * PAGE_SIZE + 1
  const end        = Math.min(page * PAGE_SIZE, filtered.length)

  const handleDelete = (r: CashBookRecord) => {
    if (!window.confirm(`Delete "${r.bookName}" (${r.fileName})? This cannot be undone.`)) return
    removeRecord(r.id)
    toast.success('Cash book record deleted')
  }

  if (records.length === 0) {
    return (
      <EmptyState
        icon={BookOpen}
        title="No cash book records yet"
        description="Upload a CSV or PDF cash book to get started"
        action={<Button onClick={onUpload}>Upload Cash Book</Button>}
      />
    )
  }

  return (
    <div>
      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-2 px-2 pb-4">
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
          {filtered.length} record{filtered.length !== 1 ? 's' : ''}
        </span>
      </div>

      {filtered.length === 0 ? (
        <div className="py-12 text-center text-sm text-muted-foreground">
          No records match the selected filters.
        </div>
      ) : (
        <>
          <div className="overflow-x-auto">
            <Table className="min-w-[720px]" aria-label="Cash book records">
              <TableHeader>
                <TableRow>
                  <TableHead>Cash Book</TableHead>
                  <TableHead>Account</TableHead>
                  <TableHead>Uploaded</TableHead>
                  <TableHead className="text-center">Transactions</TableHead>
                  <TableHead className="text-right">Total In</TableHead>
                  <TableHead className="text-right">Total Out</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Action</TableHead>
                  <TableHead className="w-10" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageRows.map((row) => (
                  <TableRow key={row.id}>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <div className="flex size-7 shrink-0 items-center justify-center rounded-lg bg-emerald-500/10">
                          <BookOpen className="size-3.5 text-emerald-600 dark:text-emerald-400" />
                        </div>
                        <div>
                          <p className="text-sm font-semibold">{row.bookName}</p>
                          <p className="max-w-32 truncate text-[10px] text-muted-foreground">{row.fileName}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="font-mono text-xs text-muted-foreground">
                      {row.accountNumber ?? '—'}
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-xs text-muted-foreground">
                      {formatDate(row.uploadedAt)}
                    </TableCell>
                    <TableCell className="text-center font-semibold">
                      {row.totalCount}
                      {(row.status === 'synced' || row.status === 'partially_synced') && row.syncedCount > 0 && (
                        <span className="ml-1 text-[10px] text-muted-foreground">({row.syncedCount} synced)</span>
                      )}
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-right font-semibold text-emerald-600 dark:text-emerald-400">
                      {row.totalDebit > 0 ? formatCurrency(row.totalDebit) : '—'}
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-right font-semibold text-red-600 dark:text-red-400">
                      {row.totalCredit > 0 ? formatCurrency(row.totalCredit) : '—'}
                    </TableCell>
                    <TableCell><CashBookStatusBadge status={row.status} /></TableCell>
                    <TableCell className="text-right">
                      {row.status === 'pending' && (
                        <Button size="sm" onClick={() => navigate(`/company/cash-book/${row.id}`)}>
                          Map & Sync
                        </Button>
                      )}
                      {row.status === 'partially_synced' && (
                        <Button variant="outline" size="sm" onClick={() => navigate(`/company/cash-book/${row.id}`)}>
                          Continue
                        </Button>
                      )}
                      {row.status === 'error' && (
                        <Button variant="destructive" size="sm" onClick={() => navigate(`/company/cash-book/${row.id}`)}>
                          Retry
                        </Button>
                      )}
                      {row.status === 'synced' && (
                        <Button variant="outline" size="sm" onClick={() => navigate(`/company/cash-book/${row.id}`)}>
                          View
                        </Button>
                      )}
                    </TableCell>
                    <TableCell>
                      <Button
                        variant="ghost"
                        size="icon-sm"
                        className="text-muted-foreground hover:text-destructive"
                        onClick={() => handleDelete(row)}
                        title="Delete record"
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
                Showing {start}–{end} of {filtered.length}
              </p>
              <div className="flex items-center gap-1">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={page === 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                >
                  <ChevronLeft className="size-3.5" />
                </Button>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                  <Button
                    key={p}
                    variant={p === page ? 'default' : 'outline'}
                    size="sm"
                    className="w-7 p-0"
                    onClick={() => setPage(p)}
                  >
                    {p}
                  </Button>
                ))}
                <Button
                  variant="outline"
                  size="sm"
                  disabled={page === totalPages}
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                >
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
