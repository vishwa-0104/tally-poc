import { useRef, useState } from 'react'
import { toast } from 'react-hot-toast'
import { Loader2, FileText, Landmark, CheckCircle, Clock, AlertCircle } from 'lucide-react'
import { useNavigate, Navigate } from 'react-router-dom'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { UploadCard } from '@/components/company'
import { BankStatementsTable } from '@/components/company/BankStatementsTable'
import { Card, CardHeader, CardTitle, CardContent } from '@/shadcn/components/ui/card'
import { CompanyPageHeader } from '@/shadcn/components/company-page-header'
import { cn } from '@/lib/utils'
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

  const synced  = statements.filter((r) => r.status === 'synced').length
  const pending = statements.filter((r) => r.status === 'pending' || r.status === 'partially_synced').length
  const errors  = statements.filter((r) => r.status === 'error').length

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

  return (
    <>
      <CompanyPageHeader
        title={company?.name ?? 'My Bank'}
        subtitle={company?.gstin ? `GSTIN: ${company.gstin}` : 'Upload and sync bank statement transactions to Tally'}
        actions={<ExtensionStatus />}
      />

      <div className="p-4 md:p-7">
        <div className="grid grid-cols-1 gap-4 sm:gap-6 lg:grid-cols-2 mb-7">
          <UploadCard
            title="Upload Bank Statement"
            multiple={false}
            disabled={parsing}
            onSubmit={(files) => { if (files[0]) handleFileSelect(files[0]) }}
          />

          <div className="grid grid-cols-2 gap-3 sm:gap-4">
            {[
              { label: 'Total Statements', value: statements.length, color: 'text-foreground',                        icon: Landmark    },
              { label: 'Synced',           value: synced,            color: 'text-emerald-600 dark:text-emerald-400', icon: CheckCircle },
              { label: 'Pending',          value: pending,           color: 'text-orange-600 dark:text-orange-400',   icon: Clock       },
              { label: 'Errors',           value: errors,            color: 'text-red-600 dark:text-red-400',         icon: AlertCircle },
            ].map(({ label, value, color, icon: Icon }) => (
              <Card key={label} className="widget-card flex flex-col justify-center p-4 sm:p-6">
                <div className="flex items-center justify-between">
                  <p className="text-xs sm:text-sm text-muted-foreground">{label}</p>
                  <div className="mb-2 sm:mb-3 flex size-8 sm:size-10 items-center justify-center rounded-full bg-muted">
                    <Icon className={cn('size-4 sm:size-5', color)} />
                  </div>
                </div>
                <p className={cn('text-2xl sm:text-4xl font-bold tabular-nums tracking-tight', color)}>
                  {value}
                </p>
              </Card>
            ))}
          </div>
        </div>

        <Card className="widget-card">
          <CardHeader>
            <CardTitle>Bank Statements</CardTitle>
          </CardHeader>
          <CardContent>
            <BankStatementsTable
              statements={statements}
              onUpload={() => fileRef.current?.click()}
            />
          </CardContent>
        </Card>
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
          <div className="bg-card border border-border rounded-2xl shadow-2xl px-10 py-8 flex flex-col items-center gap-4 max-w-xs w-full mx-4">
            <div className="w-14 h-14 rounded-xl bg-primary/10 flex items-center justify-center">
              <FileText className="w-7 h-7 text-primary" />
            </div>
            <Loader2 className="w-6 h-6 text-primary animate-spin" />
            <div className="text-center">
              <p className="text-sm font-semibold text-foreground">Parsing bank statement…</p>
              {parseFile && (
                <p className="text-xs text-muted-foreground mt-1 truncate max-w-56" title={parseFile}>
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
