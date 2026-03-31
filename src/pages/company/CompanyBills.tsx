import { useState } from 'react'
import { Upload } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { StatCard } from '@/components/ui'
import { Button } from '@/components/ui/Button'
import { BillsTable, UploadModal } from '@/components/company'
import { useAuthStore, useBillStore, useCompanyStore } from '@/store'
import { buildTallyXml } from '@/lib/utils'
import { syncToTally } from '@/services'
import { getTallyUrl } from './CompanySettings'
import type { TallyBillMapping } from '@/types'

export default function CompanyBills() {
  const [showUpload, setShowUpload] = useState(false)
  const [syncingAll, setSyncingAll] = useState(false)
  const navigate = useNavigate()

  const { user }    = useAuthStore()
  const { getBills, updateBillStatus } = useBillStore()
  const { getCompany, incrementSynced, decrementPending, incrementError, decrementError } = useCompanyStore()

  const company = user?.companyId ? getCompany(user.companyId) : null
  const bills   = user?.companyId ? getBills(user.companyId) : []

  const synced  = bills.filter((b) => b.status === 'synced').length
  const pending = bills.filter((b) => ['parsed', 'mapped'].includes(b.status)).length
  const errors  = bills.filter((b) => b.status === 'error').length

  const syncableBills = bills.filter((b) => b.status === 'parsed' || b.status === 'mapped' || b.status === 'error')

  const getXmlForBill = (bill: (typeof bills)[number]) => {
    if (bill.tallyXml) {
      return { xml: bill.tallyXml, mappingUsed: bill.tallyMapping ?? null }
    }

    const mapping: TallyBillMapping | null = bill.tallyMapping ?? null
    const companyMapping = company?.mapping ?? null

    const vendorLedger = mapping?.vendorLedger ?? bill.vendorName
    const purchaseLedger = mapping?.purchaseLedger ?? companyMapping?.purchase ?? ''
    const cgstLedger = mapping?.cgstLedger ?? companyMapping?.cgst ?? ''
    const sgstLedger = mapping?.sgstLedger ?? companyMapping?.sgst ?? ''
    const igstLedger = mapping?.igstLedger ?? (companyMapping?.igst ? companyMapping.igst : undefined)

    if (!purchaseLedger || !cgstLedger || !sgstLedger) return null

    const mappingUsed: TallyBillMapping = {
      vendorLedger,
      purchaseLedger,
      cgstLedger,
      sgstLedger,
      igstLedger: igstLedger && igstLedger.trim() ? igstLedger : undefined,
    }

    const xml = buildTallyXml({
      vendorLedger: mappingUsed.vendorLedger,
      purchaseLedger: mappingUsed.purchaseLedger,
      cgstLedger: mappingUsed.cgstLedger,
      sgstLedger: mappingUsed.sgstLedger,
      igstLedger: mappingUsed.igstLedger,
      billNumber: bill.billNumber,
      billDate: bill.billDate,
      totalAmount: bill.totalAmount,
      subtotal: bill.subtotal,
      cgstAmount: bill.cgstAmount,
      sgstAmount: bill.sgstAmount,
      igstAmount: bill.igstAmount,
    })
    return { xml, mappingUsed }
  }

  const handleSyncAll = async () => {
    if (!company || syncableBills.length === 0) return
    setSyncingAll(true)
    try {
      for (const bill of syncableBills) {
        const built = getXmlForBill(bill)
        if (!built) {
          updateBillStatus(company.id, bill.id, 'error', {
            syncError: company?.mapping
              ? 'Mapping not available for this bill. Please open it and save mapping.'
              : 'Company ledger mapping is not configured. Please set it in Settings, or open the bill and save mapping.',
          })
          if (bill.status === 'parsed' || bill.status === 'mapped') {
            decrementPending(company.id)
            incrementError(company.id)
          }
          continue
        }

        const { xml, mappingUsed } = built

        try {
          const result = await syncToTally(xml, getTallyUrl())
          if (result.success && result.created > 0) {
            updateBillStatus(company.id, bill.id, 'synced', {
              tallyXml: xml,
              tallyMapping: mappingUsed ?? undefined,
              syncedAt: new Date().toISOString(),
              syncError: undefined,
            })

            if (bill.status === 'error') decrementError(company.id)
            else decrementPending(company.id)

            incrementSynced(company.id)
          } else {
            throw new Error(result.message ?? 'Tally returned 0 created vouchers')
          }
        } catch (err) {
          const msg = err instanceof Error ? err.message : 'Sync failed'

          updateBillStatus(company.id, bill.id, 'error', {
            tallyXml: xml,
            tallyMapping: mappingUsed ?? undefined,
            syncError: msg,
          })

          if (bill.status === 'parsed' || bill.status === 'mapped') {
            decrementPending(company.id)
            incrementError(company.id)
          }
        }
      }
    } finally {
      setSyncingAll(false)
    }
  }

  const handleParsed = (billId: string) => {
    navigate(`/company/bills/${billId}`)
  }

  return (
    <>
      <PageHeader
        title={company?.name ?? 'Bills'}
        subtitle={company?.gstin ? `GSTIN: ${company.gstin}` : 'Your purchase bills'}
        actions={
          <>
            <ExtensionStatus />
            <Button
              variant="outline"
              size="sm"
              disabled={syncingAll || syncableBills.length === 0}
              onClick={handleSyncAll}
            >
              {syncingAll ? 'Syncing…' : `Sync All (${syncableBills.length})`}
            </Button>
            <Button variant="teal" size="sm" onClick={() => setShowUpload(true)}>
              <Upload className="w-3.5 h-3.5" />
              Upload Bill
            </Button>
          </>
        }
      />

      <div className="p-7">
        {/* Stats */}
        <div className="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-7">
          <StatCard label="Total Bills" value={bills.length} sub="All time"       accent="blue"  />
          <StatCard label="Synced"      value={synced}       sub="In Tally"       accent="green" />
          <StatCard label="Pending"     value={pending}      sub="Needs mapping or sync"  accent="amber" />
          <StatCard label="Errors"      value={errors}       sub="Need attention" accent="red"   />
        </div>

        {/* Bills table */}
        <div className="card overflow-hidden">
          <BillsTable bills={bills} onUpload={() => setShowUpload(true)} />
        </div>
      </div>

      <UploadModal
        open={showUpload}
        onClose={() => setShowUpload(false)}
        onParsed={handleParsed}
      />
    </>
  )
}
