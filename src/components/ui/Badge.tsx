import { cn } from '@/lib/utils'
import type { BillStatus } from '@/types'

const variantMap: Record<string, string> = {
  green:  'badge-green',
  amber:  'badge-amber',
  red:    'badge-red',
  blue:   'badge-blue',
  teal:   'badge-teal',
  gray:   'badge-gray',
}

interface BadgeProps {
  variant?: keyof typeof variantMap
  children: React.ReactNode
  className?: string
}

export function Badge({ variant = 'gray', children, className }: BadgeProps) {
  return (
    <span className={cn('badge', variantMap[variant], className)}>
      {children}
    </span>
  )
}

const statusMap: Record<BillStatus, { variant: string; label: string }> = {
  synced:  { variant: 'green', label: 'Synced' },
  parsed:  { variant: 'teal',  label: 'AI Parsed' },
  mapped:  { variant: 'amber', label: 'Ready to Sync' },
  pending: { variant: 'gray',  label: 'Pending' },
  error:   { variant: 'red',   label: 'Sync Error' },
}

export function StatusBadge({ status }: { status: BillStatus }) {
  const { variant, label } = statusMap[status]
  return <Badge variant={variant as keyof typeof variantMap}>{label}</Badge>
}
