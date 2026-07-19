import type { ReactNode } from 'react'
import { CompanyHeaderMenu } from './company-header-menu'

interface CompanyPageHeaderProps {
  title: string
  subtitle?: string
  actions?: ReactNode
}

export function CompanyPageHeader({ title, subtitle, actions }: CompanyPageHeaderProps) {
  return (
    <header className="sticky top-0 z-10 border-b border-border bg-background">
      <div className="flex items-center justify-between gap-3 px-4 py-3 sm:px-7">
        <div>
          <h1 className="text-lg font-semibold text-foreground sm:text-2xl">{title}</h1>
          {subtitle && <p className="mt-0.5 text-xs text-muted-foreground sm:text-sm">{subtitle}</p>}
        </div>
        <div className="flex items-center gap-2.5">
          {actions}
          <CompanyHeaderMenu />
        </div>
      </div>
    </header>
  )
}
