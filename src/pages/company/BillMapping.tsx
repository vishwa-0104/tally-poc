import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, CheckCircle } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { MappingForm } from '@/components/company/MappingForm'
import { XmlPreview } from '@/components/company/XmlPreview'
import { useAuthStore, useBillStore, useCompanyStore } from '@/store'
import { useTallyLedgers } from '@/hooks'
import { syncToTally } from '@/services'
import { buildTallyXml } from '@/lib/utils'
import { getTallyUrl } from './CompanySettings'
import type { MappingInput } from '@/lib/validators'
import type { Bill } from '@/types'

export default function BillMapping() {
  const { billId } = useParams<{ billId: string }>()
  const navigate   = useNavigate()
  const [saving, setSaving]     = useState(false)
  const [syncing, setSyncing]   = useState(false)
  const [xml, setXml]           = useState<string | null>(null)
  const [syncDone, setSyncDone] = useState(false)

  const { user }     = useAuthStore()
  const { getBill, updateBillStatus } = useBillStore()
  const { getCompany, fetchLedgersFromDb, incrementSynced, decrementPending, incrementPending, incrementError, decrementError } = useCompanyStore()
  const ledgersState = useCompanyStore((s) => s.ledgers)

  const company = user?.companyId ? getCompany(user.companyId) : null
  const bill    = user?.companyId && billId ? getBill(user.companyId, billId) : null

  const storedLedgers = user?.companyId ? (ledgersState[user.companyId] ?? []) : []
console.log("EFFECT === ", user)
  useEffect(() => {
    
    if (user?.companyId && storedLedgers.length === 0) {
      fetchLedgersFromDb(user.companyId).catch((err) => console.error('[BillMapping] Failed to load ledgers from DB:', err))
    }
  }, [user?.companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  const tallyUrl = getTallyUrl()

  // Only live-fetch from Tally if no ledgers are stored yet
  const { ledgers: liveLedgers, loading: ledgersLoading } = useTallyLedgers(
    tallyUrl,
    storedLedgers.length === 0 && !!company,
  )

  const ledgers = storedLedgers.length > 0 ? storedLedgers : liveLedgers

  if (!bill) {
    return (
      <div className="p-10 text-center text-gray-500">
        <p>Bill not found.</p>
        <Button variant="outline" className="mt-4" onClick={() => navigate('/company')}>
          Back to Bills
        </Button>
      </div>
    )
  }

  const buildArtifacts = (data: MappingInput) => {
    const igstLedger = data.igstLedger && data.igstLedger.trim() ? data.igstLedger : undefined

    const tallyMapping = {
      vendorLedger: data.vendorLedger,
      purchaseLedger: data.purchaseLedger,
      cgstLedger: data.cgstLedger,
      sgstLedger: data.sgstLedger,
      igstLedger,
    }

    const generatedXml = buildTallyXml({
      vendorLedger: data.vendorLedger,
      purchaseLedger: data.purchaseLedger,
      cgstLedger: data.cgstLedger,
      sgstLedger: data.sgstLedger,
      igstLedger,
      billNumber: data.billNumber,
      billDate: data.billDate,
      totalAmount: data.totalAmount,
      subtotal: bill.subtotal,
      cgstAmount: bill.cgstAmount,
      sgstAmount: bill.sgstAmount,
      igstAmount: bill.igstAmount,
    })

    return { generatedXml, tallyMapping }
  }

  const handleSaveMapping = async (data: MappingInput) => {
    if (!company) return
    setSaving(true)

    const fromStatus = bill.status
    const { generatedXml, tallyMapping } = buildArtifacts(data)
    setXml(generatedXml)
    setSyncDone(false)

    updateBillStatus(company.id, bill.id, 'mapped', {
      billDate: data.billDate,
      billNumber: data.billNumber,
      totalAmount: data.totalAmount,
      tallyXml: generatedXml,
      tallyMapping,
      syncError: undefined,
      ...(data.lineItems && { lineItems: data.lineItems as Bill['lineItems'] }),
      isEdited: data.lineItems
        ? JSON.stringify(data.lineItems) !== JSON.stringify(bill.originalData?.lineItems)
        : bill.isEdited,
    })

    // Moving error -> mapped means the bill is now pending again.
    if (fromStatus === 'error') {
      decrementError(company.id)
      incrementPending(company.id)
    }

    toast.success('Mapping saved. Ready to sync.')
    setSaving(false)
  }

  const handleSync = async (data: MappingInput) => {
    if (!company) return
    setSyncing(true)

    const fromStatus = bill.status
    const { generatedXml, tallyMapping } = buildArtifacts(data)
    setXml(generatedXml)
    setSyncDone(false)

    // Always persist mapping before attempting sync.
    updateBillStatus(company.id, bill.id, 'mapped', {
      billDate: data.billDate,
      billNumber: data.billNumber,
      totalAmount: data.totalAmount,
      tallyXml: generatedXml,
      tallyMapping,
      syncError: undefined,
      ...(data.lineItems && { lineItems: data.lineItems as Bill['lineItems'] }),
      isEdited: data.lineItems
        ? JSON.stringify(data.lineItems) !== JSON.stringify(bill.originalData?.lineItems)
        : bill.isEdited,
    })

    // Moving error -> mapped means the bill is now pending again.
    if (fromStatus === 'error') {
      decrementError(company.id)
      incrementPending(company.id)
    }

    try {
      const result = await syncToTally(generatedXml, tallyUrl)

      if (result.success && result.created > 0) {
        // mapped -> synced
        updateBillStatus(company.id, bill.id, 'synced', {
          tallyXml: generatedXml,
          syncedAt: new Date().toISOString(),
          syncError: undefined,
        })
        incrementSynced(company.id)
        decrementPending(company.id)
        setSyncDone(true)
        toast.success('Bill synced to Tally successfully!')
      } else {
        throw new Error(result.message ?? 'Tally returned 0 created vouchers')
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Sync failed'

      // mapped -> error
      updateBillStatus(company.id, bill.id, 'error', {
        tallyXml: generatedXml,
        tallyMapping,
        syncError: msg,
      })

      decrementPending(company.id)
      incrementError(company.id)
      toast.error(msg)
    } finally {
      setSyncing(false)
    }
  }

  return (
    <>
      <PageHeader
        title="Map & Sync Bill"
        subtitle={`${bill.billNumber} — ${bill.vendorName}`}
        actions={
          <Button variant="outline" size="sm" onClick={() => navigate('/company')}>
            <ArrowLeft className="w-3.5 h-3.5" />
            Back to Bills
          </Button>
        }
      />

      <div className="p-7 max-w-5xl">
        {/* Success banner */}
        {syncDone && (
          <div className="flex items-start gap-3 p-5 bg-emerald-50 border border-emerald-200 rounded-xl mb-6">
            <CheckCircle className="w-6 h-6 text-emerald-500 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-bold text-emerald-800">Successfully synced to Tally!</p>
              <p className="text-xs text-emerald-700 mt-0.5">
                Voucher created in Tally ERP. This bill is now marked as synced.
              </p>
              <Button
                variant="teal"
                size="sm"
                className="mt-3"
                onClick={() => navigate('/company')}
              >
                Back to Bills
              </Button>
            </div>
          </div>
        )}

        {!syncDone && (
          <div className="card p-6 mb-5">
            <MappingForm
              bill={bill}
              ledgers={ledgers}
              ledgersLoading={ledgersLoading}
              saving={saving}
              syncing={syncing}
              defaultMapping={company?.mapping}
              onSaveMapping={handleSaveMapping}
              onSyncToTally={handleSync}
            />
          </div>
        )}

        {/* XML preview shown after generation */}
        {xml && (
          <div className="card p-6">
            <XmlPreview xml={xml} />
          </div>
        )}
      </div>
    </>
  )
}
