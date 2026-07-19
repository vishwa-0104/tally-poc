import { useState, useEffect } from 'react'
import { ChevronLeft, ChevronRight, Zap, Loader2, CheckCircle2 } from 'lucide-react'
import { Button } from '@/shadcn/components/ui/button'
import { cn, formatCurrency } from '@/lib/utils'
import { makeFingerprint } from '@/store/bankStore'
import type { BankTransaction, ParsedBankStatement, TallyLedger } from '@/types'
import type { BankSyncRow } from '@/services/tallyService'

const PAGE_SIZE = 15

const BANK_VOUCHER_TYPES = ['Contra', 'Payment', 'Receipt'] as const

interface BankMappingFormProps {
  statement: ParsedBankStatement
  bankLedger: string
  onBankLedgerChange: (v: string) => void
  ledgers: TallyLedger[]
  onSync: (rows: BankSyncRow[], bankLedger: string) => Promise<void>
  syncing: boolean
  fingerprintSet: Set<string>
}

export function BankMappingForm({
  statement,
  bankLedger,
  onBankLedgerChange,
  ledgers,
  onSync,
  syncing,
  fingerprintSet,
}: BankMappingFormProps) {
  const [rows, setRows] = useState<BankTransaction[]>(() =>
    statement.transactions.map((t) => {
      const alreadySynced = t.synced === true || fingerprintSet.has(
        makeFingerprint(statement.bankName, t.date, Math.abs(t.debit ?? t.credit ?? 0), t.description),
      )
      return {
        ...t,
        ledger: '',
        voucherType: (t.debit != null && t.credit != null)
          ? 'Contra'
          : t.debit != null
          ? 'Receipt'
          : 'Payment',
        synced:   alreadySynced,
        selected: !alreadySynced,
      }
    }),
  )
  useEffect(() => {
    if (fingerprintSet.size === 0) return
    setRows((prev) => prev.map((r) => {
      if (r.synced) return r
      const fp = makeFingerprint(statement.bankName, r.date, Math.abs(r.debit ?? r.credit ?? 0), r.description)
      if (!fingerprintSet.has(fp)) return r
      return { ...r, synced: true, selected: false }
    }))
  }, [fingerprintSet, statement.bankName]) // eslint-disable-line react-hooks/exhaustive-deps

  const [page, setPage] = useState(1)

  const totalPages = Math.max(1, Math.ceil(rows.length / PAGE_SIZE))
  const pageRows   = rows.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  const updateRow = (id: string, patch: Partial<BankTransaction>) =>
    setRows((prev) => prev.map((r) => (r.id === id ? { ...r, ...patch } : r)))

  const allSelected   = pageRows.every((r) => r.selected)
  const toggleAll     = () => {
    const ids = new Set(pageRows.map((r) => r.id))
    const next = !allSelected
    setRows((prev) => prev.map((r) => ids.has(r.id) ? { ...r, selected: next } : r))
  }

  const ledgerNames = ledgers.map((l) => l.name)

  // Bank Ledger field: only show Bank Accounts / Cash-in-Hand group ledgers
  const bankLedgerNames = (() => {
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
      date:        r.date,
      description: r.description,
      ledger:      r.ledger.trim(),
      voucherType: r.voucherType,
      amount:      Math.abs(r.debit ?? r.credit ?? 0),
      isPayment:   r.credit != null,
    }))
    await onSync(syncRows, bankLedger)
  }

  const selectedCount   = rows.filter((r) => r.selected).length
  const mappedCount     = rows.filter((r) => r.selected && r.ledger.trim()).length
  const readyToSync     = mappedCount > 0 && bankLedger.trim()

  return (
    <div className="flex flex-col h-full">
      {/* Bank ledger header */}
      <div className="px-6 py-4 border-b border-border bg-background flex items-center gap-4 flex-wrap">
        <div className="flex items-center gap-2 text-sm font-semibold text-foreground">
          <span>{statement.bankName}</span>
          {statement.accountNumber && (
            <span className="text-xs text-muted-foreground font-normal">· A/c {statement.accountNumber}</span>
          )}
        </div>
        <div className="flex items-center gap-2 ml-auto">
          <label className="text-xs font-semibold text-muted-foreground whitespace-nowrap">Bank Ledger *</label>
          <div className="relative">
            <input
              list="bank-ledger-list"
              value={bankLedger}
              onChange={(e) => onBankLedgerChange(e.target.value)}
              placeholder="Select bank account ledger…"
              autoComplete="off"
              className="input-base text-sm w-64"
            />
            <datalist id="bank-ledger-list">
              {bankLedgerNames.map((n) => <option key={n} value={n} />)}
            </datalist>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="flex-1 overflow-y-auto overflow-x-hidden px-4 py-2">
        <table className="w-full text-xs border-collapse table-fixed">
          <colgroup>
            <col className="w-[3%]" />
            <col className="w-[8%]" />
            <col className="w-20" />
            <col className="w-20" />
            <col className="w-12" />
            <col className="w-[9%]" />
            <col className="w-[9%]" />
            <col className="w-[9%]" />
          </colgroup>
          <thead className="sticky top-0 z-10 bg-muted border-b border-border">
            <tr>
              <th className="px-3 py-2.5 text-left">
                <input
                  type="checkbox"
                  checked={allSelected}
                  onChange={toggleAll}
                  className="rounded"
                />
              </th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground whitespace-nowrap">Date</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Description</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Ledger</th>
              <th className="px-3 py-2.5 text-left font-semibold text-muted-foreground">Voucher Type</th>
              <th className="px-2 py-2.5 text-right font-semibold text-muted-foreground whitespace-nowrap">Debit<br /><span className="font-normal text-muted-foreground/70">(Bank Cr)</span></th>
              <th className="px-2 py-2.5 text-right font-semibold text-muted-foreground whitespace-nowrap">Credit<br /><span className="font-normal text-muted-foreground/70">(Bank Dr)</span></th>
              <th className="px-2 py-2.5 text-right font-semibold text-muted-foreground">Amount</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {pageRows.map((row) => (
              <tr
                key={row.id}
                className={cn(
                  'transition-colors',
                  row.synced ? 'bg-emerald-500/10' : 'hover:bg-muted/50',
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
                  <span className="block text-foreground break-words leading-snug line-clamp-3">{row.description}</span>
                </td>
                <td className="px-3 py-1.5">
                  {row.synced ? (
                    <span className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400 text-xs font-medium">
                      <CheckCircle2 className="w-3.5 h-3.5 flex-shrink-0" />
                      Already Synced
                    </span>
                  ) : (
                    <>
                      <input
                        list={`ledger-list-${row.id}`}
                        value={row.ledger}
                        onChange={(e) => updateRow(row.id, { ledger: e.target.value })}
                        placeholder="Select ledger…"
                        autoComplete="off"
                        className={cn(
                          'w-full text-xs px-2.5 py-1 border border-border rounded-lg bg-background text-foreground outline-none transition-all focus:border-primary focus:ring-2 focus:ring-primary/10',
                          row.selected && !row.ledger.trim() && 'border-amber-500/50 bg-amber-500/10',
                        )}
                      />
                      <datalist id={`ledger-list-${row.id}`}>
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
                    className="w-full text-xs px-2.5 py-1 border border-border rounded-lg bg-background text-foreground outline-none transition-all focus:border-primary focus:ring-2 focus:ring-primary/10 disabled:bg-muted disabled:text-muted-foreground"
                  >
                    {BANK_VOUCHER_TYPES.map((v) => <option key={v} value={v}>{v}</option>)}
                  </select>
                </td>
                <td className="px-2 py-2 text-right text-emerald-600 dark:text-emerald-400 font-medium truncate" title={row.debit != null ? formatCurrency(row.debit) : '—'}>
                  {row.debit != null ? formatCurrency(row.debit) : '—'}
                </td>
                <td className="px-2 py-2 text-right text-red-600 dark:text-red-400 font-medium truncate" title={row.credit != null ? formatCurrency(row.credit) : '—'}>
                  {row.credit != null ? formatCurrency(row.credit) : '—'}
                </td>
                <td className="px-2 py-2 text-right font-semibold text-foreground truncate" title={formatCurrency(Math.abs(row.debit ?? row.credit ?? 0))}>
                  {formatCurrency(Math.abs(row.debit ?? row.credit ?? 0))}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Footer: pagination + sync */}
      <div className="flex items-center justify-between px-6 py-3 border-t border-border bg-background gap-4 flex-wrap">
        {/* Pagination */}
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

        {/* Summary + sync */}
        <div className="flex items-center gap-3">
          <span className="text-xs text-muted-foreground">
            {mappedCount} of {selectedCount} selected rows mapped
          </span>
          {!bankLedger.trim() && (
            <span className="text-xs text-amber-600 dark:text-amber-400 font-medium">Set Bank Ledger first</span>
          )}
          <Button
            onClick={handleSync}
            disabled={!readyToSync || syncing}
          >
            {syncing ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Zap className="w-3.5 h-3.5" />}
            Push {mappedCount > 0 ? `${mappedCount} Vouchers` : ''}
          </Button>
        </div>
      </div>
    </div>
  )
}
