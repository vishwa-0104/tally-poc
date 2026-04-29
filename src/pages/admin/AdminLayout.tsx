import { useEffect } from 'react'
import { Outlet } from 'react-router-dom'
import { LayoutDashboard, Building2, BarChart2, Users, ClipboardList } from 'lucide-react'
import { AppLayout, ProtectedRoute } from '@/components/shared'
import type { NavItem } from '@/components/shared/AppLayout'
import { useCompanyStore } from '@/store/companyStore'

const NAV: NavItem[] = [
  { label: 'Dashboard',  path: '/admin',           icon: LayoutDashboard },
  { label: 'Companies',  path: '/admin/companies',  icon: Building2 },
  { label: 'Users',      path: '/admin/users',      icon: Users },
  { label: 'Analytics',  path: '/admin/analytics',  icon: BarChart2 },
  { label: 'Leads',      path: '/admin/leads',       icon: ClipboardList },
]

export default function AdminLayout() {
  const { fetchCompanies } = useCompanyStore()

  useEffect(() => { fetchCompanies() }, [])

  return (
    <ProtectedRoute allowedRole="admin">
      <AppLayout navItems={NAV} role="admin">
        <Outlet />
      </AppLayout>
    </ProtectedRoute>
  )
}
