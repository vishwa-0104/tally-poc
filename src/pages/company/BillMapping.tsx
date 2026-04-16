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
import { getTallyUrl, getTallyCompanyName, getTallyVoucherType } from './CompanySettings'
import { normalizeLedgerMapping } from '@/types'
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
  const { getCompany, fetchCompanies, fetchLedgersFromDb, incrementSynced, decrementPending, incrementPending, incrementError, decrementError } = useCompanyStore()
  const ledgersState    = useCompanyStore((s) => s.ledgers)
  const stockItemsState = useCompanyStore((s) => s.stockItems)
  const companies       = useCompanyStore((s) => s.companies)

  const companyId = user?.companyId ?? ''
  const company   = companyId ? getCompany(companyId) : null
  const bill      = companyId && billId ? getBill(companyId, billId) : null

  const storedLedgers    = companyId ? (ledgersState[companyId] ?? []) : []
  const storedStockItems = companyId ? (stockItemsState[companyId] ?? []) : []

  useEffect(() => {
    if (companyId && companies.length === 0) {
      fetchCompanies().catch((err) => console.error('[BillMapping] Failed to load companies:', err))
    }
    if (companyId && storedLedgers.length === 0) {
      fetchLedgersFromDb(companyId).catch((err) => console.error('[BillMapping] Failed to load ledgers from DB:', err))
    }
  }, [companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  const tallyUrl     = getTallyUrl()
  const tallyCompany = getTallyCompanyName()
  const voucherType  = getTallyVoucherType()

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
    const trim = (v?: string) => (v && v.trim() ? v.trim() : undefined)
    const cgstLedger = trim(data.cgstLedger)
    const sgstLedger = trim(data.sgstLedger)
    const igstLedger = trim(data.igstLedger)

    const tallyMapping = {
      vendorLedger: trim(data.vendorLedger),
      purchaseLedger: trim(data.purchaseLedger),
      cgstLedger,
      sgstLedger,
      igstLedger,
    }

    // Use the form's round-off value (user-editable, pre-filled from AI parse or computed).
    const roundOffAmt =
      data.roundOffAmount != null && Math.abs(data.roundOffAmount) >= 0.005
        ? data.roundOffAmount
        : undefined

    console.log('[buildArtifacts] amounts — subtotal:', bill.subtotal, 'cgst:', bill.cgstAmount, 'sgst:', bill.sgstAmount, 'igst:', bill.igstAmount, 'roundOff:', roundOffAmt)

    const generatedXml = buildTallyXml({
      vendorLedger:   trim(data.vendorLedger),
      purchaseLedger: trim(data.purchaseLedger),
      cgstLedger,
      sgstLedger,
      igstLedger,
      billNumber:    data.billNumber,
      billDate:      data.billDate,
      voucherNumber: data.voucherNumber?.trim() || undefined,
      totalAmount:   data.totalAmount,
      subtotal:      bill.subtotal,
      cgstAmount:    bill.cgstAmount,
      sgstAmount:    bill.sgstAmount,
      igstAmount:    bill.igstAmount,
      roundOffAmount: roundOffAmt,
      tallyCompany:  tallyCompany || undefined,
      voucherType:   voucherType,
      lineItems:     data.lineItems ?? bill.lineItems,
    })

    return { generatedXml, tallyMapping }
  }

  const handleSaveMapping = async (data: MappingInput) => {
    if (!companyId) return
    setSaving(true)

    const fromStatus = bill.status
    const { generatedXml, tallyMapping } = buildArtifacts(data)
    setXml(generatedXml)
    setSyncDone(false)

    updateBillStatus(companyId, bill.id, 'mapped', {
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
      decrementError(companyId)
      incrementPending(companyId)
    }

    toast.success('Mapping saved. Ready to sync.')
    setSaving(false)
  }

  const handleSync = async (data: MappingInput) => {
    console.log('[handleSync] form data:', JSON.stringify(data, null, 2))
    if (!companyId) return
    setSyncing(true)

    const fromStatus = bill.status
    const { generatedXml, tallyMapping } = buildArtifacts(data)
    setXml(generatedXml)
    setSyncDone(false)

    // Always persist mapping before attempting sync.
    updateBillStatus(companyId, bill.id, 'mapped', {
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
      decrementError(companyId)
      incrementPending(companyId)
    }

    try {
      const result = await syncToTally(generatedXml, tallyUrl)

      if (result.success && result.created > 0) {
        // mapped -> synced
        await updateBillStatus(companyId, bill.id, 'synced', {
          tallyXml: generatedXml,
          syncedAt: new Date().toISOString(),
          syncError: undefined,
        })
        incrementSynced(companyId)
        decrementPending(companyId)
        fetchCompanies().catch(() => {}) // refresh admin counts from DB
        setSyncDone(true)
        toast.success('Bill synced to Tally successfully!')
      } else {
        throw new Error(result.message ?? 'Tally returned 0 created vouchers')
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Sync failed'

      // mapped -> error
      await updateBillStatus(companyId, bill.id, 'error', {
        tallyXml: generatedXml,
        tallyMapping,
        syncError: msg,
      })

      decrementPending(companyId)
      incrementError(companyId)
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
              stockItems={storedStockItems}
              saving={saving}
              syncing={syncing}
              defaultMapping={company?.mapping ? {
                purchase: normalizeLedgerMapping(company.mapping).purchaseLedgers[0],
                cgst:     normalizeLedgerMapping(company.mapping).cgstLedgers[0],
                sgst:     normalizeLedgerMapping(company.mapping).sgstLedgers[0],
                igst:     normalizeLedgerMapping(company.mapping).igstLedgers[0],
              } : null}
              savedLedgerSets={normalizeLedgerMapping(company?.mapping)}
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
