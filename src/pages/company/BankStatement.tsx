import { useRef, useState } from 'react'
import { toast } from 'react-hot-toast'
import { Upload, ArrowLeft, Landmark } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { BankMappingForm } from '@/components/company/BankMappingForm'
import { PageHeader } from '@/components/shared'
import { useAuthStore, useCompanyStore } from '@/store'
import { api } from '@/lib/api'
import { syncBankToTally } from '@/services/tallyService'
import type { ParsedBankStatement } from '@/types'
import type { BankSyncRow } from '@/services/tallyService'
import { getTallyUrl } from './CompanySettings'

// ── CSV parser ────────────────────────────────────────────────────────────────

function parseCsvRow(line: string): string[] {
  const result: string[] = []
  let current = ''
  let inQuotes = false
  for (let i = 0; i < line.length; i++) {
    if (line[i] === '"') { inQuotes = !inQuotes }
    else if (line[i] === ',' && !inQuotes) { result.push(current.trim()); current = '' }
    else { current += line[i] }
  }
  result.push(current.trim())
  return result
}

function parseAmount(val: string | undefined): number | null {
  if (!val) return null
  const n = parseFloat(val.replace(/["',\s]/g, ''))
  return isNaN(n) || n === 0 ? null : n
}

function normalizeDate(d: string): string {
  d = d.trim().replace(/['"]/g, '')
  // DD/MM/YYYY or DD-MM-YYYY
  let m = d.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/)
  if (m) return `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}`
  // YYYY-MM-DD already
  if (/^\d{4}-\d{2}-\d{2}$/.test(d)) return d
  // DD Mon YYYY  (e.g. 18 May 2024)
  m = d.match(/^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})$/)
  if (m) {
    const months: Record<string, string> = {
      jan:'01', feb:'02', mar:'03', apr:'04', may:'05', jun:'06',
      jul:'07', aug:'08', sep:'09', oct:'10', nov:'11', dec:'12',
    }
    const mo = months[m[2].toLowerCase()]
    if (mo) return `${m[3]}-${mo}-${m[1].padStart(2, '0')}`
  }
  return d
}

function parseCsvBankStatement(text: string): ParsedBankStatement {
  const lines = text.trim().split(/\r?\n/)
  if (lines.length < 2) return { bankName: 'Bank Statement', transactions: [] }

  // Find header row (first line containing "date")
  let headerIdx = 0
  for (let i = 0; i < Math.min(5, lines.length); i++) {
    if (lines[i].toLowerCase().includes('date')) { headerIdx = i; break }
  }

  const headers = parseCsvRow(lines[headerIdx]).map((h) => h.toLowerCase().replace(/['"]/g, '').trim())

  const find = (...terms: string[]) => headers.findIndex((h) => terms.some((t) => h.includes(t)))

  const dateIdx   = find('date')
  const descIdx   = find('description', 'narration', 'particulars', 'detail', 'remarks', 'transaction remark', 'txn remark')
  // Bank's CREDIT column = money received = our "debit" field
  const debitIdx  = find('credit', 'deposit', 'cr ')
  // Bank's DEBIT column  = money paid    = our "credit" field
  const creditIdx = find('debit', 'withdrawal', 'dr ', 'withd')
  const balIdx    = find('balance')

  if (dateIdx === -1) return { bankName: 'Bank Statement', transactions: [] }

  const transactions: ParsedBankStatement['transactions'] = []
  for (let i = headerIdx + 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue
    const cols  = parseCsvRow(lines[i])
    const raw   = cols[dateIdx]?.replace(/['"]/g, '').trim() || ''
    const desc  = (descIdx >= 0 ? cols[descIdx] : '').replace(/['"]/g, '').trim()
    if (!raw && !desc) continue

    const debit   = debitIdx  >= 0 ? parseAmount(cols[debitIdx])  : null
    const credit  = creditIdx >= 0 ? parseAmount(cols[creditIdx]) : null
    const balance = balIdx    >= 0 ? parseAmount(cols[balIdx])    : null

    if (debit === null && credit === null) continue

    transactions.push({
      id:      `txn_${Date.now()}_${i}`,
      date:    normalizeDate(raw),
      description: desc,
      debit,
      credit,
      balance: balance ?? undefined,
    })
  }

  return { bankName: 'Bank Statement', transactions }
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function BankStatement() {
  const { activeCompanyId }       = useAuthStore()
  const { getCompany, getLedgers, getVoucherTypes } = useCompanyStore()
  const company = getCompany(activeCompanyId ?? '') ?? null
  const companyId = activeCompanyId ?? ''

  const ledgers      = getLedgers(companyId)
  const voucherTypes = getVoucherTypes(companyId)
  const tallyUrl     = getTallyUrl(companyId, company?.port)
  const tallyCompany = company?.name ?? ''

  const fileRef   = useRef<HTMLInputElement>(null)
  const [statement, setStatement] = useState<ParsedBankStatement | null>(null)
  const [bankLedger, setBankLedger] = useState('')
  const [parsing,  setParsing]   = useState(false)
  const [syncing,  setSyncing]   = useState(false)

  const handleFileSelect = async (file: File) => {
    setParsing(true)
    try {
      if (file.name.endsWith('.csv') || file.type === 'text/csv') {
        const text = await file.text()
        const parsed = parseCsvBankStatement(text)
        if (parsed.transactions.length === 0) {
          toast.error('No transactions found. Check the CSV format (needs Date, Description, Debit/Credit columns).')
          return
        }
        setStatement(parsed)
      } else {
        // PDF / image → AI parse via server
        const reader = new FileReader()
        const base64: string = await new Promise((resolve, reject) => {
          reader.onload  = () => resolve((reader.result as string).split(',')[1])
          reader.onerror = reject
          reader.readAsDataURL(file)
        })
        const { data } = await api.post<ParsedBankStatement>('/bank/parse', {
          base64,
          mediaType: file.type || 'application/pdf',
        })
        if (!data.transactions?.length) {
          toast.error('No transactions found in the document.')
          return
        }
        // Stamp IDs (server doesn't set them)
        data.transactions = data.transactions.map((t, i) => ({
          ...t,
          id: t.id ?? `txn_${Date.now()}_${i}`,
        }))
        setStatement(data)
      }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to parse file')
    } finally {
      setParsing(false)
    }
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    const file = e.dataTransfer.files[0]
    if (file) handleFileSelect(file)
  }

  const handleSync = async (rows: BankSyncRow[], bl: string) => {
    setSyncing(true)
    try {
      const result = await syncBankToTally(rows, bl, tallyUrl, tallyCompany)
      if (result.success) {
        toast.success(`Synced ${result.created} voucher${result.created !== 1 ? 's' : ''} to Tally`)
      } else {
        toast.error(result.message ?? 'Sync failed')
      }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Sync failed')
    } finally {
      setSyncing(false)
    }
  }

  // ── Empty state (no statement loaded) ────────────────────────────────────
  if (!statement) {
    return (
      <div className="flex flex-col h-full">
        <PageHeader title="My Bank" subtitle="Import and sync bank statement transactions to Tally" />
        <div
          className="flex-1 flex flex-col items-center justify-center p-8"
          onDrop={handleDrop}
          onDragOver={(e) => e.preventDefault()}
        >
          <div className="flex flex-col items-center gap-6 max-w-sm text-center">
            <div className="w-16 h-16 rounded-2xl bg-teal-50 flex items-center justify-center">
              <Landmark className="w-8 h-8 text-teal-600" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-gray-900 mb-1">Upload Bank Statement</h2>
              <p className="text-sm text-gray-500">
                Supports CSV exports from any Indian bank, or upload a PDF / image for AI parsing.
              </p>
            </div>
            <Button
              variant="teal"
              size="lg"
              loading={parsing}
              onClick={() => fileRef.current?.click()}
              className="w-full"
            >
              <Upload className="w-4 h-4 mr-2" />
              {parsing ? 'Parsing…' : 'Upload Bank Statement'}
            </Button>
            <p className="text-xs text-gray-400">
              CSV · PDF · JPG · PNG · drag &amp; drop supported
            </p>
          </div>
          <input
            ref={fileRef}
            type="file"
            accept=".csv,.pdf,.jpg,.jpeg,.png,.webp"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0]
              if (file) handleFileSelect(file)
              e.target.value = ''
            }}
          />
        </div>
      </div>
    )
  }

  // ── Mapping form ──────────────────────────────────────────────────────────
  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center gap-3 px-6 py-4 border-b border-gray-100 bg-white flex-shrink-0">
        <button
          onClick={() => setStatement(null)}
          className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-gray-800 transition-colors"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          Upload another
        </button>
        <span className="text-gray-300">|</span>
        <h1 className="text-sm font-bold text-gray-900">Bank Statement Mapping</h1>
        <span className="text-xs text-gray-500">{statement.transactions.length} transactions</span>
      </div>

      <div className="flex-1 overflow-hidden">
        <BankMappingForm
          statement={statement}
          bankLedger={bankLedger}
          onBankLedgerChange={setBankLedger}
          ledgers={ledgers}
          voucherTypes={voucherTypes}
          onSync={handleSync}
          syncing={syncing}
        />
      </div>
    </div>
  )
}
