import { cn } from '@/lib/utils'
import { forwardRef, type SelectHTMLAttributes } from 'react'

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string
  error?: string
  options: { value: string; label: string }[]
  placeholder?: string
  teal?: boolean
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, options, placeholder, teal, className, id, ...props }, ref) => {
    const selectId = id ?? label?.toLowerCase().replace(/\s+/g, '-')
    return (
      <div className="mb-4">
        {label && (
          <label htmlFor={selectId} className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
            {label}
          </label>
        )}
        <select
          ref={ref}
          id={selectId}
          className={cn(
            'input-base appearance-none cursor-pointer',
            teal && 'input-teal',
            error && 'input-error',
            className,
          )}
          aria-invalid={!!error}
          aria-describedby={error ? `${selectId}-err` : undefined}
          {...props}
        >
          {placeholder && <option value="">{placeholder}</option>}
          {options.map((o) => (
            <option key={o.value} value={o.value}>{o.label}</option>
          ))}
        </select>
        {error && (
          <p id={`${selectId}-err`} role="alert" className="text-xs text-red-600 mt-1">
            {error}
          </p>
        )}
      </div>
    )
  },
)
Select.displayName = 'Select'
