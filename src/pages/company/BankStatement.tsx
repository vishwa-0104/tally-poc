import { useRef, useState } from 'react'
import { toast } from 'react-hot-toast'
import { Upload, Loader2, FileText } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { Button } from '@/components/ui/Button'
import { BankStatementsTable } from '@/components/company/BankStatementsTable'
import { useAuthStore, useCompanyStore } from '@/store'
import { useBankStore } from '@/store/bankStore'
import { api } from '@/lib/api'
import type { ParsedBankStatement } from '@/types'

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
  let m = d.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/)
  if (m) return `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}`
  if (/^\d{4}-\d{2}-\d{2}$/.test(d)) return d
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

function parseCsvBankStatement(text: string, fileName: string): ParsedBankStatement {
  const lines = text.trim().split(/\r?\n/)
  if (lines.length < 2) return { bankName: fileName, transactions: [] }

  let headerIdx = 0
  for (let i = 0; i < Math.min(5, lines.length); i++) {
    if (lines[i].toLowerCase().includes('date')) { headerIdx = i; break }
  }

  const headers = parseCsvRow(lines[headerIdx]).map((h) => h.toLowerCase().replace(/['"]/g, '').trim())
  const find = (...terms: string[]) => headers.findIndex((h) => terms.some((t) => h.includes(t)))

  const dateIdx   = find('date')
  const descIdx   = find('description', 'narration', 'particulars', 'detail', 'remarks', 'transaction remark', 'txn remark')
  // Bank CREDIT column = money received = our "debit" field (Debit Bank Credit in UI)
  const debitIdx  = find('credit', 'deposit', 'cr ')
  // Bank DEBIT column  = money paid    = our "credit" field (Credit Bank Debit in UI)
  const creditIdx = find('debit', 'withdrawal', 'dr ', 'withd')
  const balIdx    = find('balance')

  if (dateIdx === -1) return { bankName: fileName, transactions: [] }

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

  return { bankName: fileName.replace(/\.[^.]+$/, ''), transactions }
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function BankStatement() {
  const navigate          = useNavigate()
  const { activeCompanyId } = useAuthStore()
  const { getCompany }    = useCompanyStore()
  const { addStatement, getStatements } = useBankStore()

  const company    = getCompany(activeCompanyId ?? '') ?? null
  const companyId  = activeCompanyId ?? ''
  const statements = getStatements(companyId)

  const fileRef      = useRef<HTMLInputElement>(null)
  const [parsing,  setParsing]  = useState(false)
  const [parseFile, setParseFile] = useState<string>('')

  const handleFileSelect = async (file: File) => {
    setParsing(true)
    setParseFile(file.name)
    try {
      let parsed: ParsedBankStatement

      if (file.name.endsWith('.csv') || file.type === 'text/csv' || file.type === 'application/vnd.ms-excel') {
        const text = await file.text()
        parsed = parseCsvBankStatement(text, file.name)
        if (parsed.transactions.length === 0) {
          toast.error('No transactions found. Check the CSV has Date, Description, and Debit/Credit columns.')
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
        })
        if (!data.transactions?.length) {
          toast.error('No transactions found in the document.')
          return
        }
        data.transactions = data.transactions.map((t, i) => ({
          ...t,
          id: (t as { id?: string }).id ?? `txn_${Date.now()}_${i}`,
        }))
        parsed = data
      }

      const totalDebit  = parsed.transactions.reduce((s, t) => s + (t.debit  ?? 0), 0)
      const totalCredit = parsed.transactions.reduce((s, t) => s + (t.credit ?? 0), 0)

      const record = {
        id:            `bs_${Date.now()}`,
        companyId,
        bankName:      parsed.bankName || file.name.replace(/\.[^.]+$/, ''),
        accountNumber: parsed.accountNumber,
        fileName:      file.name,
        uploadedAt:    new Date().toISOString(),
        status:        'pending' as const,
        syncedCount:   0,
        totalCount:    parsed.transactions.length,
        totalDebit,
        totalCredit,
        transactions:  parsed.transactions,
      }

      addStatement(record)
      toast.success(`${parsed.transactions.length} transactions imported`)
      navigate(`/company/bank/${record.id}`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to parse file')
    } finally {
      setParsing(false)
      setParseFile('')
    }
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    const file = e.dataTransfer.files[0]
    if (file) handleFileSelect(file)
  }

  return (
    <>
      <PageHeader
        title={company?.name ? `${company.name} — My Bank` : 'My Bank'}
        subtitle="Upload and sync bank statement transactions to Tally"
        actions={
          <>
            <ExtensionStatus />
            {statements.length > 0 && (
              <Button variant="teal" size="sm" disabled={parsing} onClick={() => fileRef.current?.click()}>
                <Upload className="w-3.5 h-3.5" />
                Upload Statement
              </Button>
            )}
          </>
        }
      />

      <div
        className="p-4 md:p-7"
        onDrop={handleDrop}
        onDragOver={(e) => e.preventDefault()}
      >
        <div className="card overflow-hidden">
          <BankStatementsTable
            statements={statements}
            onUpload={() => fileRef.current?.click()}
          />
        </div>
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

      {/* Parsing overlay */}
      {parsing && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl px-10 py-8 flex flex-col items-center gap-4 max-w-xs w-full mx-4">
            <div className="w-14 h-14 rounded-xl bg-teal-50 flex items-center justify-center">
              <FileText className="w-7 h-7 text-teal-600" />
            </div>
            <Loader2 className="w-6 h-6 text-teal-600 animate-spin" />
            <div className="text-center">
              <p className="text-sm font-semibold text-gray-900">Parsing bank statement…</p>
              {parseFile && (
                <p className="text-xs text-gray-400 mt-1 truncate max-w-56" title={parseFile}>
                  {parseFile}
                </p>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  )
}
