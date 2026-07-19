import { useState, useEffect } from 'react'
import { useParams, useNavigate, Navigate } from 'react-router-dom'
import { toast } from 'react-hot-toast'
import { ArrowLeft } from 'lucide-react'
import { CashBookMappingForm } from '@/components/company/CashBookMappingForm'
import { CompanyPageHeader } from '@/shadcn/components/company-page-header'
import { Button } from '@/shadcn/components/ui/button'
import { useAuthStore, useCompanyStore } from '@/store'
import { useCashBookStore, makeCashBookFingerprint } from '@/store/cashBookStore'
import { syncBankToTally } from '@/services/tallyService'
import type { BankSyncRow } from '@/services/tallyService'
import { COMPANY_FEATURES, normalizeLedgerMapping } from '@/types'
import type { ParsedBankStatement } from '@/types'
import { getTallyUrl } from './CompanySettings'
import { api } from '@/lib/api'

export default function CashBookMapping() {
  const { cashId }           = useParams<{ cashId: string }>()
  const navigate             = useNavigate()
  const { activeCompanyId }  = useAuthStore()
  const { getCompany, getLedgers, fetchLedgersFromDb, companiesLoaded } = useCompanyStore()
  const { getRecord, updateRecord } = useCashBookStore()

  const companyId   = activeCompanyId ?? ''
  const company     = getCompany(companyId) ?? null
  const ledgers     = getLedgers(companyId)

  const hasCashBook = (company?.features ?? []).some(
    (f) => f.feature === COMPANY_FEATURES.CASH_BOOK && f.enabled,
  )

  const [fingerprintSet, setFingerprintSet] = useState<Set<string>>(new Set())
  const [cashLedger,     setCashLedger]     = useState('')
  const [syncing,        setSyncing]        = useState(false)

  // Set default cash ledger once company mapping loads
  useEffect(() => {
    if (cashLedger) return
    const defaults = normalizeLedgerMapping(company?.mapping).cash_book_default_ledgers ?? []
    if (defaults[0]) setCashLedger(defaults[0])
  }, [company?.mapping]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!companyId) return
    if (ledgers.length === 0) fetchLedgersFromDb(companyId).catch(() => {})
    api.get<string[]>(`/companies/${companyId}/cash-book-fingerprints`)
      .then(({ data }) => setFingerprintSet(new Set(data)))
      .catch(() => {})
  }, [companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  const record       = getRecord(cashId ?? '')
  const tallyUrl     = getTallyUrl(companyId, company?.port)
  const tallyCompany = company?.name ?? ''

  if (!companiesLoaded) return null
  if (!hasCashBook) return <Navigate to="/company" replace />

  if (!record) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-4 text-muted-foreground">
        <p className="text-sm">Cash book record not found.</p>
        <button onClick={() => navigate('/company/cash-book')} className="text-xs text-primary hover:underline">
          ← Back to Cash Book
        </button>
      </div>
    )
  }

  const statement: ParsedBankStatement = {
    bankName:      record.bookName,
    accountNumber: record.accountNumber,
    transactions:  record.transactions,
  }

  const handleSync = async (rows: BankSyncRow[], bl: string) => {
    setSyncing(true)
    try {
      const result = await syncBankToTally(rows, bl, tallyUrl, tallyCompany)
      if (result.success) {
        // Use originalDate (from CSV) for fingerprinting, not the user-overridden entryDate
        const fps = rows.map((r) =>
          makeCashBookFingerprint(record.bookName, r.originalDate ?? r.date, r.amount, r.description),
        )

        await api.post(`/companies/${companyId}/cash-book-fingerprints`, { fingerprints: fps })

        setFingerprintSet((prev) => new Set([...prev, ...fps]))

        const syncedMap = new Map(rows.map((r) => [`${r.originalDate ?? r.date}|${r.description}`, r]))
        const updatedTxns = record.transactions.map((t) => {
          const matched = syncedMap.get(`${t.date}|${t.description}`)
          if (!matched) return t
          return { ...t, synced: true, narration: matched.narration, entryDate: matched.date }
        })
        const totalSyncedCount = updatedTxns.filter((t) => t.synced === true).length
        const newStatus = totalSyncedCount >= record.totalCount ? 'synced' : 'partially_synced'

        updateRecord(record.id, {
          status:       newStatus,
          syncedCount:  totalSyncedCount,
          syncedAt:     new Date().toISOString(),
          syncError:    undefined,
          transactions: updatedTxns,
        })
        toast.success(`Synced ${result.created} voucher${result.created !== 1 ? 's' : ''} to Tally`)
        navigate('/company/cash-book')
      } else {
        updateRecord(record.id, {
          status:    'error',
          syncError: result.message ?? 'Sync failed',
        })
        toast.error(result.message ?? 'Sync failed')
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Sync failed'
      updateRecord(record.id, { status: 'error', syncError: msg })
      toast.error(msg)
    } finally {
      setSyncing(false)
    }
  }

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <CompanyPageHeader
        title={record.bookName}
        subtitle={`${record.accountNumber ? record.accountNumber + ' · ' : ''}${record.totalCount} transactions · ${record.fileName}`}
        actions={
          <>
            {record.status === 'error' && record.syncError && (
              <span className="text-xs text-red-600 dark:text-red-400 bg-red-500/10 border border-red-500/30 rounded px-2 py-0.5 truncate max-w-xs" title={record.syncError}>
                Last error: {record.syncError}
              </span>
            )}
            <Button variant="outline" size="sm" onClick={() => navigate('/company/cash-book')}>
              <ArrowLeft className="w-3.5 h-3.5" />
              Cash Book
            </Button>
          </>
        }
      />

      {/* Mapping form fills remaining height */}
      <div className="flex-1 overflow-hidden">
        <CashBookMappingForm
          statement={statement}
          cashLedger={cashLedger}
          onCashLedgerChange={setCashLedger}
          ledgers={ledgers}
          onSync={handleSync}
          syncing={syncing}
          fingerprintSet={fingerprintSet}
        />
      </div>
    </div>
  )
}
