import { cn } from '@/lib/utils'
import { forwardRef, type InputHTMLAttributes } from 'react'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  teal?: boolean
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, teal, className, id, ...props }, ref) => {
    const inputId = id ?? label?.toLowerCase().replace(/\s+/g, '-')
    return (
      <div className="mb-4">
        {label && (
          <label htmlFor={inputId} className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={cn(
            'input-base',
            teal && 'input-teal',
            error && 'input-error',
            className,
          )}
          aria-invalid={!!error}
          aria-describedby={error ? `${inputId}-err` : undefined}
          {...props}
        />
        {error && (
          <p id={`${inputId}-err`} role="alert" className="text-xs text-red-600 mt-1">
            {error}
          </p>
        )}
      </div>
    )
  },
)
Input.displayName = 'Input'
