import { useRef, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { toast } from 'react-hot-toast'
import {
  Upload, Loader2, Scale, ChevronLeft, ChevronRight,
  X, CheckCircle2, Trash2, Plus, Eye,
} from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { EmptyState } from '@/components/ui/EmptyState'
import { useAuthStore, useCompanyStore } from '@/store'
import { api } from '@/lib/api'
import { parseCsvBankStatement } from '@/lib/bankParser'
import { formatDate } from '@/lib/utils'
import type { ParsedBankStatement } from '@/types'
import { COMPANY_FEATURES } from '@/types'
import { useReconciliationStore } from '@/store/reconciliationStore'
import type { ReconciliationRow } from '@/store/reconciliationStore'

// ── Reconcile logic ───────────────────────────────────────────────────────────

type Tx = ParsedBankStatement['transactions'][number]

/**
 * Extract solid reference tokens from a transaction description.
 * Looks for: UTR numbers, NEFT/RTGS/IMPS/UPI/cheque ref codes, and any
 * standalone 8+ digit numeric sequence (typical for Indian bank identifiers).
 */
function extractRefs(desc: string): Set<string> {
  const d = desc.toUpperCase()
  const found = new Set<string>()

  // Named-prefix references: UTR, REF, TXN, NEFT, RTGS, IMPS, UPI, CHQ, CHEQUE, TRANS
  const prefixRe =
    /(?:UTR(?:NO|N)?|REF(?:NO|#|\s)?|TXN(?:ID|NO|#|\s)?|NEFT|RTGS|IMPS|UPI(?:REF)?|CH(?:EQU?E?)?(?:NO|#|\s)?|TRANS(?:ACTION)?(?:ID|NO)?)[/\-#\s.:]*([A-Z0-9]{6,})/g
  let m: RegExpExecArray | null
  while ((m = prefixRe.exec(d)) !== null) found.add(m[1])

  // Standalone 8+ digit numbers (UTR=16, IMPS=12, NEFT ref=16, etc.)
  const longNumRe = /\b(\d{8,})\b/g
  while ((m = longNumRe.exec(d)) !== null) found.add(m[1])

  // Alphanumeric codes that start with 1–4 letters then 8+ digits (e.g. P23345678901)
  const alphaRe = /\b([A-Z]{1,4}\d{8,})\b/g
  while ((m = alphaRe.exec(d)) !== null) found.add(m[1])

  return found
}

/**
 * Return the first token that appears in both sets,
 * also checking containment for truncated variants.
 */
function findCommonRef(a: Set<string>, b: Set<string>): string | null {
  for (const av of a) {
    if (b.has(av)) return av
    for (const bv of b) {
      if (av.length >= 6 && bv.length >= 6 && (av.includes(bv) || bv.includes(av))) {
        return av.length <= bv.length ? av : bv
      }
    }
  }
  return null
}

/** Direction-aware amount key so ₹5000 received ≠ ₹5000 paid */
function amtKey(t: Tx): string {
  if (t.debit  != null && t.debit  > 0) return `D${t.debit.toFixed(2)}`
  if (t.credit != null && t.credit > 0) return `C${t.credit.toFixed(2)}`
  return 'Z0.00'
}

const STOP_WORDS = new Set([
  'neft','rtgs','imps','upi','from','payment','transfer','bank','and','for',
  'with','pvt','ltd','private','limited','the','account','acct','being','towards',
])

/** Meaningful word overlap ratio — ignores stop words and short tokens */
function wordOverlap(a: string, b: string): number {
  const words = (s: string) =>
    new Set(
      s.toLowerCase().replace(/[^a-z0-9\s]/g, ' ').split(/\s+/)
        .filter(w => w.length > 3 && !STOP_WORDS.has(w))
    )
  const wa = words(a), wb = words(b)
  if (wa.size === 0 || wb.size === 0) return 0
  let common = 0
  for (const w of wa) if (wb.has(w)) common++
  return common / Math.min(wa.size, wb.size)
}

function reconcileAll(bank: ParsedBankStatement, books: ParsedBankStatement): ReconciliationRow[] {
  const usedBookIdx = new Set<number>()

  type BookEntry = { i: number; t: Tx; refs: Set<string>; amt: string }
  const booksData: BookEntry[] = books.transactions.map((t, i) => ({
    i, t, refs: extractRefs(t.description), amt: amtKey(t),
  }))

  type MatchResult = { matchIdx: number | null; matchBasis: ReconciliationRow['matchBasis']; matchToken?: string }
  const bankMatches: MatchResult[] = bank.transactions.map(() => ({ matchIdx: null, matchBasis: undefined }))

  // ── Pass 1: Reference token + amount (date-independent) ──────────────────
  bank.transactions.forEach((bt, bi) => {
    const bankRefs = extractRefs(bt.description)
    if (bankRefs.size === 0) return
    const bankAmt = amtKey(bt)
    for (const bd of booksData) {
      if (usedBookIdx.has(bd.i) || bd.amt !== bankAmt) continue
      const ref = findCommonRef(bankRefs, bd.refs)
      if (ref) {
        bankMatches[bi] = { matchIdx: bd.i, matchBasis: 'ref', matchToken: ref }
        usedBookIdx.add(bd.i)
        break
      }
    }
  })

  // ── Pass 2: Description word overlap ≥ 40% + amount (date-independent) ──
  bank.transactions.forEach((bt, bi) => {
    if (bankMatches[bi].matchIdx !== null) return
    const bankAmt = amtKey(bt)
    let best: { idx: number; score: number } | null = null
    for (const bd of booksData) {
      if (usedBookIdx.has(bd.i) || bd.amt !== bankAmt) continue
      const score = wordOverlap(bt.description, bd.t.description)
      if (score >= 0.4 && (!best || score > best.score)) best = { idx: bd.i, score }
    }
    if (best) {
      bankMatches[bi] = { matchIdx: best.idx, matchBasis: 'desc' }
      usedBookIdx.add(best.idx)
    }
  })

  // ── Pass 3: Amount-only, exactly ONE unmatched candidate (safe fallback) ──
  bank.transactions.forEach((bt, bi) => {
    if (bankMatches[bi].matchIdx !== null) return
    const bankAmt = amtKey(bt)
    const candidates = booksData.filter(bd => !usedBookIdx.has(bd.i) && bd.amt === bankAmt)
    if (candidates.length === 1) {
      bankMatches[bi] = { matchIdx: candidates[0].i, matchBasis: 'amount' }
      usedBookIdx.add(candidates[0].i)
    }
  })

  const bankRows: ReconciliationRow[] = bank.transactions.map((bt, bi) => {
    const { matchIdx, matchBasis, matchToken } = bankMatches[bi]
    return {
      id: `bank_${bt.id}`, date: bt.date, description: bt.description,
      debit: bt.debit, credit: bt.credit, source: 'bank',
      matched: matchIdx !== null,
      matchBasis: matchIdx !== null ? matchBasis : undefined,
      matchToken,
    }
  })

  const booksRows: ReconciliationRow[] = books.transactions.map((rt, i) => ({
    id: `books_${rt.id}`, date: rt.date, description: rt.description,
    debit: rt.debit, credit: rt.credit, source: 'books' as const,
    matched: usedBookIdx.has(i),
  }))

  return [...bankRows, ...booksRows].sort((a, b) => {
    const d = a.date.localeCompare(b.date)
    if (d !== 0) return d
    if (a.source === 'bank' && b.source === 'books') return -1
    if (a.source === 'books' && b.source === 'bank') return 1
    return 0
  })
}

// ── Upload side ───────────────────────────────────────────────────────────────

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
  return (
    <div className="flex-1 p-5">
      <p className="text-xs font-semibold text-gray-700 uppercase tracking-wide mb-0.5">{label}</p>
      <p className="text-[11px] text-gray-400 mb-3">{hint}</p>

      {loaded ? (
        <div className="rounded-xl border border-emerald-200 bg-emerald-50/60 px-4 py-3 flex items-start gap-3">
          <CheckCircle2 className="w-4 h-4 text-emerald-500 flex-shrink-0 mt-0.5" />
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-gray-800 truncate">{sourceName}</p>
            <p className="text-xs text-gray-500 mt-0.5">{count} entries · {fileName}</p>
          </div>
          <button onClick={onClear} className="p-1 rounded hover:bg-emerald-100 text-gray-400 hover:text-gray-600 flex-shrink-0">
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      ) : parsing ? (
        <div className="rounded-xl border border-gray-200 bg-gray-50 px-4 py-5 flex flex-col items-center gap-2 text-gray-400">
          <Loader2 className="w-5 h-5 animate-spin text-teal-500" />
          <p className="text-xs">Reading {fileName}…</p>
        </div>
      ) : (
        <div
          onDrop={(e) => { e.preventDefault(); const f = e.dataTransfer.files[0]; if (f) onSelect(f) }}
          onDragOver={(e) => e.preventDefault()}
          onClick={() => inputRef.current?.click()}
          className="rounded-xl border-2 border-dashed border-gray-200 hover:border-teal-400 bg-gray-50/50 hover:bg-teal-50/30 transition-colors cursor-pointer px-4 py-6 flex flex-col items-center gap-1.5 text-gray-400 hover:text-teal-600"
        >
          <Upload className="w-5 h-5 mb-0.5" />
          <p className="text-xs font-medium">Drop file or click to browse</p>
          <p className="text-[11px] text-gray-400">CSV, PDF, JPG, PNG</p>
        </div>
      )}
      <input ref={inputRef} type="file" accept=".csv,.pdf,.jpg,.jpeg,.png,.webp" className="hidden"
        onChange={(e) => { const f = e.target.files?.[0]; if (f) onSelect(f); e.target.value = '' }} />
    </div>
  )
}

// ── Page ──────────────────────────────────────────────────────────────────────

const PAGE_SIZE = 10

export default function BankReconciliation() {
  const navigate              = useNavigate()
  const { activeCompanyId }   = useAuthStore()
  const { getCompany, companiesLoaded } = useCompanyStore()
  const { addRecord, removeRecord, getRecords } = useReconciliationStore()

  const refBank  = useRef<HTMLInputElement>(null)
  const refBooks = useRef<HTMLInputElement>(null)

  const [showUpload,    setShowUpload]    = useState(false)
  const [stmtBank,      setStmtBank]      = useState<ParsedBankStatement | null>(null)
  const [stmtBooks,     setStmtBooks]     = useState<ParsedBankStatement | null>(null)
  const [fileNameBank,  setFileNameBank]  = useState('')
  const [fileNameBooks, setFileNameBooks] = useState('')
  const [parsingBank,   setParsingBank]   = useState(false)
  const [parsingBooks,  setParsingBooks]  = useState(false)
  const [page,          setPage]          = useState(1)

  const companyId = activeCompanyId ?? ''
  const company   = getCompany(companyId) ?? null
  const records   = getRecords(companyId)

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
    try {
      let parsed: ParsedBankStatement
      if (file.name.endsWith('.csv') || file.type === 'text/csv' || file.type === 'application/vnd.ms-excel') {
        const text = await file.text()
        parsed = parseCsvBankStatement(text, file.name)
        if (!parsed.transactions.length) {
          toast.error('No entries found. Check the CSV has Date, Description, and Debit/Credit columns.')
          setFileName(''); return
        }
      } else {
        const reader = new FileReader()
        const base64: string = await new Promise((res, rej) => {
          reader.onload  = () => res((reader.result as string).split(',')[1])
          reader.onerror = rej
          reader.readAsDataURL(file)
        })
        const { data } = await api.post<ParsedBankStatement>('/bank/parse', { base64, mediaType: file.type || 'application/pdf', companyId })
        if (!data.transactions?.length) { toast.error('No entries found in the document.'); setFileName(''); return }
        data.transactions = data.transactions.map((t, i) => ({ ...t, id: (t as { id?: string }).id ?? `txn_${Date.now()}_${i}` }))
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

  const handleReconcile = () => {
    if (!stmtBank || !stmtBooks) return
    const rows  = reconcileAll(stmtBank, stmtBooks)
    const stats = {
      totalBank:        stmtBank.transactions.length,
      totalBooks:       stmtBooks.transactions.length,
      matched:          rows.filter((r) => r.source === 'bank' && r.matched).length,
      missingFromBooks: rows.filter((r) => r.source === 'bank' && !r.matched).length,
      extraInBooks:     rows.filter((r) => r.source === 'books' && !r.matched).length,
    }
    const record = {
      id:            `rec_${Date.now()}`,
      companyId,
      bankName:      stmtBank.bankName  || fileNameBank.replace(/\.[^.]+$/, ''),
      booksName:     stmtBooks.bankName || fileNameBooks.replace(/\.[^.]+$/, ''),
      bankFileName:  fileNameBank,
      booksFileName: fileNameBooks,
      createdAt:     new Date().toISOString(),
      stats,
      rows,
    }
    addRecord(record)
    toast.success(`Report saved — ${stats.matched} matched, ${stats.missingFromBooks} missing from books`)
    navigate(`/company/reconcile/${record.id}`)
  }

  const handleDelete = (id: string, name: string) => {
    if (!window.confirm(`Delete reconciliation report "${name}"?`)) return
    removeRecord(id)
    toast.success('Report deleted')
  }

  const totalPages = Math.max(1, Math.ceil(records.length / PAGE_SIZE))
  const pageRecords = records.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  return (
    <>
      <PageHeader
        title={company?.name ? `${company.name} — Reconciliation` : 'Bank Reconciliation'}
        subtitle="Match bank statement against book records to find missing or extra entries"
        actions={
          <Button variant="teal" size="sm" onClick={() => setShowUpload((v) => !v)}>
            <Plus className="w-3.5 h-3.5" />
            New Report
          </Button>
        }
      />

      <div className="p-4 md:p-7 space-y-5">

        {/* ── Upload panel (toggle) ── */}
        {(showUpload || records.length === 0) && (
          <div className="card overflow-hidden">
            <div className="px-5 py-3 border-b border-gray-100 flex items-center justify-between">
              <h2 className="text-sm font-semibold text-gray-700">New Reconciliation</h2>
              {records.length > 0 && (
                <button onClick={() => setShowUpload(false)} className="p-1 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-600">
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>
            <div className="flex divide-x divide-gray-100">
              <UploadSide label="Bank Statement" hint="Official statement downloaded from your bank"
                sourceName={stmtBank?.bankName} count={stmtBank?.transactions.length}
                fileName={fileNameBank} parsing={parsingBank} inputRef={refBank}
                onSelect={(f) => parseFile(f, setStmtBank, setFileNameBank, setParsingBank)}
                onClear={() => { setStmtBank(null); setFileNameBank('') }}
              />
              <UploadSide label="Book Records" hint="Exported day book or ledger entries from your accounting software"
                sourceName={stmtBooks?.bankName} count={stmtBooks?.transactions.length}
                fileName={fileNameBooks} parsing={parsingBooks} inputRef={refBooks}
                onSelect={(f) => parseFile(f, setStmtBooks, setFileNameBooks, setParsingBooks)}
                onClear={() => { setStmtBooks(null); setFileNameBooks('') }}
              />
            </div>
            <div className="border-t border-gray-100 px-5 py-4 flex justify-center">
              <Button variant="teal" size="sm" disabled={!stmtBank || !stmtBooks || parsingBank || parsingBooks} onClick={handleReconcile}>
                <Scale className="w-4 h-4" />
                Reconcile & Save
              </Button>
            </div>
          </div>
        )}

        {/* ── Saved reports ── */}
        <div className="card overflow-hidden">
          {records.length === 0 ? (
            <EmptyState
              icon={Scale}
              title="No reconciliation reports yet"
              description="Upload a bank statement and book records to generate your first report"
            />
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full text-xs">
                  <thead>
                    <tr className="bg-gray-50 border-b border-gray-100">
                      {['Bank Statement', 'Book Records', 'Created', 'Matched', 'Missing', 'Extra', ''].map((h, i) => (
                        <th key={i} className="px-4 py-2.5 text-left font-semibold text-gray-500 uppercase tracking-wide text-[10px] whitespace-nowrap">
                          {h}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {pageRecords.map((rec) => (
                      <tr key={rec.id} className="hover:bg-gray-50 transition-colors">
                        <td className="px-4 py-3">
                          <p className="font-semibold text-gray-800">{rec.bankName}</p>
                          <p className="text-[10px] text-gray-400 truncate max-w-36">{rec.bankFileName}</p>
                        </td>
                        <td className="px-4 py-3">
                          <p className="font-semibold text-gray-800">{rec.booksName}</p>
                          <p className="text-[10px] text-gray-400 truncate max-w-36">{rec.booksFileName}</p>
                        </td>
                        <td className="px-4 py-3 text-gray-500 whitespace-nowrap">{formatDate(rec.createdAt)}</td>
                        <td className="px-4 py-3 text-left">
                          <span className="inline-flex items-center gap-1 text-emerald-700 font-semibold">
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            {rec.stats.matched}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-left">
                          <span className={`font-semibold ${rec.stats.missingFromBooks > 0 ? 'text-red-600' : 'text-gray-400'}`}>
                            {rec.stats.missingFromBooks}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-left">
                          <span className={`font-semibold ${rec.stats.extraInBooks > 0 ? 'text-amber-600' : 'text-gray-400'}`}>
                            {rec.stats.extraInBooks}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <Button variant="outline" size="sm" onClick={() => navigate(`/company/reconcile/${rec.id}`)}>
                              <Eye className="w-3.5 h-3.5" />
                              View
                            </Button>
                            <button
                              onClick={() => handleDelete(rec.id, `${rec.bankName} vs ${rec.booksName}`)}
                              className="p-1.5 rounded text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors"
                              title="Delete report"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {totalPages > 1 && (
                <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-gray-50">
                  <span className="text-xs text-gray-500">{records.length} report{records.length !== 1 ? 's' : ''}</span>
                  <div className="flex items-center gap-1">
                    <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1}
                      className="p-1.5 rounded hover:bg-gray-200 disabled:opacity-30 disabled:cursor-not-allowed">
                      <ChevronLeft className="w-4 h-4 text-gray-600" />
                    </button>
                    {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                      <button key={p} onClick={() => setPage(p)}
                        className={`w-7 h-7 text-xs rounded font-medium transition-colors ${p === page ? 'bg-teal-600 text-white' : 'text-gray-600 hover:bg-gray-200'}`}>
                        {p}
                      </button>
                    ))}
                    <button onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages}
                      className="p-1.5 rounded hover:bg-gray-200 disabled:opacity-30 disabled:cursor-not-allowed">
                      <ChevronRight className="w-4 h-4 text-gray-600" />
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </>
  )
}
