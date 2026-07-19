import { useState, useCallback, useRef, useEffect } from 'react'
import type { ChangeEvent } from 'react'
import { useDropzone } from 'react-dropzone'
import { Camera, Upload, CheckCircle, Circle, Loader, AlertTriangle } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { parseBillWithAI, parsedDataToBill } from '@/services'
import { useBillStore, useCompanyStore, useAuthStore } from '@/store'
import { cn } from '@/lib/utils'

type QuotaErrorType = 'limit' | 'expired' | 'blocked' | 'unavailable'
interface QuotaError { type: QuotaErrorType; message: string }

function extractQuotaError(err: unknown): QuotaError | null {
  const code = (err as { response?: { data?: { error?: string; message?: string } } })?.response?.data?.error
  const message = (err as { response?: { data?: { message?: string } } })?.response?.data?.message ?? ''
  if (code === 'PARSE_LIMIT_EXCEEDED') return { type: 'limit', message }
  if (code === 'SUBSCRIPTION_EXPIRED')  return { type: 'expired', message }
  if (code === 'PARSE_BLOCKED')         return { type: 'blocked', message }
  if (code === 'SERVICE_UNAVAILABLE')   return { type: 'unavailable', message }
  return null
}

const STEPS = [
  { label: 'Uploading your bill',       sub: 'Preparing your file…' },
  { label: 'Reading the bill',          sub: 'Scanning vendor details, dates and amounts…' },
  { label: 'Extracting line items',     sub: 'Picking up item names, quantities and tax rates…' },
  { label: 'Almost done',               sub: 'Saving your bill…' },
]

type BillType = 'purchase' | 'debit' | 'misc' | 'credit'

interface UploadModalProps {
  open: boolean
  onClose: () => void
  onParsed: (billId: string) => void
  onMultipleFiles: (files: File[], type: BillType, isMiscDebit: boolean, isMiscCredit: boolean) => void
  initialType?: 'purchase' | 'debit' | 'credit'
  initialFiles?: File[]
  debitVoucherEnabled?: boolean
  creditVoucherEnabled?: boolean
  isMiscUpload?: boolean
}

export function UploadModal({ open, onClose, onParsed, onMultipleFiles, initialType = 'purchase', initialFiles, debitVoucherEnabled = false, creditVoucherEnabled = false, isMiscUpload = false }: UploadModalProps) {
  const [file, setFile]             = useState<File | null>(null)
  const [multiFiles, setMultiFiles] = useState<File[]>([])
  const [parsing, setParsing]       = useState(false)
  const [step, setStep]             = useState(-1)
  const [quotaError, setQuotaError] = useState<QuotaError | null>(null)
  const [selectedType, setSelectedType] = useState<BillType>(initialType)
  const cameraInputRef              = useRef<HTMLInputElement>(null)

  const handleCameraCapture = (e: ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (f) setFile(f)
    e.target.value = ''
  }

  const { activeCompanyId } = useAuthStore()
  const addBill  = useBillStore((s) => s.addBill)
  const { incrementBillCount } = useCompanyStore()

  const onDrop = useCallback((accepted: File[]) => {
    if (accepted.length > 1) {
      setMultiFiles(accepted)
      setFile(null)
    } else if (accepted[0]) {
      setFile(accepted[0])
      setMultiFiles([])
    }
  }, [])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'image/*': [], 'application/pdf': [] },
    maxFiles: 10,
    maxSize: 10 * 1024 * 1024,
    onDropRejected: (rejections) => {
      if (rejections.some((r) => r.errors.some((e) => e.code === 'too-many-files'))) {
        toast.error('Maximum 10 bills per upload')
      } else {
        toast.error('File too large or unsupported format')
      }
    },
  })

  // Reset type selection when modal reopens with a different initialType
  useEffect(() => { setSelectedType(initialType) }, [initialType])

  // overrideFile/overrideMultiFiles/overrideType let the auto-submit effect below fire
  // immediately with fresh values instead of waiting a render for state to catch up.
  const handleParse = async (overrideFile?: File | null, overrideMultiFiles?: File[], overrideType?: BillType) => {
    if (!activeCompanyId) return

    const effectiveType  = overrideType ?? selectedType
    const isMiscDebit    = isMiscUpload && effectiveType === 'debit'
    const isMiscCredit   = isMiscUpload && effectiveType === 'credit'
    const billTypeToSave: 'purchase' | 'debit' | 'misc' = isMiscUpload ? 'misc' : effectiveType as 'purchase' | 'debit'
    const f  = overrideFile !== undefined ? overrideFile : file
    const mf = overrideMultiFiles !== undefined ? overrideMultiFiles : multiFiles

    // Multi-file: hand off to parent and close immediately
    if (mf.length > 1) {
      onMultipleFiles(mf, billTypeToSave, isMiscDebit, isMiscCredit)
      handleClose()
      return
    }

    if (!f) return
    setParsing(true)
    setStep(0)
    try {
      const parsed = await parseBillWithAI(f, (s) => setStep(s), billTypeToSave, activeCompanyId)
      let bill     = parsedDataToBill(parsed, activeCompanyId, undefined, billTypeToSave)
      if (isMiscDebit)  bill = { ...bill, tallyMapping: { isDebit:  true } }
      if (isMiscCredit) bill = { ...bill, tallyMapping: { isCredit: true } }
      const saved  = await addBill(bill)
      incrementBillCount(activeCompanyId)
      toast.success('Bill parsed successfully!')
      onParsed(saved.id)
      handleClose()
    } catch (err) {
      const qe = extractQuotaError(err)
      if (qe) {
        setQuotaError(qe)
      } else {
        toast.error(err instanceof Error ? err.message : 'Parsing failed')
      }
    } finally {
      setParsing(false)
      setStep(-1)
    }
  }

  // Cards on the page stage files before the modal opens (matching dashboard-main's
  // inline-dropzone entry points) — seed the modal's file state AND fire the parse
  // immediately, so opening the modal from a card is a single click, not two.
  useEffect(() => {
    if (!open || !initialFiles || initialFiles.length === 0) return
    if (initialFiles.length > 1) {
      setMultiFiles(initialFiles); setFile(null)
      handleParse(null, initialFiles, initialType)
    } else {
      setFile(initialFiles[0]); setMultiFiles([])
      handleParse(initialFiles[0], [], initialType)
    }
  }, [open]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleClose = () => {
    if (parsing) return
    setFile(null)
    setMultiFiles([])
    setStep(-1)
    setQuotaError(null)
    onClose()
  }

  const quotaFooter = <Button variant="outline" onClick={handleClose}>Close</Button>

  const title = isMiscUpload
    ? 'Upload Misc Bill'
    : 'Upload Bill'

  const subtitle = "Upload a photo or PDF of your purchase bill and we'll read it for you"

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title={title}
      subtitle={subtitle}
      footer={
        quotaError ? quotaFooter :
        parsing ? undefined : (
          <>
            <Button variant="outline" onClick={handleClose}>Cancel</Button>
            <Button variant="teal" onClick={() => handleParse()} disabled={!file && multiFiles.length === 0}>
              {multiFiles.length > 1 ? `Upload ${multiFiles.length} Bills` : 'Submit Bill'}
            </Button>
          </>
        )
      }
    >
      {quotaError ? (
        <div className="py-6 flex flex-col items-center gap-4 text-center">
          <div className={cn(
            'w-14 h-14 rounded-full flex items-center justify-center',
            quotaError.type === 'blocked' || quotaError.type === 'unavailable' ? 'bg-red-500/15' : 'bg-amber-500/15',
          )}>
            <AlertTriangle className={cn('w-7 h-7', quotaError.type === 'blocked' || quotaError.type === 'unavailable' ? 'text-red-600 dark:text-red-400' : 'text-amber-600 dark:text-amber-400')} />
          </div>
          <div>
            <p className={cn('text-sm font-bold mb-1', quotaError.type === 'blocked' || quotaError.type === 'unavailable' ? 'text-red-700 dark:text-red-400' : 'text-amber-700 dark:text-amber-400')}>
              {quotaError.type === 'blocked'     ? 'Parsing Disabled' :
               quotaError.type === 'expired'     ? 'Subscription Expired' :
               quotaError.type === 'unavailable' ? 'Service Unavailable' :
                                                   'Parse Limit Reached'}
            </p>
            <p className="text-xs text-muted-foreground leading-relaxed max-w-xs">{quotaError.message}</p>
          </div>
        </div>
      ) : !parsing ? (
        <>
          {/* Bill type selector — Purchase always shown, Debit/Credit when features enabled */}
          {(debitVoucherEnabled || creditVoucherEnabled) && (
            <div className="flex items-center gap-2 mb-4">
              <button
                type="button"
                onClick={() => setSelectedType('purchase')}
                className={cn(
                  'px-3 py-1.5 rounded-lg text-xs font-semibold border transition-all',
                  selectedType === 'purchase'
                    ? 'bg-primary text-primary-foreground border-primary'
                    : 'bg-card text-muted-foreground border-border hover:border-primary/40 hover:text-primary',
                )}
              >
                {isMiscUpload ? 'Misc. Purchases' : 'Purchase'}
              </button>
              {debitVoucherEnabled && (
                <button
                  type="button"
                  onClick={() => setSelectedType('debit')}
                  className={cn(
                    'px-3 py-1.5 rounded-lg text-xs font-semibold border transition-all',
                    selectedType === 'debit'
                      ? 'bg-primary text-primary-foreground border-primary'
                      : 'bg-card text-muted-foreground border-border hover:border-primary/40 hover:text-primary',
                  )}
                >
                  {isMiscUpload ? 'Misc. Debit Note' : 'Debit Note'}
                </button>
              )}
              {creditVoucherEnabled && isMiscUpload && (
                <button
                  type="button"
                  onClick={() => setSelectedType('credit')}
                  className={cn(
                    'px-3 py-1.5 rounded-lg text-xs font-semibold border transition-all',
                    selectedType === 'credit'
                      ? 'bg-primary text-primary-foreground border-primary'
                      : 'bg-card text-muted-foreground border-border hover:border-primary/40 hover:text-primary',
                  )}
                >
                  Misc. Credit Note
                </button>
              )}
            </div>
          )}

          {/* Dropzone */}
          <div
            {...getRootProps()}
            className={cn(
              'border-2 border-dashed rounded-xl p-10 text-center cursor-pointer transition-all',
              isDragActive
                ? 'border-primary bg-primary/10'
                : 'border-border bg-muted hover:border-primary/50 hover:bg-primary/5',
            )}
          >
            <input {...getInputProps()} aria-label="Upload bill file" />
            <div className="w-12 h-12 bg-primary/15 rounded-xl flex items-center justify-center mx-auto mb-3">
              <Upload className="w-5 h-5 text-primary" />
            </div>
            <p className="text-sm font-semibold text-foreground mb-1">
              {isDragActive ? 'Drop it here…' : 'Drop file here or click to browse'}
            </p>
            <p className="text-xs text-muted-foreground">JPG, PNG, PDF — max 10 MB · up to 10 files</p>
          </div>

          {/* Camera capture — opens rear camera on mobile, file picker on desktop */}
          <div className="flex items-center gap-3 my-3">
            <div className="flex-1 border-t border-border" />
            <span className="text-xs text-muted-foreground">or</span>
            <div className="flex-1 border-t border-border" />
          </div>
          <input
            ref={cameraInputRef}
            type="file"
            accept="image/*"
            capture="environment"
            className="hidden"
            onChange={handleCameraCapture}
          />
          <button
            type="button"
            onClick={() => cameraInputRef.current?.click()}
            className="w-full flex items-center justify-center gap-2 px-4 py-3 rounded-xl border-2 border-dashed border-border bg-muted hover:border-primary/50 hover:bg-primary/5 transition-all text-sm font-semibold text-muted-foreground hover:text-primary"
          >
            <Camera className="w-4 h-4" />
            Take a Photo
          </button>

          {/* Selected file(s) */}
          {multiFiles.length > 1 ? (
            <div className="mt-3 flex items-center gap-3 px-4 py-3 bg-primary/10 rounded-lg border border-primary/30">
              <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
              <span className="text-sm font-medium text-foreground flex-1">{multiFiles.length} files selected</span>
              <span className="text-xs text-muted-foreground">{(multiFiles.reduce((s, f) => s + f.size, 0) / 1024).toFixed(0)} KB total</span>
            </div>
          ) : file ? (
            <div className="mt-3 flex items-center gap-3 px-4 py-3 bg-muted rounded-lg border border-border">
              <CheckCircle className="w-4 h-4 text-primary flex-shrink-0" />
              <span className="text-sm font-medium text-foreground flex-1 truncate">{file.name}</span>
              <span className="text-xs text-muted-foreground">{(file.size / 1024).toFixed(0)} KB</span>
            </div>
          ) : null}
        </>
      ) : (
        /* Parsing steps */
        <div className="py-2">
          {STEPS.map((s, i) => {
            const done   = i < step
            const active = i === step
            const idle   = i > step
            return (
              <div key={i} className="flex items-start gap-3 py-3 border-b border-border last:border-0">
                <div className={cn(
                  'w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5',
                  done   && 'bg-emerald-500/15',
                  active && 'bg-primary/15',
                  idle   && 'bg-muted',
                )}>
                  {done   && <CheckCircle className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />}
                  {active && <Loader className="w-4 h-4 text-primary animate-spin" />}
                  {idle   && <Circle className="w-4 h-4 text-muted-foreground/50" />}
                </div>
                <div>
                  <p className={cn('text-sm font-semibold', idle ? 'text-muted-foreground' : 'text-foreground')}>{s.label}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">{s.sub}</p>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </Modal>
  )
}
