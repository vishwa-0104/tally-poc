import { useEffect, type ReactNode } from 'react'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils'

interface ModalProps {
  open: boolean
  onClose: () => void
  title: string
  subtitle?: string
  children: ReactNode
  footer?: ReactNode
  wide?: boolean
}

export function Modal({ open, onClose, title, subtitle, children, footer, wide }: ModalProps) {
  // Close on Escape
  useEffect(() => {
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    if (open) document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [open, onClose])

  if (!open) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      onClick={(e) => { if (e.target === e.currentTarget) onClose() }}
    >
      <div className={cn('card animate-modal w-full max-h-[90vh] overflow-y-auto', wide ? 'max-w-2xl' : 'max-w-lg')}>
        {/* Header */}
        <div className="flex items-start justify-between p-6 pb-0">
          <div>
            <h2 id="modal-title" className="text-lg font-bold text-gray-900">{title}</h2>
            {subtitle && <p className="text-xs text-gray-500 mt-0.5">{subtitle}</p>}
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg bg-gray-100 hover:bg-gray-200 flex items-center justify-center transition-colors"
            aria-label="Close modal"
          >
            <X className="w-4 h-4 text-gray-600" />
          </button>
        </div>
        {/* Body */}
        <div className="p-6">{children}</div>
        {/* Footer */}
        {footer && (
          <div className="flex gap-2 justify-end px-6 pb-6">{footer}</div>
        )}
      </div>
    </div>
  )
}
