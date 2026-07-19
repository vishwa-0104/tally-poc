import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { RefreshCw, ChevronDown, ChevronRight, AlertCircle, RotateCcw } from 'lucide-react'
import { CompanyPageHeader } from '@/shadcn/components/company-page-header'
import { EmptyState } from '@/components/ui'
import { Button } from '@/components/ui/Button'
import { formatCurrency, formatDate } from '@/lib/utils'
import { useAuthStore, useBillStore } from '@/store'

export default function CompanySyncLog() {
  const { activeCompanyId } = useAuthStore()
  const { getBills }        = useBillStore()
  const navigate            = useNavigate()

  const bills  = activeCompanyId ? getBills(activeCompanyId) : []
  const synced = bills.filter((b) => b.status === 'synced')
  const errors = bills.filter((b) => b.status === 'error')

  const successRate = bills.length > 0
    ? Math.round((synced.length / bills.length) * 100)
    : 0

  return (
    <>
      <CompanyPageHeader title="Sync Log" subtitle="History of all sync operations" />

      <div className="p-4 md:p-7 space-y-6">

        {/* Summary stats */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <SummaryCard label="Synced"        value={synced.length}  color="green" />
          <SummaryCard label="Errors"        value={errors.length}  color="red"   />
          <SummaryCard label="Total Bills"   value={bills.length}   color="gray"  />
          <SummaryCard label="Success Rate"  value={`${successRate}%`} color="teal" />
        </div>

        {/* Synced table */}
        <div>
          <h2 className="text-sm font-bold text-foreground mb-3">Successful Syncs ({synced.length})</h2>
          <div className="card overflow-hidden">
            {synced.length === 0 ? (
              <EmptyState
                icon={RefreshCw}
                title="No syncs yet"
                description="Synced bills will appear here"
              />
            ) : (
              <table className="w-full border-collapse" aria-label="Synced bills">
                <thead>
                  <tr className="bg-muted border-b border-border">
                    {['Bill No.', 'Vendor', 'Amount', 'Bill Date', 'Synced At', 'Vendor Ledger', 'Result'].map((h) => (
                      <th key={h} className="px-4 py-2.5 text-left text-[10px] font-bold text-muted-foreground uppercase tracking-widest">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {synced.map((b) => (
                    <tr key={b.id} className="border-b border-border last:border-0 hover:bg-muted">
                      <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{b.billNumber}</td>
                      <td className="px-4 py-3 text-sm font-medium text-foreground">{b.vendorName}</td>
                      <td className="px-4 py-3 text-sm font-semibold text-foreground">{formatCurrency(b.totalAmount)}</td>
                      <td className="px-4 py-3 text-xs text-muted-foreground">{formatDate(b.billDate)}</td>
                      <td className="px-4 py-3 text-xs text-muted-foreground">
                        {b.syncedAt ? new Date(b.syncedAt).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }) : '—'}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground font-mono">{b.tallyMapping?.vendorLedger ?? '—'}</td>
                      <td className="px-4 py-3"><span className="badge badge-green">Success</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Errors table */}
        {errors.length > 0 && (
          <div>
            <h2 className="text-sm font-bold text-foreground mb-3">Failed Syncs ({errors.length})</h2>
            <div className="card overflow-hidden">
              <table className="w-full border-collapse" aria-label="Failed syncs">
                <thead>
                  <tr className="bg-muted border-b border-border">
                    {['', 'Bill No.', 'Vendor', 'Amount', 'Error Summary', 'Action'].map((h) => (
                      <th key={h} className="px-4 py-2.5 text-left text-[10px] font-bold text-muted-foreground uppercase tracking-widest">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {errors.map((b) => (
                    <ErrorRow
                      key={b.id}
                      billNumber={b.billNumber}
                      vendorName={b.vendorName}
                      totalAmount={b.totalAmount}
                      syncError={b.syncError}
                      onRetry={() => navigate(`/company/bills/${b.id}`)}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {bills.length === 0 && (
          <EmptyState
            icon={RefreshCw}
            title="No bills yet"
            description="Upload and sync your first bill to see activity here"
          />
        )}
      </div>
    </>
  )
}

// ── Sub-components ────────────────────────────────────────────────────────────

function SummaryCard({ label, value, color }: { label: string; value: number | string; color: string }) {
  const colorMap: Record<string, string> = {
    green: 'bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 border-emerald-500/30',
    red:   'bg-red-500/10 text-red-700 dark:text-red-400 border-red-500/30',
    teal:  'bg-primary/10 text-primary border-primary/30',
    gray:  'bg-muted text-foreground border-border',
  }
  return (
    <div className={`rounded-xl border px-5 py-4 ${colorMap[color] ?? colorMap.gray}`}>
      <p className="text-2xl font-bold">{value}</p>
      <p className="text-xs font-medium mt-0.5 opacity-80">{label}</p>
    </div>
  )
}

interface ErrorRowProps {
  billNumber: string
  vendorName: string
  totalAmount: number
  syncError?: string
  onRetry: () => void
}

function ErrorRow({ billNumber, vendorName, totalAmount, syncError, onRetry }: ErrorRowProps) {
  const [expanded, setExpanded] = useState(false)
  const summary = syncError ? syncError.slice(0, 60) + (syncError.length > 60 ? '…' : '') : 'Unknown error'

  return (
    <>
      <tr
        className="border-b border-border hover:bg-red-50/40 cursor-pointer"
        onClick={() => setExpanded((e) => !e)}
      >
        <td className="px-3 py-3 w-6 text-muted-foreground">
          {expanded
            ? <ChevronDown className="w-3.5 h-3.5" />
            : <ChevronRight className="w-3.5 h-3.5" />
          }
        </td>
        <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{billNumber}</td>
        <td className="px-4 py-3 text-sm font-medium text-foreground">{vendorName}</td>
        <td className="px-4 py-3 text-sm font-semibold text-foreground">{formatCurrency(totalAmount)}</td>
        <td className="px-4 py-3 text-xs text-red-600">{summary}</td>
        <td className="px-4 py-3" onClick={(e) => e.stopPropagation()}>
          <Button variant="outline" size="sm" onClick={onRetry}>
            <RotateCcw className="w-3 h-3" />
            Retry
          </Button>
        </td>
      </tr>
      {expanded && (
        <tr className="border-b border-border bg-red-50/30">
          <td />
          <td colSpan={5} className="px-4 pb-3 pt-1">
            <div className="flex gap-2 p-3 bg-card border border-red-200 rounded-lg">
              <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" />
              <p className="text-xs text-red-700 font-mono leading-relaxed break-all">{syncError ?? 'No error details available'}</p>
            </div>
          </td>
        </tr>
      )}
    </>
  )
}
