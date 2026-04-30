import { useState } from 'react'
import { Upload, Loader } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'react-hot-toast'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { StatCard } from '@/components/ui'
import { Button } from '@/components/ui/Button'
import { BillsTable, UploadModal } from '@/components/company'
import { useAuthStore, useBillStore, useCompanyStore } from '@/store'
import { parseBillWithAI, parsedDataToBill } from '@/services'

export default function CompanyBills() {
  const [showUpload, setShowUpload]         = useState(false)
  const [showMiscUpload, setShowMiscUpload] = useState(false)
  const [bulkParsing, setBulkParsing] = useState(false)
  const [bulkDone, setBulkDone]       = useState(0)
  const [bulkTotal, setBulkTotal]     = useState(0)
  const navigate = useNavigate()

  const { activeCompanyId }  = useAuthStore()
  const { getBills, addBill } = useBillStore()
  const { getCompany, incrementBillCount } = useCompanyStore()

  const company = activeCompanyId ? getCompany(activeCompanyId) : null
  const bills   = activeCompanyId ? getBills(activeCompanyId) : []

  const synced  = bills.filter((b) => b.status === 'synced').length
  const pending = bills.filter((b) => ['parsed', 'mapped'].includes(b.status)).length
  const errors  = bills.filter((b) => b.status === 'error').length

  const handleParsed = (billId: string) => {
    navigate(`/company/bills/${billId}`)
  }

  const handleMultipleFiles = async (files: File[], billType: 'purchase' | 'misc' = 'purchase') => {
    if (!activeCompanyId) return
    setBulkTotal(files.length)
    setBulkDone(0)
    setBulkParsing(true)

    let succeeded = 0
    let failed = 0
    for (const file of files) {
      try {
        const parsed = await parseBillWithAI(file, undefined, billType, activeCompanyId)
        const bill   = parsedDataToBill(parsed, activeCompanyId!, undefined, billType)
        addBill(bill)
        incrementBillCount(activeCompanyId!)
        succeeded++
      } catch (err) {
        const code = (err as { response?: { data?: { error?: string } } })?.response?.data?.error
        if (code === 'PARSE_LIMIT_EXCEEDED' || code === 'SUBSCRIPTION_EXPIRED' || code === 'PARSE_BLOCKED') {
          toast.error(code === 'PARSE_BLOCKED' ? 'Parsing is disabled for your account' : 'Parse limit reached — stopping upload')
          setBulkDone((d) => d + (files.length - succeeded - failed))
          break
        }
        failed++
      }
      setBulkDone((d) => d + 1)
    }

    setBulkParsing(false)
    if (failed === 0 && succeeded > 0) {
      toast.success(`${succeeded} bill${succeeded !== 1 ? 's' : ''} parsed successfully`)
    } else if (succeeded > 0) {
      toast.success(`${succeeded} parsed, ${failed} failed`)
    }
  }

  return (
    <>
      <PageHeader
        title={company?.name ?? 'Bills'}
        subtitle={company?.gstin ? `GSTIN: ${company.gstin}` : 'Your purchase bills'}
        actions={
          <>
            <ExtensionStatus />
            {/* {company && (() => {
              const used    = company.parseBillsUsed
              const limit   = company.parseBillsLimit
              const pct     = limit > 0 ? Math.min(100, Math.round((used / limit) * 100)) : 0
              const expired = company.subscriptionExpiresAt && new Date(company.subscriptionExpiresAt) < new Date()
              const color   = company.parseBlocked || expired ? 'text-red-600 border-red-200 bg-red-50' :
                              pct >= 90 ? 'text-red-600 border-red-200 bg-red-50' :
                              pct >= 70 ? 'text-amber-600 border-amber-200 bg-amber-50' :
                              'text-teal-700 border-teal-200 bg-teal-50'
              return (
                <span className={cn('hidden sm:flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-full border', color)}>
                  {used} / {limit} bills parsed
                </span>
              )
            })()} */}
            {bulkParsing && (
              <span className="flex items-center gap-1.5 px-3 py-1.5 bg-teal-50 text-teal-700 text-xs font-medium rounded-full border border-teal-200">
                <Loader className="w-3 h-3 animate-spin" />
                Parsing {bulkDone} / {bulkTotal} bills…
              </span>
            )}
            <Button variant="teal" size="sm" onClick={() => setShowUpload(true)} disabled={bulkParsing}>
              <Upload className="w-3.5 h-3.5" />
              Upload Bills
            </Button>
            <Button variant="outline" size="sm" onClick={() => setShowMiscUpload(true)} disabled={bulkParsing}>
              Upload Misc Bill
            </Button>
          </>
        }
      />

      <div className="p-4 md:p-7">
        {/* Stats */}
        <div className="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-7">
          <StatCard label="Total Bills" value={bills.length} sub="All time"                accent="blue"  />
          <StatCard label="Synced"      value={synced}       sub="In ERP"                accent="green" />
          <StatCard label="Pending"     value={pending}      sub="Needs mapping or sync"   accent="amber" />
          <StatCard label="Errors"      value={errors}       sub="Need attention"          accent="red"   />
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
        onMultipleFiles={(files) => handleMultipleFiles(files, 'purchase')}
      />

      <UploadModal
        open={showMiscUpload}
        onClose={() => setShowMiscUpload(false)}
        onParsed={handleParsed}
        onMultipleFiles={(files) => handleMultipleFiles(files, 'misc')}
        billType="misc"
      />
    </>
  )
}
