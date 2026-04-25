import { useState, useCallback, useRef } from 'react'
import type { ChangeEvent } from 'react'
import { useDropzone } from 'react-dropzone'
import { Camera, Upload, CheckCircle, Circle, Loader } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { parseBillWithAI, parsedDataToBill } from '@/services'
import { useBillStore, useCompanyStore, useAuthStore } from '@/store'
import { cn } from '@/lib/utils'

const STEPS = [
  { label: 'Uploading your bill',       sub: 'Preparing your file…' },
  { label: 'Reading the bill',          sub: 'Scanning vendor details, dates and amounts…' },
  { label: 'Extracting line items',     sub: 'Picking up item names, quantities and tax rates…' },
  { label: 'Almost done',               sub: 'Saving your bill…' },
]

interface UploadModalProps {
  open: boolean
  onClose: () => void
  onParsed: (billId: string) => void
  onMultipleFiles: (files: File[]) => void
}

export function UploadModal({ open, onClose, onParsed, onMultipleFiles }: UploadModalProps) {
  const [file, setFile]           = useState<File | null>(null)
  const [multiFiles, setMultiFiles] = useState<File[]>([])
  const [parsing, setParsing]     = useState(false)
  const [step, setStep]           = useState(-1)
  const cameraInputRef            = useRef<HTMLInputElement>(null)

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

  const handleParse = async () => {
    if (!activeCompanyId) return

    // Multi-file: hand off to parent and close immediately
    if (multiFiles.length > 1) {
      onMultipleFiles(multiFiles)
      handleClose()
      return
    }

    if (!file) return
    setParsing(true)
    setStep(0)
    try {
      const parsed = await parseBillWithAI(file, (s) => setStep(s))
      const bill   = parsedDataToBill(parsed, activeCompanyId)
      addBill(bill)
      incrementBillCount(activeCompanyId)
      toast.success('Bill parsed successfully!')
      onParsed(bill.id)
      handleClose()
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Parsing failed')
    } finally {
      setParsing(false)
      setStep(-1)
    }
  }

  const handleClose = () => {
    if (parsing) return
    setFile(null)
    setMultiFiles([])
    setStep(-1)
    onClose()
  }

  return (
    <Modal
      open={open}
      onClose={handleClose}
      title="Upload Bill"
      subtitle="Upload a photo or PDF of your purchase bill and we'll read it for you"
      footer={
        parsing ? undefined : (
          <>
            <Button variant="outline" onClick={handleClose}>Cancel</Button>
            <Button variant="teal" onClick={handleParse} disabled={!file && multiFiles.length === 0}>
              {multiFiles.length > 1 ? `Upload ${multiFiles.length} Bills` : 'Read Bill'}
            </Button>
          </>
        )
      }
    >
      {!parsing ? (
        <>
          {/* Dropzone */}
          <div
            {...getRootProps()}
            className={cn(
              'border-2 border-dashed rounded-xl p-10 text-center cursor-pointer transition-all',
              isDragActive
                ? 'border-teal-500 bg-teal-50'
                : 'border-gray-200 bg-gray-50 hover:border-teal-400 hover:bg-teal-50/50',
            )}
          >
            <input {...getInputProps()} aria-label="Upload bill file" />
            <div className="w-12 h-12 bg-teal-100 rounded-xl flex items-center justify-center mx-auto mb-3">
              <Upload className="w-5 h-5 text-teal-600" />
            </div>
            <p className="text-sm font-semibold text-gray-700 mb-1">
              {isDragActive ? 'Drop it here…' : 'Drop file here or click to browse'}
            </p>
            <p className="text-xs text-gray-500">JPG, PNG, PDF — max 10 MB · up to 10 files</p>
          </div>

          {/* Camera capture — opens rear camera on mobile, file picker on desktop */}
          <div className="flex items-center gap-3 my-3">
            <div className="flex-1 border-t border-gray-200" />
            <span className="text-xs text-gray-500">or</span>
            <div className="flex-1 border-t border-gray-200" />
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
            className="w-full flex items-center justify-center gap-2 px-4 py-3 rounded-xl border-2 border-dashed border-gray-200 bg-gray-50 hover:border-teal-400 hover:bg-teal-50/50 transition-all text-sm font-semibold text-gray-600 hover:text-teal-700"
          >
            <Camera className="w-4 h-4" />
            Take a Photo
          </button>

          {/* Selected file(s) */}
          {multiFiles.length > 1 ? (
            <div className="mt-3 flex items-center gap-3 px-4 py-3 bg-teal-50 rounded-lg border border-teal-200">
              <CheckCircle className="w-4 h-4 text-teal-500 flex-shrink-0" />
              <span className="text-sm font-medium text-gray-800 flex-1">{multiFiles.length} files selected</span>
              <span className="text-xs text-gray-500">{(multiFiles.reduce((s, f) => s + f.size, 0) / 1024).toFixed(0)} KB total</span>
            </div>
          ) : file ? (
            <div className="mt-3 flex items-center gap-3 px-4 py-3 bg-gray-50 rounded-lg border border-gray-200">
              <CheckCircle className="w-4 h-4 text-teal-500 flex-shrink-0" />
              <span className="text-sm font-medium text-gray-800 flex-1 truncate">{file.name}</span>
              <span className="text-xs text-gray-500">{(file.size / 1024).toFixed(0)} KB</span>
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
              <div key={i} className="flex items-start gap-3 py-3 border-b border-gray-100 last:border-0">
                <div className={cn(
                  'w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5',
                  done   && 'bg-emerald-50',
                  active && 'bg-teal-50',
                  idle   && 'bg-gray-100',
                )}>
                  {done   && <CheckCircle className="w-4 h-4 text-emerald-500" />}
                  {active && <Loader className="w-4 h-4 text-teal-500 animate-spin" />}
                  {idle   && <Circle className="w-4 h-4 text-gray-300" />}
                </div>
                <div>
                  <p className={cn('text-sm font-semibold', idle ? 'text-gray-500' : 'text-gray-800')}>{s.label}</p>
                  <p className="text-xs text-gray-500 mt-0.5">{s.sub}</p>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </Modal>
  )
}
