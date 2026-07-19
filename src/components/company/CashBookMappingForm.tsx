import { useState, useEffect } from 'react'
import { ChevronLeft, ChevronRight, Zap, CheckCircle2 } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { cn, formatCurrency } from '@/lib/utils'
import { makeCashBookFingerprint } from '@/store/cashBookStore'
import type { ParsedBankStatement, TallyLedger } from '@/types'
import type { BankSyncRow } from '@/services/tallyService'

const PAGE_SIZE = 15
const VOUCHER_TYPES = ['Contra', 'Payment', 'Receipt'] as const

function toIsoDate(dateStr: string): string {
  if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return dateStr
  const m = dateStr.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/)
  if (m) return `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}`
  return new Date().toISOString().slice(0, 10)
}

const todayIso = () => new Date().toISOString().slice(0, 10)

interface CashBookRow {
  id:          string
  date:        string
  entryDate:   string
  description: string
  debit:       number | null
  credit:      number | null
  synced:      boolean
  selected:    boolean
  ledger:      string
  voucherType: string
  narration:   string
}

interface Props {
  statement:          ParsedBankStatement
  cashLedger:         string
  onCashLedgerChange: (v: string) => void
  ledgers:            TallyLedger[]
  onSync:             (rows: BankSyncRow[], cashLedger: string) => Promise<void>
  syncing:            boolean
  fingerprintSet:     Set<string>
}

export function CashBookMappingForm({
  statement,
  cashLedger,
  onCashLedgerChange,
  ledgers,
  onSync,
  syncing,
  fingerprintSet,
}: Props) {
  const [rows, setRows] = useState<CashBookRow[]>(() =>
    statement.transactions.map((t) => {
      const alreadySynced = t.synced === true || fingerprintSet.has(
        makeCashBookFingerprint(statement.bankName, t.date, Math.abs(t.debit ?? t.credit ?? 0), t.description),
      )
      return {
        id:          t.id,
        date:        t.date,
        entryDate:   t.entryDate ?? (t.date ? toIsoDate(t.date) : todayIso()),
        description: t.description,
        debit:       t.debit,
        credit:      t.credit,
        synced:      alreadySynced,
        selected:    !alreadySynced,
        ledger:      '',
        voucherType: (t.debit != null && t.credit != null)
          ? 'Contra'
          : t.debit != null
          ? 'Receipt'
          : 'Payment',
        narration: t.narration ?? '',
      }
    }),
  )

  useEffect(() => {
    if (fingerprintSet.size === 0) return
    setRows((prev) => prev.map((r) => {
      if (r.synced) return r
      const fp = makeCashBookFingerprint(statement.bankName, r.date, Math.abs(r.debit ?? r.credit ?? 0), r.description)
      if (!fingerprintSet.has(fp)) return r
      return { ...r, synced: true, selected: false }
    }))
  }, [fingerprintSet, statement.bankName]) // eslint-disable-line react-hooks/exhaustive-deps

  const [page, setPage] = useState(1)

  const totalPages = Math.max(1, Math.ceil(rows.length / PAGE_SIZE))
  const pageRows   = rows.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  const updateRow = (id: string, patch: Partial<CashBookRow>) =>
    setRows((prev) => prev.map((r) => (r.id === id ? { ...r, ...patch } : r)))

  const allSelected = pageRows.every((r) => r.selected)
  const toggleAll   = () => {
    const ids = new Set(pageRows.map((r) => r.id))
    const next = !allSelected
    setRows((prev) => prev.map((r) => ids.has(r.id) ? { ...r, selected: next } : r))
  }

  const ledgerNames = ledgers.map((l) => l.name)

  const cashLedgerNames = (() => {
    const filtered = ledgers
      .filter((l) => {
        const g = (l.group || '').toLowerCase()
        return g.includes('bank account') || g.includes('cash-in-hand') || g.includes('cash in hand')
      })
      .map((l) => l.name)
    return filtered.length > 0 ? filtered : ledgerNames
  })()

  const handleSync = async () => {
    const selected = rows.filter((r) => r.selected && r.ledger.trim())
    if (selected.length === 0) return
    const syncRows: BankSyncRow[] = selected.map((r) => ({
      date:         r.entryDate,
      description:  r.description,
      ledger:       r.ledger.trim(),
      voucherType:  r.voucherType,
      amount:       Math.abs(r.debit ?? r.credit ?? 0),
      isPayment:    r.credit != null,
      narration:    r.narration.trim() || r.description,
      originalDate: r.date,
    }))
    await onSync(syncRows, cashLedger)
  }

  const selectedCount = rows.filter((r) => r.selected).length
  const mappedCount   = rows.filter((r) => r.selected && r.ledger.trim()).length
  const readyToSync   = mappedCount > 0 && cashLedger.trim()

  return (
    <div className="flex flex-col h-full">
      {/* Cash ledger header */}
      <div className="px-6 py-4 border-b border-border bg-card flex items-center gap-4 flex-wrap">
        <div className="flex items-center gap-2 text-sm font-semibold text-foreground">
          <span>{statement.bankName}</span>
          {statement.accountNumber && (
            <span className="text-xs text-muted-foreground font-normal">· A/c {statement.accountNumber}</span>
          )}
        </div>
        <div className="flex items-center gap-2 ml-auto">
          <label className="text-xs font-semibold text-muted-foreground whitespace-nowrap">Cash Ledger *</label>
          <div className="relative">
            <input
              list="cash-ledger-main-list"
              value={cashLedger}
              onChange={(e) => onCashLedgerChange(e.target.value)}
              placeholder="Select cash account ledger…"
              autoComplete="off"
              className="input-base text-sm w-64"
            />
            <datalist id="cash-ledger-main-list">
              {cashLedgerNames.map((n) => <option key={n} value={n} />)}
            </datalist>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="flex-1 overflow-y-auto overflow-x-auto px-4 py-2">
        <table className="w-full text-xs border-collapse" style={{ minWidth: 900 }}>
          <colgroup>
            <col style={{ width: 32 }} />
            <col style={{ width: 130 }} />
            <col />
            <col style={{ width: 140 }} />
            <col style={{ width: 160 }} />
            <col style={{ width: 100 }} />
            <col style={{ width: 80 }} />
            <col style={{ width: 80 }} />
            <col style={{ width: 80 }} />
          </colgroup>
          <thead className="sticky top-0 z-10 bg-muted border-b border-border">
            <tr>
              <th className="px-3 py-2.5 text-left">
                <input type="checkbox" checked={allSelected} onChange={toggleAll} className="rounded" />
              </th>
              <th className="px-2 py-2.5 text-left font-semibold text-muted-foreground whitespace-nowrap">Date</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Description</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Ledger</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Narration</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground whitespace-nowrap">Voucher Type</th>
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
                  row.synced ? 'bg-emerald-50/50' : 'hover:bg-muted',
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
                <td className="px-2 py-1.5">
                  <input
                    type="date"
                    value={row.entryDate}
                    disabled={row.synced}
                    onChange={(e) => updateRow(row.id, { entryDate: e.target.value })}
                    className="w-full text-xs px-1.5 py-1 border border-border rounded-lg bg-card text-foreground outline-none transition-all focus:border-brand-500 focus:ring-2 focus:ring-brand-500/10 disabled:bg-muted disabled:text-muted-foreground"
                  />
                </td>
                <td className="px-3 py-2">
                  <span className="block text-foreground break-words leading-snug line-clamp-3">{row.description}</span>
                </td>
                <td className="px-3 py-1.5">
                  {row.synced ? (
                    <span className="flex items-center gap-1 text-emerald-600 text-xs font-medium">
                      <CheckCircle2 className="w-3.5 h-3.5 flex-shrink-0" />
                      Already Synced
                    </span>
                  ) : (
                    <>
                      <input
                        list={`cash-ledger-row-${row.id}`}
                        value={row.ledger}
                        onChange={(e) => updateRow(row.id, { ledger: e.target.value })}
                        placeholder="Select ledger…"
                        autoComplete="off"
                        className={cn(
                          'w-full text-xs px-2.5 py-1 border border-border rounded-lg bg-card text-foreground outline-none transition-all focus:border-brand-500 focus:ring-2 focus:ring-brand-500/10',
                          row.selected && !row.ledger.trim() && 'border-amber-300 bg-amber-50',
                        )}
                      />
                      <datalist id={`cash-ledger-row-${row.id}`}>
                        {ledgerNames.map((n) => <option key={n} value={n} />)}
                      </datalist>
                    </>
                  )}
                </td>
                <td className="px-3 py-1.5">
                  <input
                    type="text"
                    value={row.narration}
                    disabled={row.synced}
                    onChange={(e) => updateRow(row.id, { narration: e.target.value })}
                    placeholder="Narration…"
                    className="w-full text-xs px-2.5 py-1 border border-border rounded-lg bg-card text-foreground outline-none transition-all focus:border-brand-500 focus:ring-2 focus:ring-brand-500/10 disabled:bg-muted disabled:text-muted-foreground"
                  />
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
      <div className="flex items-center justify-between px-6 py-3 border-t border-border bg-card gap-4 flex-wrap">
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
          {!cashLedger.trim() && (
            <span className="text-xs text-amber-600 font-medium">Set Cash Ledger first</span>
          )}
          <Button
            variant="teal"
            onClick={handleSync}
            loading={syncing}
            disabled={!readyToSync || syncing}
          >
            <Zap className="w-3.5 h-3.5 mr-1.5" />
            Push {mappedCount > 0 ? `${mappedCount} Vouchers` : ''}
          </Button>
        </div>
      </div>
    </div>
  )
}
