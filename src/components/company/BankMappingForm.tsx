import { useState, useMemo } from 'react'
import { ChevronLeft, ChevronRight, Zap } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { cn, formatCurrency } from '@/lib/utils'
import type { BankTransaction, ParsedBankStatement, TallyLedger } from '@/types'
import type { BankSyncRow } from '@/services/tallyService'

const PAGE_SIZE = 15

const DEFAULT_VOUCHER_TYPES = ['Payment', 'Receipt', 'Journal', 'Contra']

interface BankMappingFormProps {
  statement: ParsedBankStatement
  bankLedger: string
  onBankLedgerChange: (v: string) => void
  ledgers: TallyLedger[]
  voucherTypes: string[]
  onSync: (rows: BankSyncRow[], bankLedger: string) => Promise<void>
  syncing: boolean
}

export function BankMappingForm({
  statement,
  bankLedger,
  onBankLedgerChange,
  ledgers,
  voucherTypes,
  onSync,
  syncing,
}: BankMappingFormProps) {
  const allVoucherTypes = useMemo(
    () => (voucherTypes.length > 0 ? voucherTypes : DEFAULT_VOUCHER_TYPES),
    [voucherTypes],
  )

  const [rows, setRows] = useState<BankTransaction[]>(() =>
    statement.transactions.map((t) => ({
      ...t,
      ledger:      '',
      voucherType: t.debit != null ? 'Receipt' : 'Payment',
      selected:    true,
    })),
  )
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
      <div className="px-6 py-4 border-b border-gray-100 bg-white flex items-center gap-4 flex-wrap">
        <div className="flex items-center gap-2 text-sm font-semibold text-gray-700">
          <span>{statement.bankName}</span>
          {statement.accountNumber && (
            <span className="text-xs text-gray-400 font-normal">· A/c {statement.accountNumber}</span>
          )}
        </div>
        <div className="flex items-center gap-2 ml-auto">
          <label className="text-xs font-semibold text-gray-600 whitespace-nowrap">Bank Ledger *</label>
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
              {ledgerNames.map((n) => <option key={n} value={n} />)}
            </datalist>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="flex-1 overflow-auto">
        <table className="w-full text-xs border-collapse">
          <thead className="sticky top-0 z-10 bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-3 py-2.5 text-left w-8">
                <input
                  type="checkbox"
                  checked={allSelected}
                  onChange={toggleAll}
                  className="rounded"
                />
              </th>
              <th className="px-3 py-2.5 text-left font-semibold text-gray-600 whitespace-nowrap">Date</th>
              <th className="px-3 py-2.5 text-left font-semibold text-gray-600">Description</th>
              <th className="px-3 py-2.5 text-left font-semibold text-gray-600 min-w-44">Ledger</th>
              <th className="px-3 py-2.5 text-left font-semibold text-gray-600 min-w-32">Voucher Type</th>
              <th className="px-3 py-2.5 text-right font-semibold text-gray-600 whitespace-nowrap">Debit<br /><span className="font-normal text-gray-400">(Bank Credit)</span></th>
              <th className="px-3 py-2.5 text-right font-semibold text-gray-600 whitespace-nowrap">Credit<br /><span className="font-normal text-gray-400">(Bank Debit)</span></th>
              <th className="px-3 py-2.5 text-right font-semibold text-gray-600">Amount</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {pageRows.map((row) => (
              <tr
                key={row.id}
                className={cn(
                  'hover:bg-gray-50 transition-colors',
                  !row.selected && 'opacity-40',
                )}
              >
                <td className="px-3 py-2">
                  <input
                    type="checkbox"
                    checked={row.selected}
                    onChange={(e) => updateRow(row.id, { selected: e.target.checked })}
                    className="rounded"
                  />
                </td>
                <td className="px-3 py-2 whitespace-nowrap text-gray-600">{row.date}</td>
                <td className="px-3 py-2 max-w-xs">
                  <span className="line-clamp-2 text-gray-800">{row.description}</span>
                </td>
                <td className="px-3 py-2">
                  <input
                    list={`ledger-list-${row.id}`}
                    value={row.ledger}
                    onChange={(e) => updateRow(row.id, { ledger: e.target.value })}
                    placeholder="Select ledger…"
                    autoComplete="off"
                    className={cn(
                      'input-base w-full text-xs py-1',
                      row.selected && !row.ledger.trim() && 'border-amber-300 bg-amber-50',
                    )}
                  />
                  <datalist id={`ledger-list-${row.id}`}>
                    {ledgerNames.map((n) => <option key={n} value={n} />)}
                  </datalist>
                </td>
                <td className="px-3 py-2">
                  <select
                    value={row.voucherType}
                    onChange={(e) => updateRow(row.id, { voucherType: e.target.value })}
                    className="input-base w-full text-xs py-1"
                  >
                    {allVoucherTypes.map((v) => <option key={v} value={v}>{v}</option>)}
                  </select>
                </td>
                <td className="px-3 py-2 text-right text-teal-700 font-medium">
                  {row.debit != null ? formatCurrency(row.debit) : '—'}
                </td>
                <td className="px-3 py-2 text-right text-red-600 font-medium">
                  {row.credit != null ? formatCurrency(row.credit) : '—'}
                </td>
                <td className="px-3 py-2 text-right font-semibold text-gray-800">
                  {formatCurrency(Math.abs(row.debit ?? row.credit ?? 0))}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Footer: pagination + sync */}
      <div className="flex items-center justify-between px-6 py-3 border-t border-gray-100 bg-white gap-4 flex-wrap">
        {/* Pagination */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="p-1 rounded hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <span className="text-xs text-gray-600">
            Page {page} of {totalPages} · {rows.length} rows
          </span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page === totalPages}
            className="p-1 rounded hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>

        {/* Summary + sync */}
        <div className="flex items-center gap-3">
          <span className="text-xs text-gray-500">
            {mappedCount} of {selectedCount} selected rows mapped
          </span>
          {!bankLedger.trim() && (
            <span className="text-xs text-amber-600 font-medium">Set Bank Ledger first</span>
          )}
          <Button
            variant="teal"
            onClick={handleSync}
            loading={syncing}
            disabled={!readyToSync || syncing}
          >
            <Zap className="w-3.5 h-3.5 mr-1.5" />
            Sync {mappedCount > 0 ? `${mappedCount} Vouchers` : 'to Tally'}
          </Button>
        </div>
      </div>
    </div>
  )
}
