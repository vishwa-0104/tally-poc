import { cn } from '@/lib/utils'

interface StatCardProps {
  label: string
  value: number | string
  sub?: string
  accent: 'blue' | 'green' | 'amber' | 'red'
}

const accentMap = {
  blue:  'border-t-brand-500',
  green: 'border-t-emerald-500',
  amber: 'border-t-amber-500',
  red:   'border-t-red-500',
}

const valueColor = {
  blue:  'text-gray-900',
  green: 'text-emerald-600',
  amber: 'text-amber-600',
  red:   'text-red-600',
}

export function StatCard({ label, value, sub, accent }: StatCardProps) {
  return (
    <div className={cn('card p-5 border-t-4', accentMap[accent])}>
      <p className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">{label}</p>
      <p className={cn('text-3xl font-bold leading-none', valueColor[accent])}>{value}</p>
      {sub && <p className="text-xs text-gray-400 mt-1">{sub}</p>}
    </div>
  )
}
