import { useEffect, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import {
  ChevronLeft,
  ChevronRight,
  X,
  ChevronDown,
  type LucideIcon,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { Avatar, AvatarFallback } from '@/shadcn/components/ui/avatar'

export interface NavLeaf {
  label: string
  path: string
  icon: LucideIcon
}

export interface NavGroup {
  label: string
  icon: LucideIcon
  items: NavLeaf[]
}

interface CompanySidebarProps {
  topItems: NavLeaf[]
  groups: NavGroup[]
  bottomItems: NavLeaf[]
  collapsed: boolean
  onToggle: (v: boolean) => void
  isOverlay: boolean
  onClose: () => void
}

export function CompanySidebar({
  topItems,
  groups,
  bottomItems,
  collapsed,
  onToggle,
  isOverlay,
  onClose,
}: CompanySidebarProps) {
  const location = useLocation()
  const [openGroups, setOpenGroups] = useState<Record<string, boolean>>({})

  useEffect(() => {
    if (collapsed) setOpenGroups({})
  }, [collapsed])

  const showAsCollapsed = collapsed && !isOverlay
  // Several nav items (Purchase/Expenses/Debit Note/Credit Note) point at the same
  // pathname with different `?type=` query strings — pathname-only matching would
  // highlight all of them at once, so items carrying a query string need an exact
  // pathname+type match instead of the usual prefix match.
  const isActive = (path: string) => {
    const [itemPath, itemQuery] = path.split('?')
    if (itemQuery) {
      const itemType = new URLSearchParams(itemQuery).get('type')
      return location.pathname === itemPath && new URLSearchParams(location.search).get('type') === itemType
    }
    return (location.pathname === itemPath || location.pathname.startsWith(itemPath + '/')) && !location.search
  }
  const handleNavClick = isOverlay ? onClose : undefined

  const leafClass = (active: boolean) =>
    cn(
      'flex w-full items-center rounded-sm px-3 py-2.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
      active
        ? 'bg-primary/10 text-foreground hover:bg-primary/15'
        : 'text-muted-foreground hover:bg-primary/5 hover:text-foreground',
      showAsCollapsed && 'justify-center px-0',
    )

  return (
    <aside
      className={cn(
        'fixed left-0 top-0 z-40 flex h-screen flex-col border-r border-border bg-sidebar-bg transition-all duration-300',
        isOverlay
          ? collapsed
            ? '-translate-x-full'
            : 'w-60 translate-x-0 shadow-2xl'
          : collapsed
            ? 'w-16'
            : 'w-60',
      )}
    >
      {!isOverlay && (
        <button
          type="button"
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          onClick={() => onToggle(!collapsed)}
          className="absolute -right-3 top-6 z-[60] flex size-6 items-center justify-center rounded-full border border-border bg-background shadow-sm transition-all hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
        >
          {collapsed ? <ChevronRight className="size-3.5" /> : <ChevronLeft className="size-3.5" />}
        </button>
      )}

      {isOverlay && !collapsed && (
        <button
          type="button"
          aria-label="Close sidebar"
          onClick={onClose}
          className="absolute right-3 top-5 z-[60] flex size-6 items-center justify-center rounded-full hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <X className="size-4" />
        </button>
      )}

      <div className={cn('flex items-center border-border px-4 py-5', showAsCollapsed ? 'justify-center' : 'gap-3')}>
        <Avatar size={showAsCollapsed ? 'sm' : 'default'}>
          <AvatarFallback className="bg-primary text-primary-foreground font-bold text-lg">
            S
          </AvatarFallback>
        </Avatar>
        {!showAsCollapsed && (
          <span className="text-lg font-semibold text-foreground">SyncInvoice</span>
        )}
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto px-2 py-4" aria-label="Main navigation">
        {topItems.map(item => {
          const active = isActive(item.path)
          return (
            <Link
              key={item.path}
              to={item.path}
              onClick={handleNavClick}
              title={item.label}
              aria-current={active ? 'page' : undefined}
              className={leafClass(active)}
            >
              <item.icon className={cn('size-5 shrink-0', showAsCollapsed ? '' : 'mr-3')} />
              {!showAsCollapsed && <span>{item.label}</span>}
            </Link>
          )
        })}

        {groups.map(group => {
          const open = !!openGroups[group.label]
          const groupHasActive = group.items.some(item => isActive(item.path))
          return (
            <div key={group.label}>
              <button
                type="button"
                onClick={showAsCollapsed ? () => onToggle(false) : () => setOpenGroups(g => ({ ...g, [group.label]: !open }))}
                className={cn(
                  'flex w-full items-center rounded-sm px-3 py-2.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
                  groupHasActive ? 'text-foreground' : 'text-muted-foreground hover:bg-primary/5 hover:text-foreground',
                  showAsCollapsed && 'justify-center px-0',
                )}
              >
                <group.icon className={cn('size-5 shrink-0', showAsCollapsed ? '' : 'mr-3')} />
                {!showAsCollapsed && (
                  <>
                    <span className="flex-1 text-left">{group.label}</span>
                    <ChevronDown
                      className={cn('size-3.5 text-muted-foreground transition-transform duration-200', open && 'rotate-180')}
                    />
                  </>
                )}
              </button>

              <div className={cn('grid transition-all duration-300 ease-in-out', open ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0')}>
                <div className="overflow-hidden">
                  <div className="space-y-0.5 pl-9 pt-1">
                    {group.items.map(item => {
                      const active = isActive(item.path)
                      return (
                        <Link
                          key={item.path}
                          to={item.path}
                          onClick={handleNavClick}
                          aria-current={active ? 'page' : undefined}
                          className={cn(
                            'flex w-full items-center rounded-sm px-3 py-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
                            active
                              ? 'bg-primary/10 text-foreground hover:bg-primary/15'
                              : 'text-muted-foreground hover:bg-primary/5 hover:text-foreground',
                          )}
                        >
                          <item.icon className="mr-3 size-4 shrink-0" />
                          <span className="truncate">{item.label}</span>
                        </Link>
                      )
                    })}
                  </div>
                </div>
              </div>
            </div>
          )
        })}

        {bottomItems.map(item => {
          const active = isActive(item.path)
          return (
            <Link
              key={item.path}
              to={item.path}
              onClick={handleNavClick}
              title={item.label}
              aria-current={active ? 'page' : undefined}
              className={leafClass(active)}
            >
              <item.icon className={cn('size-5 shrink-0', showAsCollapsed ? '' : 'mr-3')} />
              {!showAsCollapsed && <span>{item.label}</span>}
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
