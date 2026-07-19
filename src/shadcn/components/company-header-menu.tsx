import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Moon, Sun, MoreVertical, LogOut } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store/authStore'
import { useThemeStore } from '@/store/themeStore'

export function CompanyHeaderMenu() {
  const { dark, toggle } = useThemeStore()
  const { user, companies, activeCompanyId, switchCompany, logout } = useAuthStore()
  const navigate = useNavigate()
  const [menuOpen, setMenuOpen] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!menuOpen) return
    const handler = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) setMenuOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [menuOpen])

  const activeCompany = companies.find((c) => c.id === activeCompanyId)
  const initial = activeCompany?.name?.charAt(0).toUpperCase() ?? user?.name?.charAt(0).toUpperCase() ?? '?'

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  return (
    <div className="flex items-center gap-1">
      <button
        type="button"
        onClick={toggle}
        title={dark ? 'Switch to light mode' : 'Switch to dark mode'}
        className="flex size-8 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      >
        {dark ? <Sun className="size-4" /> : <Moon className="size-4" />}
      </button>

      <div
        className="flex size-8 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary"
        title={activeCompany?.name ?? user?.name}
      >
        {initial}
      </div>

      <div className="relative" ref={menuRef}>
        <button
          type="button"
          onClick={() => setMenuOpen((o) => !o)}
          title="More"
          className="flex size-8 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
        >
          <MoreVertical className="size-4" />
        </button>

        {menuOpen && (
          <div className="absolute right-0 z-50 mt-1 w-48 origin-top-right rounded-2xl border border-border bg-card p-2 text-card-foreground shadow-lg">
            {companies.length > 0 && (
              <>
                <div className="px-2 py-1.5 text-xs font-medium text-muted-foreground">Switch Company</div>
                <div className="max-h-48 overflow-y-auto">
                  {companies.map((c) => (
                    <button
                      key={c.id}
                      type="button"
                      onClick={() => { setMenuOpen(false); if (c.id !== activeCompanyId) switchCompany(c.id) }}
                      className={cn(
                        'flex w-full items-center rounded-xl px-2 py-1.5 text-left text-sm transition-colors hover:bg-muted',
                        c.id === activeCompanyId && 'bg-primary/10 font-medium',
                      )}
                    >
                      {c.name}
                    </button>
                  ))}
                </div>
                <div className="my-1 h-px bg-border" />
              </>
            )}
            <button
              type="button"
              onClick={handleLogout}
              className="flex w-full items-center gap-2 rounded-xl px-2 py-1.5 text-left text-sm text-red-500 transition-colors hover:bg-red-50 dark:hover:bg-red-950/20"
            >
              <LogOut className="size-4" />
              Sign out
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
