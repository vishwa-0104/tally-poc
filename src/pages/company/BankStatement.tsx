import { useRef, useState } from 'react'
import { toast } from 'react-hot-toast'
import { Upload, Loader2, FileText } from 'lucide-react'
import { useNavigate, Navigate } from 'react-router-dom'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { Button } from '@/components/ui/Button'
import { BankStatementsTable } from '@/components/company/BankStatementsTable'
import { useAuthStore, useCompanyStore } from '@/store'
import { useBankStore } from '@/store/bankStore'
import { api } from '@/lib/api'
import type { ParsedBankStatement } from '@/types'
import { COMPANY_FEATURES } from '@/types'
import { parseCsvBankStatement } from '@/lib/bankParser'

// ── Page ──────────────────────────────────────────────────────────────────────

export default function BankStatement() {
  const navigate          = useNavigate()
  const { activeCompanyId } = useAuthStore()
  const { getCompany, companiesLoaded } = useCompanyStore()
  const { addStatement, getStatements } = useBankStore()

  const fileRef      = useRef<HTMLInputElement>(null)
  const [parsing,  setParsing]  = useState(false)
  const [parseFile, setParseFile] = useState<string>('')

  const company    = getCompany(activeCompanyId ?? '') ?? null
  const companyId  = activeCompanyId ?? ''
  const statements = getStatements(companyId)

  const hasBankVoucher = (company?.features ?? []).some(
    (f) => f.feature === COMPANY_FEATURES.BANK_VOUCHER && f.enabled,
  )
  if (!companiesLoaded) return null
  if (!hasBankVoucher) return <Navigate to="/company" replace />

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
          companyId,
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
