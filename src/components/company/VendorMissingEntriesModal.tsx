import { useState, useEffect } from 'react'
import { X, Zap, CheckCircle2, ChevronLeft, ChevronRight, BookOpen } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { Button } from '@/components/ui/Button'
import { cn, formatCurrency } from '@/lib/utils'
import { useCompanyStore } from '@/store'
import { useVendorReconciliationStore } from '@/store/vendorReconciliationStore'
import type { VendorReconciliationRow } from '@/store/vendorReconciliationStore'
import { syncBankToTally } from '@/services/tallyService'
import type { BankSyncRow } from '@/services/tallyService'
import { getTallyUrl } from '@/pages/company/CompanySettings'

const PAGE_SIZE = 15
const VOUCHER_TYPES = ['Contra', 'Payment', 'Receipt'] as const

interface MissingRow {
  id:          string
  date:        string
  description: string
  debit:       number | null
  credit:      number | null
  ledger:      string
  voucherType: string
  synced:      boolean
  selected:    boolean
}

interface Props {
  recordId:    string
  companyId:   string
  missingRows: VendorReconciliationRow[]
  onClose:     () => void
}

export function VendorMissingEntriesModal({ recordId, companyId, missingRows, onClose }: Props) {
  const { getCompany, getLedgers, fetchLedgersFromDb } = useCompanyStore()
  const { getRecord, markMissingEntriesSynced } = useVendorReconciliationStore()

  const company      = getCompany(companyId) ?? null
  const ledgers      = getLedgers(companyId)

  useEffect(() => {
    if (!companyId) return
    if (ledgers.length === 0) fetchLedgersFromDb(companyId).catch(() => {})
  }, [companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  const ledgerNames  = ledgers.map((l) => l.name)
  const tallyUrl     = getTallyUrl(companyId, company?.port)
  const tallyCompany = company?.name ?? ''

  const record    = getRecord(recordId)
  const syncedIds = new Set(record?.syncedMissingIds ?? [])

  const [cashLedger, setCashLedger] = useState('')
  const [syncing,    setSyncing]    = useState(false)
  const [page,       setPage]       = useState(1)

  const cashLedgerNames = (() => {
    const filtered = ledgers
      .filter((l) => {
        const g = (l.group ?? '').toLowerCase()
        return g.includes('bank account') || g.includes('cash-in-hand') || g.includes('cash in hand') ||
               g.includes('sundry creditor') || g.includes('sundry debtor')
      })
      .map((l) => l.name)
    return filtered.length > 0 ? filtered : ledgerNames
  })()

  const [rows, setRows] = useState<MissingRow[]>(() =>
    missingRows.map((r) => {
      const alreadySynced = syncedIds.has(r.id)
      return {
        id:          r.id,
        date:        r.date,
        description: r.description,
        debit:       r.debit,
        credit:      r.credit,
        ledger:      '',
        voucherType: r.debit != null ? 'Receipt' : 'Payment',
        synced:      alreadySynced,
        selected:    !alreadySynced,
      }
    }),
  )

  const updateRow = (id: string, patch: Partial<MissingRow>) =>
    setRows((prev) => prev.map((r) => (r.id === id ? { ...r, ...patch } : r)))

  const totalPages = Math.max(1, Math.ceil(rows.length / PAGE_SIZE))
  const pageRows   = rows.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  const allSelected = pageRows.filter((r) => !r.synced).length > 0 &&
                      pageRows.filter((r) => !r.synced).every((r) => r.selected)
  const toggleAll   = () => {
    const ids = new Set(pageRows.filter((r) => !r.synced).map((r) => r.id))
    const next = !allSelected
    setRows((prev) => prev.map((r) => ids.has(r.id) ? { ...r, selected: next } : r))
  }

  const selectedCount = rows.filter((r) => r.selected).length
  const mappedCount   = rows.filter((r) => r.selected && r.ledger.trim()).length
  const readyToSync   = mappedCount > 0 && cashLedger.trim()
  const syncedCount   = rows.filter((r) => r.synced).length

  const handleSync = async () => {
    const selected = rows.filter((r) => r.selected && r.ledger.trim())
    if (selected.length === 0) return
    setSyncing(true)
    try {
      const syncRows: BankSyncRow[] = selected.map((r) => ({
        date:        r.date,
        description: r.description,
        ledger:      r.ledger.trim(),
        voucherType: r.voucherType,
        amount:      Math.abs(r.debit ?? r.credit ?? 0),
        isPayment:   r.credit != null,
      }))
      const result = await syncBankToTally(syncRows, cashLedger, tallyUrl, tallyCompany)
      if (result.success) {
        const pushedIds = selected.map((r) => r.id)
        markMissingEntriesSynced(recordId, pushedIds)
        setRows((prev) => prev.map((r) =>
          pushedIds.includes(r.id) ? { ...r, synced: true, selected: false } : r
        ))
        toast.success(`${pushedIds.length} voucher${pushedIds.length !== 1 ? 's' : ''} pushed to books`)
      } else {
        toast.error(result.message ?? 'Sync failed — check Tally connection')
      }
    } catch {
      toast.error('Failed to connect to Tally. Is the extension running?')
    } finally {
      setSyncing(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="bg-card rounded-xl shadow-2xl w-full max-w-5xl max-h-[90vh] flex flex-col">

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border flex-shrink-0">
          <div className="flex items-center gap-2">
            <BookOpen className="w-4 h-4 text-violet-600" />
            <div>
              <span className="text-sm font-bold text-foreground">Add Missing Entries to Book</span>
              <p className="text-[11px] text-muted-foreground mt-0.5">
                {rows.length} missing {rows.length === 1 ? 'entry' : 'entries'}
                {syncedCount > 0 && <span className="ml-1.5 text-emerald-600">· {syncedCount} already pushed</span>}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded hover:bg-muted text-muted-foreground hover:text-foreground transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Ledger selector */}
        <div className="px-5 py-3 border-b border-border bg-muted/60 flex items-center gap-4 flex-shrink-0">
          <label className="text-xs font-semibold text-muted-foreground whitespace-nowrap">Ledger Account *</label>
          <div className="relative">
            <input
              list="vendor-missing-ledger-list"
              value={cashLedger}
              onChange={(e) => setCashLedger(e.target.value)}
              placeholder="Select ledger account…"
              autoComplete="off"
              className="input-base text-sm w-72"
            />
            <datalist id="vendor-missing-ledger-list">
              {cashLedgerNames.map((n) => <option key={n} value={n} />)}
            </datalist>
          </div>
          {!cashLedger.trim() && (
            <span className="text-xs text-amber-600 font-medium">Required before syncing</span>
          )}
        </div>

        {/* Table */}
        <div className="flex-1 overflow-y-auto overflow-x-hidden px-4 py-2">
          <table className="w-full text-xs border-collapse table-fixed">
            <colgroup>
              <col className="w-[3%]" />
              <col className="w-[8%]" />
              <col />
              <col className="w-[18%]" />
              <col className="w-[10%]" />
              <col className="w-[9%]" />
              <col className="w-[9%]" />
              <col className="w-[9%]" />
            </colgroup>
            <thead className="sticky top-0 z-10 bg-muted border-b border-border">
              <tr>
                <th className="px-3 py-2.5 text-left">
                  <input type="checkbox" checked={allSelected} onChange={toggleAll} className="rounded" />
                </th>
                <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground whitespace-nowrap">Date</th>
                <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Description</th>
                <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Ledger</th>
                <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Voucher Type</th>
                <th className="px-2 py-2.5 text-right font-semibold text-muted-foreground whitespace-nowrap">
                  Debit<br /><span className="font-normal text-muted-foreground">(Dr)</span>
                </th>
                <th className="px-2 py-2.5 text-right font-semibold text-muted-foreground whitespace-nowrap">
                  Credit<br /><span className="font-normal text-muted-foreground">(Cr)</span>
                </th>
                <th className="px-2 py-2.5 text-right font-semibold text-muted-foreground">Amount</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {pageRows.map((row) => (
                <tr
                  key={row.id}
                  className={cn(
                    'transition-colors',
                    row.synced  ? 'bg-emerald-50/50' : 'hover:bg-muted',
                    !row.selected && !row.synced && 'opacity-40',
                  )}
                >
                  <td className="px-3 py-2">
                    <input
                      type="checkbox"
                      checked={row.selected}
                      disabled={row.synced}
                      onChange={(e) => updateRow(row.id, { selected: e.target.checked })}
                      className="rounded disabled:cursor-not-allowed"
                    />
                  </td>
                  <td className="px-3 py-2 whitespace-nowrap text-muted-foreground">{row.date}</td>
                  <td className="px-3 py-2">
                    <span className="block text-foreground break-words leading-snug line-clamp-3">
                      {row.description || '—'}
                    </span>
                  </td>
                  <td className="px-3 py-1.5">
                    {row.synced ? (
                      <span className="flex items-center gap-1 text-emerald-600 text-xs font-medium">
                        <CheckCircle2 className="w-3.5 h-3.5 flex-shrink-0" />
                        Already Pushed
                      </span>
                    ) : (
                      <>
                        <input
                          list={`vendor-missing-ledger-${row.id}`}
                          value={row.ledger}
                          onChange={(e) => updateRow(row.id, { ledger: e.target.value })}
                          placeholder="Select ledger…"
                          autoComplete="off"
                          className={cn(
                            'w-full text-xs px-2.5 py-1 border border-border rounded-lg bg-card text-foreground outline-none transition-all focus:border-brand-500 focus:ring-2 focus:ring-brand-500/10',
                            row.selected && !row.ledger.trim() && 'border-amber-300 bg-amber-50',
                          )}
                        />
                        <datalist id={`vendor-missing-ledger-${row.id}`}>
                          {ledgerNames.map((n) => <option key={n} value={n} />)}
                        </datalist>
                      </>
                    )}
                  </td>
                  <td className="px-3 py-1.5">
                    <select
                      value={row.voucherType}
                      disabled={row.synced}
                      onChange={(e) => updateRow(row.id, { voucherType: e.target.value })}
                      className="w-full text-xs px-2.5 py-1 border border-border rounded-lg bg-card text-foreground outline-none transition-all focus:border-brand-500 focus:ring-2 focus:ring-brand-500/10 disabled:bg-muted disabled:text-muted-foreground"
                    >
                      {VOUCHER_TYPES.map((v) => <option key={v} value={v}>{v}</option>)}
                    </select>
                  </td>
                  <td className="px-2 py-2 text-right text-emerald-600 dark:text-emerald-400 font-medium truncate"
                    title={row.debit != null ? formatCurrency(row.debit) : '—'}>
                    {row.debit != null ? formatCurrency(row.debit) : '—'}
                  </td>
                  <td className="px-2 py-2 text-right text-red-600 font-medium truncate"
                    title={row.credit != null ? formatCurrency(row.credit) : '—'}>
                    {row.credit != null ? formatCurrency(row.credit) : '—'}
                  </td>
                  <td className="px-2 py-2 text-right font-semibold text-foreground truncate"
                    title={formatCurrency(Math.abs(row.debit ?? row.credit ?? 0))}>
                    {formatCurrency(Math.abs(row.debit ?? row.credit ?? 0))}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-5 py-3 border-t border-border bg-card flex-shrink-0 gap-4 flex-wrap">
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="p-1 rounded hover:bg-muted disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="text-xs text-muted-foreground">
              Page {page} of {totalPages} · {rows.length} rows
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="p-1 rounded hover:bg-muted disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>

          <div className="flex items-center gap-3">
            <span className="text-xs text-muted-foreground">
              {mappedCount} of {selectedCount} selected rows mapped
            </span>
            {!cashLedger.trim() && selectedCount > 0 && (
              <span className="text-xs text-amber-600 font-medium">Set Ledger first</span>
            )}
            <button
              onClick={onClose}
              className="px-4 py-1.5 text-xs font-medium rounded-lg border border-border text-muted-foreground hover:bg-muted transition-colors"
            >
              Close
            </button>
            <Button
              variant="teal"
              onClick={handleSync}
              loading={syncing}
              disabled={!readyToSync || syncing}
            >
              <Zap className="w-3.5 h-3.5 mr-1.5" />
              Push {mappedCount > 0 ? `${mappedCount} Voucher${mappedCount !== 1 ? 's' : ''}` : ''}
            </Button>
          </div>
        </div>

      </div>
    </div>
  )
}
