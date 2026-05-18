import { useState } from 'react'
import type { ReactNode } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { LogOut, Menu, X, ChevronRight, ChevronLeft, type LucideIcon } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store'
import invoiceSyncSvg from '../../assets/sync-invoice-logo-white.svg'

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
  const [drawerOpen,  setDrawerOpen]  = useState(false)
  const [collapsed,   setCollapsed]   = useState(true)

  const activeCompany = companies.find((c) => c.id === activeCompanyId)

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  const handleNavClick = () => setDrawerOpen(false)

  const sidebarBg   = isAdmin ? 'bg-gray-900' : 'bg-[#021A12]'
  const activeClass = isAdmin ? 'bg-brand-500 text-white' : 'bg-teal-600 text-white'
  const avatarBg    = isAdmin ? 'bg-brand-500' : 'bg-teal-600'

  const sidebarContent = (collapsed: boolean) => (
    <>
      {/* Logo + toggle */}
      <div className={cn('flex items-center mb-4', collapsed ? 'justify-center px-1' : 'justify-between px-1')}>
        {!collapsed && (
          <div className="flex items-center justify-center flex-shrink-0 w-28 h-8">
            <img className="w-full h-4.5 object-contain" src={invoiceSyncSvg} alt="InvoiceSync" />
          </div>
        )}
        <button
          onClick={() => setCollapsed((c) => !c)}
          title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          className="p-1.5 rounded-lg text-gray-400 hover:text-white hover:bg-white/10 transition-all flex-shrink-0"
        >
          {collapsed ? <ChevronRight className="w-4 h-4" /> : <ChevronLeft className="w-4 h-4" />}
        </button>
      </div>

      {/* Role pill */}
      {!collapsed && isAdmin && (
        <span className="mx-2 mb-4 px-2.5 py-0.5 rounded text-[10px] font-bold tracking-widest uppercase w-fit text-gray-400">
          Admin
        </span>
      )}

      {/* Nav items */}
      <div className="flex-1 space-y-0.5 overflow-y-auto">
        {navItems.map((item) => {
          const active = location.pathname === item.path || location.pathname.startsWith(item.path + '/')
          return (
            <Link
              key={item.path}
              to={item.path}
              onClick={handleNavClick}
              title={item.label}
              className={cn(
                'flex items-center gap-2.5 py-2 rounded-lg text-xs font-medium transition-all',
                collapsed ? 'justify-center px-2' : 'justify-start px-2.5',
                active ? activeClass : 'text-gray-400 hover:text-white hover:bg-white/8',
              )}
              aria-current={active ? 'page' : undefined}
            >
              <item.icon className="w-4 h-4 flex-shrink-0" />
              {!collapsed && <span>{item.label}</span>}
            </Link>
          )
        })}
      </div>

      {/* Company switcher */}
      {companies.length > 0 && (
        <div className="mb-3 px-1">
          {!collapsed ? (
            <select
              value={activeCompanyId ?? ''}
              onChange={(e) => switchCompany(e.target.value)}
              className="w-full text-xs bg-white/10 text-white rounded-lg px-2 py-1.5 border border-white/20 focus:outline-none cursor-pointer"
            >
              {companies.map((c) => (
                <option key={c.id} value={c.id} className="text-gray-900">{c.name}</option>
              ))}
            </select>
          ) : (
            <div className="flex justify-center text-[10px] font-bold text-teal-300 py-1" title={activeCompany?.name}>
              {activeCompany?.name?.slice(0, 2).toUpperCase()}
            </div>
          )}
        </div>
      )}

      {/* User tile */}
      <div className="mt-auto">
        <div className={cn(
          'flex items-center gap-2.5 p-2.5 rounded-lg',
          collapsed ? 'justify-center' : 'justify-start',
          isAdmin ? 'bg-white/6' : 'bg-teal-900/20',
        )}>
          <div className={cn('w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0', avatarBg)}>
            {user?.avatar}
          </div>
          {!collapsed && (
            <div className="min-w-0">
              <p className="text-xs font-semibold text-white truncate">{user?.name}</p>
              <p className="text-[10px] text-gray-500 truncate">{user?.email}</p>
            </div>
          )}
        </div>
        <button
          onClick={handleLogout}
          title="Sign out"
          className={cn(
            'flex items-center gap-2.5 py-2 mt-1 w-full rounded-lg text-xs font-medium text-gray-500 hover:text-white hover:bg-white/8 transition-all',
            collapsed ? 'justify-center px-2' : 'justify-start px-2.5',
          )}
        >
          <LogOut className="w-4 h-4" />
          {!collapsed && <span className="text-teal-400">Sign out</span>}
        </button>
      </div>
    </>
  )

  return (
    <div className="flex h-screen overflow-hidden">

      {/* ── Desktop sidebar (hidden on mobile) ── */}
      <nav
        className={cn(
          'hidden md:flex flex-shrink-0 flex-col py-5 px-2 h-full overflow-hidden transition-all duration-200',
          collapsed ? 'w-14' : 'w-56',
          sidebarBg,
        )}
        aria-label="Main navigation"
      >
        {sidebarContent(collapsed)}
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
        <button
          onClick={() => setDrawerOpen(false)}
          className="absolute top-4 right-4 text-gray-400 hover:text-white transition-colors"
          aria-label="Close menu"
        >
          <X className="w-5 h-5" />
        </button>
        {sidebarContent(false)}
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
          <span className="text-sm font-bold text-white">SyncInvoice</span>
        </div>
        {children}
      </main>
    </div>
  )
}
