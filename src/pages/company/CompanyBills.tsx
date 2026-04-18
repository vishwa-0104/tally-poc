import { useState } from 'react'
import { Upload } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { StatCard } from '@/components/ui'
import { Button } from '@/components/ui/Button'
import { BillsTable, UploadModal } from '@/components/company'
import { useAuthStore, useBillStore, useCompanyStore } from '@/store'

export default function CompanyBills() {
  const [showUpload, setShowUpload] = useState(false)
  const navigate = useNavigate()

  const { user }  = useAuthStore()
  const { getBills } = useBillStore()
  const { getCompany } = useCompanyStore()

  const company = user?.companyId ? getCompany(user.companyId) : null
  const bills   = user?.companyId ? getBills(user.companyId) : []

  const synced  = bills.filter((b) => b.status === 'synced').length
  const pending = bills.filter((b) => ['parsed', 'mapped'].includes(b.status)).length
  const errors  = bills.filter((b) => b.status === 'error').length

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
            <Button variant="teal" size="sm" onClick={() => setShowUpload(true)}>
              <Upload className="w-3.5 h-3.5" />
              Upload Bill
            </Button>
          </>
        }
      />

      <div className="p-4 md:p-7">
        {/* Stats */}
        <div className="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-7">
          <StatCard label="Total Bills" value={bills.length} sub="All time"                accent="blue"  />
          <StatCard label="Synced"      value={synced}       sub="In Tally"                accent="green" />
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
      />
    </>
  )
}
