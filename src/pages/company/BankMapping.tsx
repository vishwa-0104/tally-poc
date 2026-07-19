import { useState, useEffect } from 'react'
import { useParams, useNavigate, Navigate } from 'react-router-dom'
import { toast } from 'react-hot-toast'
import { ArrowLeft } from 'lucide-react'
import { BankMappingForm } from '@/components/company/BankMappingForm'
import { CompanyPageHeader } from '@/shadcn/components/company-page-header'
import { Button } from '@/shadcn/components/ui/button'
import { useAuthStore, useCompanyStore } from '@/store'
import { useBankStore, makeFingerprint } from '@/store/bankStore'
import { normalizeLedgerMapping } from '@/types'
import { syncBankToTally } from '@/services/tallyService'
import type { BankSyncRow } from '@/services/tallyService'
import { COMPANY_FEATURES } from '@/types'
import type { ParsedBankStatement } from '@/types'
import { getTallyUrl } from './CompanySettings'
import { api } from '@/lib/api'

export default function BankMapping() {
  const { bankId }          = useParams<{ bankId: string }>()
  const navigate            = useNavigate()
  const { activeCompanyId } = useAuthStore()
  const { getCompany, getLedgers, fetchLedgersFromDb, companiesLoaded } = useCompanyStore()
  const { getStatement, updateStatement } = useBankStore()

  const companyId    = activeCompanyId ?? ''
  const company      = getCompany(companyId) ?? null
  const ledgers      = getLedgers(companyId)

  const hasBankVoucher = (company?.features ?? []).some(
    (f) => f.feature === COMPANY_FEATURES.BANK_VOUCHER && f.enabled,
  )

  const [fingerprintSet, setFingerprintSet] = useState<Set<string>>(new Set())

  useEffect(() => {
    if (!companyId) return
    if (ledgers.length === 0) fetchLedgersFromDb(companyId).catch(() => {})
    api.get<string[]>(`/companies/${companyId}/bank-fingerprints`)
      .then(({ data }) => setFingerprintSet(new Set(data)))
      .catch(() => {})
  }, [companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  const record       = getStatement(bankId ?? '')
  const tallyUrl     = getTallyUrl(companyId, company?.port)
  const tallyCompany = company?.name ?? ''

  const [bankLedger, setBankLedger] = useState(() => {
    const rec = getStatement(bankId ?? '')
    if (!rec) return ''
    const defaults = normalizeLedgerMapping(company?.mapping).bank_default_ledgers ?? []
    const bn = rec.bankName.toLowerCase()
    const match = defaults.find((d) => bn.includes(d.keyword.toLowerCase()) || d.keyword.toLowerCase().includes(bn))
    return match?.ledger ?? ''
  })
  const [syncing, setSyncing] = useState(false)

  if (!companiesLoaded) return null
  if (!hasBankVoucher) return <Navigate to="/company" replace />

  if (!record) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-4 text-muted-foreground">
        <p className="text-sm">Bank statement not found.</p>
        <button onClick={() => navigate('/company/bank')} className="text-xs text-primary hover:underline">
          ← Back to My Bank
        </button>
      </div>
    )
  }

  const statement: ParsedBankStatement = {
    bankName:      record.bankName,
    accountNumber: record.accountNumber,
    transactions:  record.transactions,
  }

  const handleSync = async (rows: BankSyncRow[], bl: string) => {
    setSyncing(true)
    try {
      const result = await syncBankToTally(rows, bl, tallyUrl, tallyCompany)
      if (result.success) {
        const fps = rows.map((r) =>
          makeFingerprint(record.bankName, r.date, r.amount, r.description),
        )

        // Persist fingerprints to DB
        await api.post(`/companies/${companyId}/bank-fingerprints`, { fingerprints: fps })

        // Update local fingerprintSet so re-opening immediately reflects synced state
        setFingerprintSet((prev) => new Set([...prev, ...fps]))

        // Mark synced transactions in the local record
        const syncedKey = new Set(rows.map((r) => `${r.date}|${r.description}`))
        const updatedTxns = record.transactions.map((t) =>
          syncedKey.has(`${t.date}|${t.description}`) ? { ...t, synced: true } : t,
        )
        const totalSyncedCount = updatedTxns.filter((t) => t.synced === true).length
        const newStatus = totalSyncedCount >= record.totalCount ? 'synced' : 'partially_synced'

        updateStatement(record.id, {
          status:       newStatus,
          syncedCount:  totalSyncedCount,
          syncedAt:     new Date().toISOString(),
          syncError:    undefined,
          transactions: updatedTxns,
        })
        toast.success(`Synced ${result.created} voucher${result.created !== 1 ? 's' : ''} to Tally`)
        navigate('/company/bank')
      } else {
        updateStatement(record.id, {
          status:    'error',
          syncError: result.message ?? 'Sync failed',
        })
        toast.error(result.message ?? 'Sync failed')
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Sync failed'
      updateStatement(record.id, { status: 'error', syncError: msg })
      toast.error(msg)
    } finally {
      setSyncing(false)
    }
  }

  return (
    <div className="flex flex-col h-full overflow-hidden">
      <CompanyPageHeader
        title={record.bankName}
        subtitle={`${record.accountNumber ? record.accountNumber + ' · ' : ''}${record.totalCount} transactions · ${record.fileName}`}
        actions={
          <>
            {record.status === 'error' && record.syncError && (
              <span className="text-xs text-red-600 dark:text-red-400 bg-red-500/10 border border-red-500/30 rounded px-2 py-0.5 truncate max-w-xs" title={record.syncError}>
                Last error: {record.syncError}
              </span>
            )}
            <Button variant="outline" size="sm" onClick={() => navigate('/company/bank')}>
              <ArrowLeft className="w-3.5 h-3.5" />
              My Bank
            </Button>
          </>
        }
      />

      {/* Mapping form fills remaining height */}
      <div className="flex-1 overflow-hidden">
        <BankMappingForm
          statement={statement}
          bankLedger={bankLedger}
          onBankLedgerChange={setBankLedger}
          ledgers={ledgers}
          onSync={handleSync}
          syncing={syncing}
          fingerprintSet={fingerprintSet}
        />
      </div>
    </div>
  )
}
