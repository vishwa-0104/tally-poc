import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, CheckCircle } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { MappingForm } from '@/components/company/MappingForm'
import { SyncedBillView } from '@/components/company/SyncedBillView'
import { useAuthStore, useBillStore, useCompanyStore } from '@/store'
import { useTallyLedgers } from '@/hooks'
import { syncToTally } from '@/services'
import { buildTallyXml } from '@/lib/utils'
import { getNextVoucherCounter } from '@/lib/api'
import { getTallyUrl, getTallyCompanyName, getTallyVoucherType } from './CompanySettings'
import { normalizeLedgerMapping } from '@/types'
import type { MappingInput } from '@/lib/validators'
import type { Bill } from '@/types'

export default function BillMapping() {
  const { billId } = useParams<{ billId: string }>()
  const navigate   = useNavigate()
  const [saving, setSaving]     = useState(false)
  const [syncing, setSyncing]   = useState(false)
  const [syncDone, setSyncDone] = useState(false)

  const { user }     = useAuthStore()
  const { getBill, updateBillStatus, fetchBills } = useBillStore()
  const { getCompany, fetchCompanies, fetchLedgersFromDb, fetchStockItemsFromDb, fetchAliases, saveAliases, incrementSynced, decrementPending, incrementPending, incrementError, decrementError } = useCompanyStore()
  const ledgersState       = useCompanyStore((s) => s.ledgers)
  const stockItemsState    = useCompanyStore((s) => s.stockItems)
  const stockItemAliasesState = useCompanyStore((s) => s.stockItemAliases)
  const companies          = useCompanyStore((s) => s.companies)

  const companyId = user?.companyId ?? ''
  const company   = companyId ? getCompany(companyId) : null
  const bill      = companyId && billId ? getBill(companyId, billId) : null

  const storedLedgers    = companyId ? (ledgersState[companyId] ?? []) : []
  const storedStockItems = companyId ? (stockItemsState[companyId] ?? []) : []
  const storedAliases    = companyId ? (stockItemAliasesState[companyId] ?? []) : []

  useEffect(() => {
    if (companyId && companies.length === 0) {
      fetchCompanies().catch((err) => console.error('[BillMapping] Failed to load companies:', err))
    }
    if (companyId && storedLedgers.length === 0) {
      fetchLedgersFromDb(companyId).catch((err) => console.error('[BillMapping] Failed to load ledgers from DB:', err))
    }
    if (companyId && storedStockItems.length === 0) {
      fetchStockItemsFromDb(companyId).catch((err: unknown) => console.error('[BillMapping] Failed to load stock items from DB:', err))
    }
    if (companyId && storedAliases.length === 0) {
      fetchAliases(companyId).catch((err: unknown) => console.error('[BillMapping] Failed to load aliases from DB:', err))
    }
  }, [companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  // Persist stock item aliases for any line item that has a tallyStockItem mapped
  const persistAliases = (lineItems: MappingInput['lineItems']) => {
    if (!companyId || !lineItems?.length) return
    const toSave = lineItems
      .filter((item) => item.tallyStockItem?.trim() && item.description?.trim())
      .map((item) => ({ billItemName: item.description.trim(), tallyStockItemName: item.tallyStockItem!.trim() }))
    if (toSave.length > 0) saveAliases(companyId, toSave).catch(() => {})
  }

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

    // Derive single-value ledgers for XML (temporary until XML supports multi-ledger entries)
    const purchaseLedger = trim(data.purchaseLedger_18) ?? trim(data.purchaseLedger_5) ?? trim(data.purchaseLedger_exempt)
    const cgstLedger     = trim(data.cgstLedger_18)     ?? trim(data.cgstLedger_5)
    const sgstLedger     = trim(data.sgstLedger_18)     ?? trim(data.sgstLedger_5)
    const igstLedger     = trim(data.igstLedger_18)     ?? trim(data.igstLedger_5)

    const tallyMapping = {
      vendorLedger: trim(data.vendorLedger),
      purchaseLedger,
      cgstLedger,
      sgstLedger,
      igstLedger,
    }

    // Use the form's round-off value (user-editable, pre-filled from AI parse or computed).
    const roundOffAmt =
      data.roundOffAmount != null && Math.abs(data.roundOffAmount) >= 0.01
        ? data.roundOffAmount
        : undefined

    console.log('[buildArtifacts] amounts — subtotal:', bill.subtotal, 'cgst:', bill.cgstAmount, 'sgst:', bill.sgstAmount, 'igst:', bill.igstAmount, 'roundOff:', roundOffAmt)

    const generatedXml = buildTallyXml({
      vendorLedger:   trim(data.vendorLedger),
      purchaseLedger,
      cgstLedger,
      sgstLedger,
      igstLedger,
      billNumber:    data.billNumber,
      billDate:      data.billDate,
      voucherDate:   data.voucherDate?.trim() || undefined,
      voucherNumber: data.voucherNumber?.trim() || undefined,
      totalAmount:   data.totalAmount,
      subtotal:      bill.subtotal,
      cgstAmount:    bill.cgstAmount,
      sgstAmount:    bill.sgstAmount,
      igstAmount:    bill.igstAmount,
      roundOffAmount: roundOffAmt,
      roundOffLedger: company?.mapping?.roundoff_ledger?.trim() || undefined,
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

    persistAliases(data.lineItems)
    toast.success('Mapping saved. Ready to sync.')
    setSaving(false)
  }

  const handleSync = async (data: MappingInput) => {
    console.log('[handleSync] form data:', JSON.stringify(data, null, 2))
    if (!companyId) return
    setSyncing(true)

    try {
      const fromStatus = bill.status

      // Get next voucher counter and build voucher number
      const counter = await getNextVoucherCounter(companyId)
      const voucherNumber = `${data.billNumber}_${counter}`
      const dataWithVoucher: MappingInput = { ...data, voucherNumber }

      const { generatedXml, tallyMapping } = buildArtifacts(dataWithVoucher)

      // Persist mapping first — await so its DB write completes before the synced
      // write below. Without this, the 'mapped' response can arrive after the
      // optimistic 'synced' update and race-overwrite it back to 'mapped'.
      await updateBillStatus(companyId, bill.id, 'mapped', {
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

      const result = await syncToTally(generatedXml, tallyUrl)

      if (result.success && result.created > 0) {
        // Await so status persists to DB, then re-fetch bills so the store
        // is authoritative from the server — this prevents any race condition
        // from leaving the status as 'mapped' in the UI.
        await updateBillStatus(companyId, bill.id, 'synced', {
          tallyXml: generatedXml,
          syncedAt: new Date().toISOString(),
          syncError: undefined,
        })
        await fetchBills(companyId)

        persistAliases(dataWithVoucher.lineItems)
        toast.success('Bill synced to Tally successfully!')
        setSyncDone(true)
        incrementSynced(companyId)
        decrementPending(companyId)
        fetchCompanies().catch(() => {})
      } else {
        throw new Error(result.message ?? 'Tally returned 0 created vouchers')
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Sync failed'
      toast.error(msg)
      updateBillStatus(companyId, bill.id, 'error', {
        syncError: msg,
      }).catch(() => {})
      decrementPending(companyId)
      incrementError(companyId)
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

      <div className="p-4 md:p-7 max-w-5xl">
        {/* Synced — read-only view */}
        {(syncDone || bill.status === 'synced') && (
          <>
            <div className="flex items-start gap-3 p-5 bg-emerald-50 border border-emerald-200 rounded-xl mb-6">
              <CheckCircle className="w-6 h-6 text-emerald-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-bold text-emerald-800">Successfully synced to Tally!</p>
                <p className="text-xs text-emerald-700 mt-0.5">
                  Voucher created in Tally ERP. This bill is now marked as synced.
                </p>
              </div>
            </div>
            <SyncedBillView bill={bill} />
          </>
        )}

        {!syncDone && bill.status !== 'synced' && (
          <div className="card p-6 mb-5">
            <MappingForm
              bill={bill}
              ledgers={ledgers}
              ledgersLoading={ledgersLoading}
              stockItems={storedStockItems}
              saving={saving}
              syncing={syncing}
              savedLedgerSets={normalizeLedgerMapping(company?.mapping)}
              nextVoucherNumber={`${bill.billNumber}_${(company?.voucherCounter ?? 0) + 1}`}
              stockItemAliases={storedAliases}
              companyId={companyId}
              tallyUrl={tallyUrl}
              tallyCompany={tallyCompany}
              onSaveMapping={handleSaveMapping}
              onSyncToTally={handleSync}
            />
          </div>
        )}

      </div>
    </>
  )
}
