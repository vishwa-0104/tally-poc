import { useEffect } from 'react'
import { Outlet } from 'react-router-dom'
import { FileText, RefreshCw, Settings } from 'lucide-react'
import { AppLayout, ProtectedRoute } from '@/components/shared'
import type { NavItem } from '@/components/shared/AppLayout'
import { useAuthStore } from '@/store/authStore'
import { useBillStore } from '@/store/billStore'
import { useCompanyStore } from '@/store/companyStore'

const NAV: NavItem[] = [
  { label: 'My Bills',  path: '/company',          icon: FileText  },
  { label: 'Sync Log',  path: '/company/sync-log',  icon: RefreshCw },
  { label: 'Settings',  path: '/company/settings',  icon: Settings  },
]

export default function CompanyLayout() {
  const { activeCompanyId } = useAuthStore()
  const { fetchBills } = useBillStore()
  const { fetchCompanies } = useCompanyStore()

  useEffect(() => {
    if (activeCompanyId) {
      fetchBills(activeCompanyId)
      fetchCompanies()
    }
  }, [activeCompanyId]) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <ProtectedRoute allowedRole="company">
      <AppLayout navItems={NAV} role="company">
        <Outlet />
      </AppLayout>
    </ProtectedRoute>
  )
}
