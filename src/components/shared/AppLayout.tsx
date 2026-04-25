import { useState } from 'react'
import type { ReactNode } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { LogOut, Menu, X, type LucideIcon } from 'lucide-react'
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
  const { user, logout, companies, activeCompanyId, switchCompany } = useAuthStore()
  const navigate  = useNavigate()
  const location  = useLocation()
  const isAdmin   = role === 'admin'
  const [drawerOpen, setDrawerOpen] = useState(false)

  const activeCompany = companies.find((c) => c.id === activeCompanyId)

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  const handleNavClick = () => setDrawerOpen(false)

  const sidebarBg   = isAdmin ? 'bg-gray-900' : 'bg-[#021A12]'
  const iconBg      = isAdmin ? 'bg-brand-500' : 'bg-teal-500'
  const pillBg      = isAdmin ? 'bg-blue-900/50 text-blue-300' : 'bg-teal-900/40 text-teal-300'
  const activeClass = isAdmin ? 'bg-brand-500 text-white' : 'bg-teal-600 text-white'
  const avatarBg    = isAdmin ? 'bg-brand-500' : 'bg-teal-600'

  const sidebarContent = (
    <>
      {/* Logo */}
      <div className="flex items-center gap-2.5 px-2 mb-2">
        <div className={cn('w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0', iconBg)}>
          <svg className="w-4 h-4 stroke-white fill-none stroke-2" viewBox="0 0 24 24">
            <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
          </svg>
        </div>
        {/* Label — hidden on tablet icon-rail, shown otherwise */}
        <span className="text-sm font-bold text-white md:hidden lg:block">Tally Sync</span>
      </div>

      {/* Role pill */}
      <span className={cn('mx-2 mb-5 px-2.5 py-0.5 rounded text-[10px] font-bold tracking-widest uppercase w-fit md:hidden lg:block', pillBg)}>
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
              onClick={handleNavClick}
              title={item.label}
              className={cn(
                'flex items-center gap-2.5 px-2.5 py-2 rounded-lg text-xs font-medium transition-all',
                'md:justify-center md:px-2 lg:justify-start lg:px-2.5',
                active ? activeClass : 'text-gray-400 hover:text-white hover:bg-white/8',
              )}
              aria-current={active ? 'page' : undefined}
            >
              <item.icon className="w-4 h-4 flex-shrink-0" />
              <span className="md:hidden lg:block">{item.label}</span>
            </Link>
          )
        })}
      </div>

      {/* Company switcher — shown for company role */}
      {companies.length > 0 && (
        <div className="mb-3 px-1">
          <select
            value={activeCompanyId ?? ''}
            onChange={(e) => switchCompany(e.target.value)}
            className="w-full text-xs bg-white/10 text-white rounded-lg px-2 py-1.5 border border-white/20 focus:outline-none cursor-pointer md:hidden lg:block"
          >
            {companies.map((c) => (
              <option key={c.id} value={c.id} className="text-gray-900">{c.name}</option>
            ))}
          </select>
          {/* Icon rail (tablet md): 2-letter abbreviation */}
          <div className="hidden md:flex lg:hidden justify-center text-[10px] font-bold text-teal-300 py-1" title={activeCompany?.name}>
            {activeCompany?.name?.slice(0, 2).toUpperCase()}
          </div>
        </div>
      )}

      {/* User tile */}
      <div className="mt-auto">
        <div className={cn('flex items-center gap-2.5 p-2.5 rounded-lg md:justify-center lg:justify-start', isAdmin ? 'bg-white/6' : 'bg-teal-900/20')}>
          <div className={cn('w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0', avatarBg)}>
            {user?.avatar}
          </div>
          <div className="min-w-0 md:hidden lg:block">
            <p className="text-xs font-semibold text-white truncate">{user?.name}</p>
            <p className="text-[10px] text-gray-500 truncate">{user?.email}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          title="Sign out"
          className="flex items-center gap-2.5 px-2.5 py-2 mt-1 w-full rounded-lg text-xs font-medium text-gray-500 hover:text-white hover:bg-white/8 transition-all md:justify-center md:px-2 lg:justify-start lg:px-2.5"
        >
          <LogOut className="w-4 h-4" />
          <span className="md:hidden lg:block">Sign out</span>
        </button>
      </div>
    </>
  )

  return (
    <div className="flex min-h-screen">

      {/* ── Desktop / Tablet sidebar (hidden on mobile) ── */}
      <nav
        className={cn(
          'hidden md:flex flex-shrink-0 flex-col py-5 px-3.5',
          'md:w-14 lg:w-60',           // icon-rail on tablet, full on desktop
          sidebarBg,
        )}
        aria-label="Main navigation"
      >
        {sidebarContent}
      </nav>

      {/* ── Mobile drawer backdrop ── */}
      {drawerOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 md:hidden"
          onClick={() => setDrawerOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* ── Mobile drawer ── */}
      <nav
        className={cn(
          'fixed inset-y-0 left-0 z-50 flex flex-col px-3.5 py-5 w-64 transition-transform duration-300 md:hidden',
          sidebarBg,
          drawerOpen ? 'translate-x-0' : '-translate-x-full',
        )}
        aria-label="Main navigation"
      >
        {/* Close button inside drawer */}
        <button
          onClick={() => setDrawerOpen(false)}
          className="absolute top-4 right-4 text-gray-400 hover:text-white transition-colors"
          aria-label="Close menu"
        >
          <X className="w-5 h-5" />
        </button>
        {sidebarContent}
      </nav>

      {/* ── Main content ── */}
      <main className="flex-1 overflow-y-auto min-w-0">
        {/* Mobile top bar with hamburger */}
        <div className={cn('sticky top-0 z-30 flex items-center gap-3 px-4 py-3 border-b border-gray-200 md:hidden', sidebarBg)}>
          <button
            onClick={() => setDrawerOpen(true)}
            className="text-gray-300 hover:text-white transition-colors"
            aria-label="Open menu"
          >
            <Menu className="w-5 h-5" />
          </button>
          <span className="text-sm font-bold text-white">Tally Sync</span>
        </div>
        {children}
      </main>
    </div>
  )
}
