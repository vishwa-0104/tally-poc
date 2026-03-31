import type { ReactNode } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { LogOut, type LucideIcon } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store'

export interface NavItem {
  label: string
  path: string
  icon: LucideIcon
}

interface AppLayoutProps {
  navItems: NavItem[]
  children: ReactNode
  role: 'admin' | 'company'
}

export function AppLayout({ navItems, children, role }: AppLayoutProps) {
  const { user, logout } = useAuthStore()
  const navigate  = useNavigate()
  const location  = useLocation()
  const isAdmin   = role === 'admin'

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  const sidebarBg   = isAdmin ? 'bg-gray-900' : 'bg-[#021A12]'
  const iconBg      = isAdmin ? 'bg-brand-500' : 'bg-teal-500'
  const pillBg      = isAdmin ? 'bg-blue-900/50 text-blue-300' : 'bg-teal-900/40 text-teal-300'
  const activeClass = isAdmin ? 'bg-brand-500 text-white' : 'bg-teal-600 text-white'
  const avatarBg    = isAdmin ? 'bg-brand-500' : 'bg-teal-600'

  return (
    <div className="flex min-h-screen">
      {/* ── Sidebar ── */}
      <nav className={cn('w-60 flex-shrink-0 flex flex-col px-3.5 py-5', sidebarBg)} aria-label="Main navigation">
        {/* Logo */}
        <div className="flex items-center gap-2.5 px-2 mb-2">
          <div className={cn('w-8 h-8 rounded-lg flex items-center justify-center', iconBg)}>
            <svg className="w-4 h-4 stroke-white fill-none stroke-2" viewBox="0 0 24 24">
              <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
          </div>
          <span className="text-sm font-bold text-white">Tally Sync</span>
        </div>

        {/* Role pill */}
        <span className={cn('mx-2 mb-5 px-2.5 py-0.5 rounded text-[10px] font-bold tracking-widest uppercase w-fit', pillBg)}>
          {isAdmin ? 'Admin' : 'Company'}
        </span>

        {/* Nav items */}
        <div className="flex-1 space-y-0.5">
          {navItems.map((item) => {
            const active = location.pathname === item.path || location.pathname.startsWith(item.path + '/')
            return (
              <Link
                key={item.path}
                to={item.path}
                className={cn(
                  'flex items-center gap-2.5 px-2.5 py-2 rounded-lg text-xs font-medium transition-all',
                  active ? activeClass : 'text-gray-400 hover:text-white hover:bg-white/8',
                )}
                aria-current={active ? 'page' : undefined}
              >
                <item.icon className="w-4 h-4 flex-shrink-0" />
                {item.label}
              </Link>
            )
          })}
        </div>

        {/* User tile */}
        <div className="mt-auto">
          <div className={cn('flex items-center gap-2.5 p-2.5 rounded-lg', isAdmin ? 'bg-white/6' : 'bg-teal-900/20')}>
            <div className={cn('w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0', avatarBg)}>
              {user?.avatar}
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold text-white truncate">{user?.name}</p>
              <p className="text-[10px] text-gray-500 truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2.5 px-2.5 py-2 mt-1 w-full rounded-lg text-xs font-medium text-gray-500 hover:text-white hover:bg-white/8 transition-all"
          >
            <LogOut className="w-4 h-4" />
            Sign out
          </button>
        </div>
      </nav>

      {/* ── Main ── */}
      <main className="flex-1 overflow-y-auto min-w-0">{children}</main>
    </div>
  )
}
