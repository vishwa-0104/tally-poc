import { createContext, useContext, type ReactNode } from 'react'
import { formatCurrency } from '@/lib/utils'

type FormatContextType = {
  compact: boolean
  fmt: (n: number) => string
}

const FormatContext = createContext<FormatContextType | undefined>(undefined)

function formatCompact(n: number): string {
  return `₹${(n / 1000).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}K`
}

/** Controlled by the caller (Dashboard's header owns the "In Thousands" toggle) rather than managing its own state. */
export function FormatProvider({ compact, children }: { compact: boolean; children: ReactNode }) {
  const fmt = (n: number) => (compact ? formatCompact(n) : formatCurrency(n))

  return (
    <FormatContext.Provider value={{ compact, fmt }}>
      {children}
    </FormatContext.Provider>
  )
}

export function useFormat() {
  const ctx = useContext(FormatContext)
  if (!ctx) throw new Error('useFormat must be used within FormatProvider')
  return ctx
}
