import { cn } from '@/lib/utils'
import type { ButtonHTMLAttributes } from 'react'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'teal' | 'outline' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
}

const variants = {
  primary: 'btn-primary',
  teal:    'btn-teal',
  outline: 'btn-outline',
  danger:  'btn-danger',
}

const sizes = {
  sm: 'btn-sm',
  md: '',
  lg: 'btn-lg',
}

export function Button({
  variant = 'primary',
  size = 'md',
  loading = false,
  disabled,
  children,
  className,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn('btn-base', variants[variant], sizes[size], className)}
      disabled={disabled || loading}
      {...props}
    >
      {loading && (
        <span className="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin-sm" />
      )}
      {children}
    </button>
  )
}
