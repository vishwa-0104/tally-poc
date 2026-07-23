import type { ReactNode } from 'react'
import { Menu } from 'lucide-react'
import { useCompanySidebarStore } from '@/store/companySidebarStore'
import { CompanyHeaderMenu } from './company-header-menu'

interface CompanyPageHeaderProps {
  title: string
  subtitle?: string
  actions?: ReactNode
}

export function CompanyPageHeader({ title, subtitle, actions }: CompanyPageHeaderProps) {
  const { collapsed, isOverlay, setCollapsed } = useCompanySidebarStore()

  return (
    <header className="top-0 z-10 border-b border-border bg-background py-2.5 ">
      <div className="flex items-center justify-between gap-3 px-4 py-2 sm:px-7">
        <div className="flex items-center gap-2.5 min-w-0">
          {isOverlay && collapsed && (
            <button
              type="button"
              aria-label="Open menu"
              onClick={() => setCollapsed(false)}
              className="flex size-8 shrink-0 items-center justify-center rounded-full border border-border bg-background shadow-sm"
            >
              <Menu className="size-4" />
            </button>
          )}
          <div className="min-w-0">
            <h1 className="text-xs font-semibold text-foreground sm:text-sm">{title}</h1>
            {subtitle && <p className="mt-0.5 text-xs text-muted-foreground sm:text-xs">{subtitle}</p>}
          </div>
        </div>
        <div className="flex items-center gap-2.5">
          {actions}
          <CompanyHeaderMenu />
        </div>
      </div>
    </header>
  )
}
