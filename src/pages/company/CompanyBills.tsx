import { useMemo, useState } from 'react'
import { Loader, Receipt, CheckCircle, Clock, AlertCircle } from 'lucide-react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { toast } from 'react-hot-toast'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { BillsTable, UploadCard, UploadModal } from '@/components/company'
import { Card, CardHeader, CardTitle, CardContent } from '@/shadcn/components/ui/card'
import { CompanyPageHeader } from '@/shadcn/components/company-page-header'
import { cn } from '@/lib/utils'
import { useAuthStore, useBillStore, useCompanyStore } from '@/store'
import { parseBillWithAI, parsedDataToBill } from '@/services'

type BillType = 'purchase' | 'debit' | 'misc' | 'credit'

interface UploadCardConfig {
  key: string
  title: string
  initialType: 'purchase' | 'debit' | 'credit'
  isMisc: boolean
}

export default function CompanyBills() {
  const [showUpload, setShowUpload]               = useState(false)
  const [uploadInitialType, setUploadInitialType] = useState<'purchase' | 'debit' | 'credit'>('purchase')
  const [uploadIsMisc, setUploadIsMisc]           = useState(false)
  const [pendingFiles, setPendingFiles]           = useState<File[]>([])
  const [bulkParsing, setBulkParsing] = useState(false)
  const [bulkDone, setBulkDone]       = useState(0)
  const [bulkTotal, setBulkTotal]     = useState(0)
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  const { activeCompanyId }  = useAuthStore()
  const { getBills, addBill } = useBillStore()
  const { getCompany, incrementBillCount } = useCompanyStore()

  const company = activeCompanyId ? getCompany(activeCompanyId) : null
  const allBills = activeCompanyId ? getBills(activeCompanyId) : []
  const debitVoucherEnabled  = company?.features?.some((f) => f.feature === 'debit_voucher'  && f.enabled) ?? false
  const creditVoucherEnabled = company?.features?.some((f) => f.feature === 'credit_voucher' && f.enabled) ?? false

  // Sidebar "Vouchers" links (Purchase/Expenses/Debit Note/Credit Note) all point
  // here with a ?type= filter — there's no separate page per voucher type, they're
  // all just billType/tallyMapping flags on the same Bills list.
  const typeFilter = searchParams.get('type')
  const bills = useMemo(() => {
    if (!typeFilter) return allBills
    return allBills.filter((b) => {
      if (typeFilter === 'misc')   return b.billType === 'misc' && !b.tallyMapping?.isDebit && !b.tallyMapping?.isCredit
      if (typeFilter === 'debit')  return b.billType === 'debit' || (b.billType === 'misc' && b.tallyMapping?.isDebit)
      if (typeFilter === 'credit') return b.billType === 'credit' || (b.billType === 'misc' && b.tallyMapping?.isCredit)
      return true
    })
  }, [allBills, typeFilter])

  const synced  = bills.filter((b) => b.status === 'synced').length
  const pending = bills.filter((b) => ['parsed', 'mapped'].includes(b.status)).length
  const errors  = bills.filter((b) => b.status === 'error').length

  // Each voucher view offers a contextual set of upload entry points, mirroring
  // the initialType/isMiscUpload combinations the old header buttons used to preset.
  const uploadCardConfigs: UploadCardConfig[] = useMemo(() => {
    if (typeFilter === 'misc')   return [{ key: 'expenses',     title: 'Upload Expenses Bills',           initialType: 'purchase', isMisc: true  }]
    if (typeFilter === 'credit')
      return [
        { key: 'credit',      title: 'Upload Credit Notes',              initialType: 'credit', isMisc: false },
        { key: 'misc-credit', title: 'Upload Miscellaneous Credit Notes', initialType: 'credit', isMisc: true  },
      ]
    if (typeFilter === 'debit')
      return [
        { key: 'debit',      title: 'Upload Debit Notes',              initialType: 'debit', isMisc: false },
        { key: 'misc-debit', title: 'Upload Miscellaneous Debit Notes', initialType: 'debit', isMisc: true  },
      ]
    return [
      { key: 'purchase', title: 'Upload Purchase Bills',      initialType: 'purchase', isMisc: false },
      { key: 'misc',     title: 'Upload Miscellaneous Bills', initialType: 'purchase', isMisc: true  },
    ]
  }, [typeFilter])

  const handleParsed = (billId: string) => {
    navigate(`/company/bills/${billId}`)
  }

  const handleMultipleFiles = async (files: File[], billType: BillType = 'purchase', isMiscDebit = false, isMiscCredit = false) => {
    if (!activeCompanyId) return
    setBulkTotal(files.length)
    setBulkDone(0)
    setBulkParsing(true)

    let succeeded = 0
    let failed = 0
    for (const file of files) {
      try {
        const parsed = await parseBillWithAI(file, undefined, billType, activeCompanyId)
        let bill     = parsedDataToBill(parsed, activeCompanyId!, undefined, billType)
        if (isMiscDebit)  bill = { ...bill, tallyMapping: { isDebit:  true } }
        if (isMiscCredit) bill = { ...bill, tallyMapping: { isCredit: true } }
        addBill(bill)
        incrementBillCount(activeCompanyId!)
        succeeded++
      } catch (err) {
        const code = (err as { response?: { data?: { error?: string } } })?.response?.data?.error
        if (code === 'PARSE_LIMIT_EXCEEDED' || code === 'SUBSCRIPTION_EXPIRED' || code === 'PARSE_BLOCKED' || code === 'SERVICE_UNAVAILABLE') {
          toast.error(
            code === 'PARSE_BLOCKED'       ? 'Parsing is disabled for your account' :
            code === 'SERVICE_UNAVAILABLE' ? 'Service unavailable — please try again later or contact support' :
                                             'Parse limit reached — stopping upload',
          )
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

  const openUpload = (files: File[], initialType: 'purchase' | 'debit' | 'credit', isMisc: boolean) => {
    setUploadInitialType(initialType)
    setUploadIsMisc(isMisc)
    setPendingFiles(files)
    setShowUpload(true)
  }

  const uploadDisabled = bulkParsing || !!company?.parseBlocked

  return (
    <>
      <CompanyPageHeader
        title={company?.name ?? 'Bills'}
        subtitle={company?.gstin ? `GSTIN: ${company.gstin}` : 'Your purchase bills'}
        actions={
          <>
            {bulkParsing && (
              <span className="flex items-center gap-1.5 px-3 py-1.5 bg-primary/10 text-primary text-xs font-medium rounded-full border border-primary/30">
                <Loader className="w-3 h-3 animate-spin" />
                Parsing {bulkDone} / {bulkTotal} bills…
              </span>
            )}
            <ExtensionStatus />
          </>
        }
      />

      <div className="p-4 md:p-7">
        <div className="grid grid-cols-1 gap-4 sm:gap-6 lg:grid-cols-2 mb-7">
          <div className={cn('grid grid-cols-1 gap-4', uploadCardConfigs.length > 1 && 'sm:grid-cols-2')}>
            {uploadCardConfigs.map((cfg) => (
              <UploadCard
                key={cfg.key}
                title={cfg.title}
                disabled={uploadDisabled}
                disabledMessage={company?.parseBlocked ? 'Parsing disabled by admin' : undefined}
                onSubmit={(files) => openUpload(files, cfg.initialType, cfg.isMisc)}
              />
            ))}
          </div>

          <div className="grid grid-cols-2 gap-3 sm:gap-4">
            {[
              { label: 'Total Bills', value: bills.length, color: 'text-foreground',                        icon: Receipt     },
              { label: 'Synced',      value: synced,        color: 'text-emerald-600 dark:text-emerald-400', icon: CheckCircle },
              { label: 'Pending',     value: pending,       color: 'text-orange-600 dark:text-orange-400',   icon: Clock       },
              { label: 'Errors',      value: errors,        color: 'text-red-600 dark:text-red-400',         icon: AlertCircle },
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

        {/* Bills table */}
        <Card className="widget-card">
          <CardHeader>
            <CardTitle>Uploaded Bills</CardTitle>
          </CardHeader>
          <CardContent>
            <BillsTable bills={bills} onUpload={() => openUpload([], uploadCardConfigs[0].initialType, uploadCardConfigs[0].isMisc)} />
          </CardContent>
        </Card>
      </div>

      <UploadModal
        open={showUpload}
        onClose={() => { setShowUpload(false); setUploadInitialType('purchase'); setUploadIsMisc(false); setPendingFiles([]) }}
        onParsed={handleParsed}
        onMultipleFiles={handleMultipleFiles}
        initialType={uploadInitialType}
        initialFiles={pendingFiles}
        debitVoucherEnabled={debitVoucherEnabled}
        creditVoucherEnabled={creditVoucherEnabled}
        isMiscUpload={uploadIsMisc}
      />
    </>
  )
}
