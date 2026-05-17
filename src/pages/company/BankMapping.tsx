import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { toast } from 'react-hot-toast'
import { ArrowLeft } from 'lucide-react'
import { BankMappingForm } from '@/components/company/BankMappingForm'
import { useAuthStore, useCompanyStore } from '@/store'
import { useBankStore } from '@/store/bankStore'
import { syncBankToTally } from '@/services/tallyService'
import type { BankSyncRow } from '@/services/tallyService'
import type { ParsedBankStatement } from '@/types'
import { getTallyUrl } from './CompanySettings'

export default function BankMapping() {
  const { bankId }        = useParams<{ bankId: string }>()
  const navigate          = useNavigate()
  const { activeCompanyId } = useAuthStore()
  const { getCompany, getLedgers, fetchLedgersFromDb } = useCompanyStore()
  const { getStatement, updateStatement } = useBankStore()

  const companyId    = activeCompanyId ?? ''
  const company      = getCompany(companyId) ?? null
  const ledgers      = getLedgers(companyId)

  useEffect(() => {
    if (companyId && ledgers.length === 0) {
      fetchLedgersFromDb(companyId).catch(() => {})
    }
  }, [companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  const record       = getStatement(bankId ?? '')
  const tallyUrl     = getTallyUrl(companyId, company?.port)
  const tallyCompany = company?.name ?? ''

  const [bankLedger, setBankLedger] = useState('')
  const [syncing,    setSyncing]    = useState(false)

  if (!record) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-4 text-gray-400">
        <p className="text-sm">Bank statement not found.</p>
        <button onClick={() => navigate('/company/bank')} className="text-xs text-teal-600 hover:underline">
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
        updateStatement(record.id, {
          status:      'synced',
          syncedCount: rows.length,
          syncedAt:    new Date().toISOString(),
          syncError:   undefined,
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
      {/* Top bar */}
      <div className="flex items-center gap-3 px-6 py-3 border-b border-gray-100 bg-white flex-shrink-0">
        <button
          onClick={() => navigate('/company/bank')}
          className="flex items-center gap-1.5 text-xs text-gray-500 hover:text-gray-800 transition-colors"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          My Bank
        </button>
        <span className="text-gray-300">|</span>
        <div className="flex items-center gap-2 min-w-0">
          <h1 className="text-sm font-bold text-gray-900 truncate">{record.bankName}</h1>
          {record.accountNumber && (
            <span className="text-xs text-gray-400 hidden sm:inline">· {record.accountNumber}</span>
          )}
          <span className="text-xs text-gray-400">· {record.totalCount} transactions</span>
          <span className="text-[10px] text-gray-400 font-mono hidden md:inline">({record.fileName})</span>
        </div>
        {record.status === 'error' && record.syncError && (
          <span className="ml-auto text-xs text-red-600 bg-red-50 border border-red-200 rounded px-2 py-0.5 truncate max-w-xs" title={record.syncError}>
            Last error: {record.syncError}
          </span>
        )}
      </div>

      {/* Mapping form fills remaining height */}
      <div className="flex-1 overflow-hidden">
        <BankMappingForm
          statement={statement}
          bankLedger={bankLedger}
          onBankLedgerChange={setBankLedger}
          ledgers={ledgers}
          onSync={handleSync}
          syncing={syncing}
        />
      </div>
    </div>
  )
}
