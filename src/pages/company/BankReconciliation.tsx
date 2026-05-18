import { useRef, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { toast } from 'react-hot-toast'
import { Upload, Loader2, FileText, Scale, ChevronLeft, ChevronRight, X, CheckCircle2 } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { useAuthStore, useCompanyStore } from '@/store'
import { api } from '@/lib/api'
import { parseCsvBankStatement } from '@/lib/bankParser'
import { formatCurrency } from '@/lib/utils'
import type { ParsedBankStatement } from '@/types'
import { COMPANY_FEATURES } from '@/types'

const PAGE_SIZE = 15

// source 'A' = exists in bank, missing from books
// source 'B' = exists in books, not seen in bank statement
interface DiffRow {
  id: string
  date: string
  description: string
  debit: number | null
  credit: number | null
  source: 'A' | 'B'
}

function reconcile(bank: ParsedBankStatement, books: ParsedBankStatement): DiffRow[] {
  const makeKey = (t: { date: string; debit: number | null; credit: number | null }) =>
    `${t.date}|${Math.abs(t.debit ?? t.credit ?? 0).toFixed(2)}`

  const matchedBooksIdx = new Set<number>()
  const missingFromBooks: DiffRow[] = []

  for (const bt of bank.transactions) {
    const key = makeKey(bt)
    const idx = books.transactions.findIndex((rt, i) => !matchedBooksIdx.has(i) && makeKey(rt) === key)
    if (idx >= 0) {
      matchedBooksIdx.add(idx)
    } else {
      missingFromBooks.push({ id: bt.id, date: bt.date, description: bt.description, debit: bt.debit, credit: bt.credit, source: 'A' })
    }
  }

  const extraInBooks: DiffRow[] = books.transactions
    .filter((_, i) => !matchedBooksIdx.has(i))
    .map((rt) => ({ id: rt.id, date: rt.date, description: rt.description, debit: rt.debit, credit: rt.credit, source: 'B' }))

  return [...missingFromBooks, ...extraInBooks].sort((x, y) => x.date.localeCompare(y.date))
}

// ── Upload side sub-component ─────────────────────────────────────────────────

interface UploadSideProps {
  label: string
  hint: string
  sourceName?: string
  count?: number
  fileName: string
  parsing: boolean
  inputRef: React.RefObject<HTMLInputElement>
  onSelect: (file: File) => void
  onClear: () => void
}

function UploadSide({ label, hint, sourceName, count, fileName, parsing, inputRef, onSelect, onClear }: UploadSideProps) {
  const loaded = !!sourceName && !parsing

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    const file = e.dataTransfer.files[0]
    if (file) onSelect(file)
  }

  return (
    <div className="flex-1 p-6">
      <p className="text-xs font-semibold text-gray-700 uppercase tracking-wide mb-0.5">{label}</p>
      <p className="text-[11px] text-gray-400 mb-3">{hint}</p>

      {loaded ? (
        <div className="rounded-xl border border-emerald-200 bg-emerald-50/60 px-5 py-4 flex items-start gap-3">
          <CheckCircle2 className="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5" />
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-gray-800 truncate">{sourceName}</p>
            <p className="text-xs text-gray-500 mt-0.5">{count} entries · {fileName}</p>
          </div>
          <button
            onClick={onClear}
            className="p-1 rounded hover:bg-emerald-100 text-gray-400 hover:text-gray-600 flex-shrink-0"
            title="Remove"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      ) : parsing ? (
        <div className="rounded-xl border border-gray-200 bg-gray-50 px-5 py-6 flex flex-col items-center gap-2 text-gray-400">
          <Loader2 className="w-6 h-6 animate-spin text-teal-500" />
          <p className="text-xs">Reading {fileName}…</p>
        </div>
      ) : (
        <div
          onDrop={handleDrop}
          onDragOver={(e) => e.preventDefault()}
          onClick={() => inputRef.current?.click()}
          className="rounded-xl border-2 border-dashed border-gray-200 hover:border-teal-400 bg-gray-50/50 hover:bg-teal-50/30 transition-colors cursor-pointer px-5 py-8 flex flex-col items-center gap-2 text-gray-400 hover:text-teal-600"
        >
          <div className="w-10 h-10 rounded-lg bg-white border border-gray-200 flex items-center justify-center mb-1">
            <Upload className="w-5 h-5" />
          </div>
          <p className="text-xs font-medium">Drop file here or click to browse</p>
          <p className="text-[11px] text-gray-400">CSV, PDF, JPG, PNG supported</p>
        </div>
      )}

      <input
        ref={inputRef}
        type="file"
        accept=".csv,.pdf,.jpg,.jpeg,.png,.webp"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0]
          if (file) onSelect(file)
          e.target.value = ''
        }}
      />
    </div>
  )
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function BankReconciliation() {
  const { activeCompanyId } = useAuthStore()
  const { getCompany, companiesLoaded } = useCompanyStore()

  const refBank  = useRef<HTMLInputElement>(null)
  const refBooks = useRef<HTMLInputElement>(null)

  const [stmtBank,      setStmtBank]      = useState<ParsedBankStatement | null>(null)
  const [stmtBooks,     setStmtBooks]     = useState<ParsedBankStatement | null>(null)
  const [fileNameBank,  setFileNameBank]  = useState('')
  const [fileNameBooks, setFileNameBooks] = useState('')
  const [parsingBank,   setParsingBank]   = useState(false)
  const [parsingBooks,  setParsingBooks]  = useState(false)
  const [diffs,         setDiffs]         = useState<DiffRow[]>([])
  const [compared,      setCompared]      = useState(false)
  const [page,          setPage]          = useState(1)

  const companyId = activeCompanyId ?? ''
  const company   = getCompany(companyId) ?? null

  const hasBankReconcile = (company?.features ?? []).some(
    (f) => f.feature === COMPANY_FEATURES.BANK_RECONCILE && f.enabled,
  )

  if (!companiesLoaded) return null
  if (!hasBankReconcile) return <Navigate to="/company" replace />

  const parseFile = async (
    file: File,
    setStmt:     (s: ParsedBankStatement) => void,
    setFileName: (n: string) => void,
    setParsing:  (v: boolean) => void,
  ) => {
    setParsing(true)
    setFileName(file.name)
    setCompared(false)
    setDiffs([])
    try {
      let parsed: ParsedBankStatement

      if (file.name.endsWith('.csv') || file.type === 'text/csv' || file.type === 'application/vnd.ms-excel') {
        const text = await file.text()
        parsed = parseCsvBankStatement(text, file.name)
        if (parsed.transactions.length === 0) {
          toast.error('No entries found. Check the CSV has Date, Description, and Debit/Credit columns.')
          setFileName('')
          return
        }
      } else {
        const reader = new FileReader()
        const base64: string = await new Promise((resolve, reject) => {
          reader.onload  = () => resolve((reader.result as string).split(',')[1])
          reader.onerror = reject
          reader.readAsDataURL(file)
        })
        const { data } = await api.post<ParsedBankStatement>('/bank/parse', {
          base64,
          mediaType: file.type || 'application/pdf',
          companyId,
        })
        if (!data.transactions?.length) {
          toast.error('No entries found in the document.')
          setFileName('')
          return
        }
        data.transactions = data.transactions.map((t, i) => ({
          ...t,
          id: (t as { id?: string }).id ?? `txn_${Date.now()}_${i}`,
        }))
        parsed = data
      }

      setStmt(parsed)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to read file')
      setFileName('')
    } finally {
      setParsing(false)
    }
  }

  const handleCompare = () => {
    if (!stmtBank || !stmtBooks) return
    const result = reconcile(stmtBank, stmtBooks)
    setDiffs(result)
    setCompared(true)
    setPage(1)
  }

  const missingFromBooks = diffs.filter((d) => d.source === 'A').length  // in bank, not in books
  const extraInBooks     = diffs.filter((d) => d.source === 'B').length  // in books, not in bank
  const totalPages       = Math.ceil(diffs.length / PAGE_SIZE)
  const pageDiffs        = diffs.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  return (
    <>
      <PageHeader
        title={company?.name ? `${company.name} — Reconciliation` : 'Bank Reconciliation'}
        subtitle="Match your bank statement against your book records to spot missing or extra entries"
      />

      <div className="p-4 md:p-7 space-y-5">

        {/* ── Upload panel ── */}
        <div className="card overflow-hidden">
          <div className="flex divide-x divide-gray-100">
            <UploadSide
              label="Bank Statement"
              hint="Official statement downloaded from your bank"
              sourceName={stmtBank?.bankName}
              count={stmtBank?.transactions.length}
              fileName={fileNameBank}
              parsing={parsingBank}
              inputRef={refBank}
              onSelect={(f) => parseFile(f, setStmtBank, setFileNameBank, setParsingBank)}
              onClear={() => { setStmtBank(null); setFileNameBank(''); setCompared(false); setDiffs([]) }}
            />
            <UploadSide
              label="Book Records"
              hint="Exported day book or ledger entries from your accounting software"
              sourceName={stmtBooks?.bankName}
              count={stmtBooks?.transactions.length}
              fileName={fileNameBooks}
              parsing={parsingBooks}
              inputRef={refBooks}
              onSelect={(f) => parseFile(f, setStmtBooks, setFileNameBooks, setParsingBooks)}
              onClear={() => { setStmtBooks(null); setFileNameBooks(''); setCompared(false); setDiffs([]) }}
            />
          </div>

          <div className="border-t border-gray-100 px-6 py-4 flex justify-center">
            <Button
              variant="teal"
              size="sm"
              disabled={!stmtBank || !stmtBooks || parsingBank || parsingBooks}
              onClick={handleCompare}
            >
              <Scale className="w-4 h-4" />
              Reconcile
            </Button>
          </div>
        </div>

        {/* ── Results panel ── */}
        {compared && (
          <div className="card overflow-hidden">
            <div className="px-5 py-4 border-b border-gray-100 flex items-start justify-between gap-4">
              <div>
                <h2 className="text-sm font-semibold text-gray-900">Reconciliation Report</h2>
                <p className="text-xs text-gray-500 mt-0.5">
                  {diffs.length === 0
                    ? 'Bank statement and book records are fully reconciled'
                    : `${diffs.length} unmatched entr${diffs.length !== 1 ? 'ies' : 'y'} found`}
                </p>
              </div>

              {diffs.length > 0 && (
                <div className="flex items-center gap-4 text-xs flex-shrink-0">
                  <span className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-red-400 inline-block" />
                    <span className="text-gray-600">
                      <span className="font-semibold text-gray-800">{missingFromBooks}</span> missing from books
                    </span>
                  </span>
                  <span className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-amber-400 inline-block" />
                    <span className="text-gray-600">
                      <span className="font-semibold text-gray-800">{extraInBooks}</span> extra in books
                    </span>
                  </span>
                </div>
              )}
            </div>

            {diffs.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16 gap-3 text-gray-400">
                <div className="w-12 h-12 rounded-full bg-teal-50 flex items-center justify-center">
                  <Scale className="w-6 h-6 text-teal-500" />
                </div>
                <p className="text-sm font-medium text-gray-700">Books and bank are in sync</p>
                <p className="text-xs">Every bank entry has a matching record in your books</p>
              </div>
            ) : (
              <>
                <div className="overflow-x-auto">
                  <table className="w-full text-xs">
                    <colgroup>
                      <col className="w-[10%]" />
                      <col />
                      <col className="w-[12%]" />
                      <col className="w-[12%]" />
                      <col className="w-[22%]" />
                    </colgroup>
                    <thead>
                      <tr className="border-b border-gray-100 bg-gray-50/60">
                        <th className="text-left px-4 py-2.5 font-medium text-gray-500">Date</th>
                        <th className="text-left px-4 py-2.5 font-medium text-gray-500">Description</th>
                        <th className="text-right px-4 py-2.5 font-medium text-gray-500">Received</th>
                        <th className="text-right px-4 py-2.5 font-medium text-gray-500">Paid</th>
                        <th className="text-center px-4 py-2.5 font-medium text-gray-500">Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {pageDiffs.map((row) => (
                        <tr
                          key={row.id}
                          className={row.source === 'A' ? 'bg-red-50/40 hover:bg-red-50/70' : 'bg-amber-50/40 hover:bg-amber-50/70'}
                        >
                          <td className="px-4 py-2.5 text-gray-600 tabular-nums whitespace-nowrap">{row.date}</td>
                          <td className="px-4 py-2.5 text-gray-800 max-w-0">
                            <span className="block truncate" title={row.description}>{row.description || '—'}</span>
                          </td>
                          <td
                            className="px-4 py-2.5 text-right tabular-nums text-emerald-700"
                            title={row.debit != null ? formatCurrency(row.debit) : undefined}
                          >
                            {row.debit != null ? formatCurrency(row.debit) : <span className="text-gray-300">—</span>}
                          </td>
                          <td
                            className="px-4 py-2.5 text-right tabular-nums text-red-600"
                            title={row.credit != null ? formatCurrency(row.credit) : undefined}
                          >
                            {row.credit != null ? formatCurrency(row.credit) : <span className="text-gray-300">—</span>}
                          </td>
                          <td className="px-4 py-2.5 text-center">
                            {row.source === 'A' ? (
                              <span className="inline-block px-2 py-0.5 rounded-full text-[10px] font-medium bg-red-100 text-red-700">
                                Missing from books
                              </span>
                            ) : (
                              <span className="inline-block px-2 py-0.5 rounded-full text-[10px] font-medium bg-amber-100 text-amber-700">
                                Extra in books
                              </span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {totalPages > 1 && (
                  <div className="px-4 py-3 border-t border-gray-100 flex items-center justify-between">
                    <span className="text-xs text-gray-400">
                      Showing {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, diffs.length)} of {diffs.length}
                    </span>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => setPage((p) => Math.max(1, p - 1))}
                        disabled={page === 1}
                        className="p-1 rounded hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed"
                      >
                        <ChevronLeft className="w-4 h-4 text-gray-500" />
                      </button>

                      {Array.from({ length: totalPages }, (_, i) => i + 1)
                        .filter((p) => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
                        .reduce<(number | '...')[]>((acc, p, i, arr) => {
                          if (i > 0 && (p as number) - (arr[i - 1] as number) > 1) acc.push('...')
                          acc.push(p)
                          return acc
                        }, [])
                        .map((p, i) =>
                          p === '...' ? (
                            <span key={`e${i}`} className="px-1 text-xs text-gray-400">…</span>
                          ) : (
                            <button
                              key={p}
                              onClick={() => setPage(p as number)}
                              className={`w-6 h-6 rounded text-xs font-medium transition-colors ${
                                page === p ? 'bg-teal-600 text-white' : 'hover:bg-gray-100 text-gray-600'
                              }`}
                            >
                              {p}
                            </button>
                          )
                        )}

                      <button
                        onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                        disabled={page === totalPages}
                        className="p-1 rounded hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed"
                      >
                        <ChevronRight className="w-4 h-4 text-gray-500" />
                      </button>
                    </div>
                  </div>
                )}
              </>
            )}
          </div>
        )}

        {/* ── Prompt before first reconcile ── */}
        {!compared && stmtBank && stmtBooks && (
          <div className="card flex flex-col items-center justify-center py-14 gap-2 text-gray-400">
            <FileText className="w-8 h-8" />
            <p className="text-sm">
              Both files loaded — click{' '}
              <span className="font-medium text-gray-600">Reconcile</span> to find discrepancies
            </p>
          </div>
        )}
      </div>
    </>
  )
}
