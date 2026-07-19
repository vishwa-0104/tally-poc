import { useRef, useState, type ChangeEvent } from 'react'
import { Upload, Camera, FileText, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/shadcn/components/ui/button'
import { Card, CardHeader, CardTitle, CardContent } from '@/shadcn/components/ui/card'

type FileWithPreview = {
  file: File
  preview: string
}

interface UploadCardProps {
  title: string
  onSubmit: (files: File[]) => void
  multiple?: boolean
  disabled?: boolean
  disabledMessage?: string
}

export function UploadCard({ title, onSubmit, multiple = true, disabled = false, disabledMessage }: UploadCardProps) {
  const inputRef  = useRef<HTMLInputElement>(null)
  const cameraRef = useRef<HTMLInputElement>(null)
  const [files, setFiles] = useState<FileWithPreview[]>([])

  const addFiles = (newFiles: FileList | null) => {
    if (!newFiles || disabled) return
    const entries = Array.from(newFiles).map((file) => ({ file, preview: URL.createObjectURL(file) }))
    setFiles((prev) => (multiple ? [...prev, ...entries] : entries.slice(0, 1)))
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    if (!disabled) addFiles(e.dataTransfer.files)
  }

  const removeFile = (idx: number) => {
    setFiles((prev) => {
      URL.revokeObjectURL(prev[idx].preview)
      return prev.filter((_, i) => i !== idx)
    })
  }

  const handleSubmit = () => {
    onSubmit(files.map((f) => f.file))
    setFiles([])
  }

  const handleCancel = () => {
    files.forEach((f) => URL.revokeObjectURL(f.preview))
    setFiles([])
  }

  const acceptedTypes = '.pdf,.png,.jpg,.jpeg'

  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div
          onDragOver={(e) => e.preventDefault()}
          onDrop={handleDrop}
          onClick={() => !disabled && inputRef.current?.click()}
          className={cn(
            'flex flex-col items-center gap-2 rounded-2xl border-2 border-dashed border-border bg-muted/30 p-4 transition-colors sm:gap-3 sm:p-8',
            disabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer hover:border-primary/50 hover:bg-muted/50',
          )}
        >
          <Upload className="size-8 text-muted-foreground" />
          <div className="text-center">
            <p className="text-sm font-medium">{disabled && disabledMessage ? disabledMessage : 'Drag & drop files here'}</p>
            {!(disabled && disabledMessage) && (
              <p className="mt-1 text-xs text-muted-foreground">PDF, PNG, JPG up to 10MB</p>
            )}
          </div>
          <div className="mt-2 flex flex-col gap-2 sm:flex-row">
            <Button
              size="sm"
              variant="secondary"
              className="w-full sm:w-auto"
              disabled={disabled}
              onClick={(e) => { e.stopPropagation(); inputRef.current?.click() }}
            >
              <FileText className="size-4" />
              Browse Files
            </Button>
            <Button
              size="sm"
              variant="secondary"
              className="w-full sm:w-auto"
              disabled={disabled}
              onClick={(e) => { e.stopPropagation(); cameraRef.current?.click() }}
            >
              <Camera className="size-4" />
              Take a Photo
            </Button>
          </div>
          <input
            ref={inputRef}
            type="file"
            accept={acceptedTypes}
            multiple={multiple}
            className="hidden"
            onChange={(e: ChangeEvent<HTMLInputElement>) => { addFiles(e.target.files); e.target.value = '' }}
          />
          <input
            ref={cameraRef}
            type="file"
            accept="image/*"
            capture="environment"
            className="hidden"
            onChange={(e: ChangeEvent<HTMLInputElement>) => { addFiles(e.target.files); e.target.value = '' }}
          />
        </div>

        {files.length > 0 && (
          <div className="space-y-2">
            <p className="text-xs font-medium text-muted-foreground">{files.length} file(s) selected</p>
            <div className="flex flex-wrap gap-2">
              {files.map((f, i) => (
                <div key={i} className="group relative size-16 overflow-hidden rounded-xl border border-border bg-muted">
                  {f.file.type.startsWith('image/') ? (
                    <img src={f.preview} alt="" className="size-full object-cover" />
                  ) : (
                    <div className="flex size-full items-center justify-center">
                      <FileText className="size-6 text-muted-foreground" />
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={() => removeFile(i)}
                    className="absolute right-0.5 top-0.5 flex size-4 items-center justify-center rounded-full bg-background/80 opacity-0 transition-opacity group-hover:opacity-100"
                  >
                    <X className="size-3" />
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="flex gap-2">
          <Button onClick={handleSubmit} disabled={files.length === 0 || disabled} className="flex-1">
            <Upload className="size-4" />
            Submit
          </Button>
          <Button variant="outline" onClick={handleCancel} disabled={files.length === 0} className="flex-1">
            Cancel
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
