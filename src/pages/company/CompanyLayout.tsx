import { useEffect, useMemo } from 'react'
import { Outlet } from 'react-router-dom'
import { FileText, Settings, Landmark } from 'lucide-react'
import { AppLayout, ProtectedRoute } from '@/components/shared'
import type { NavItem } from '@/components/shared/AppLayout'
import { useAuthStore } from '@/store/authStore'
import { useBillStore } from '@/store/billStore'
import { useCompanyStore } from '@/store/companyStore'
import { COMPANY_FEATURES } from '@/types'

export default function CompanyLayout() {
  const { activeCompanyId } = useAuthStore()
  const { fetchBills } = useBillStore()
  const { fetchCompanies, getCompany } = useCompanyStore()

  const company = getCompany(activeCompanyId ?? '')
  const hasBankVoucher = useMemo(
    () => (company?.features ?? []).some((f) => f.feature === COMPANY_FEATURES.BANK_VOUCHER && f.enabled),
    [company?.features],
  )

  const nav = useMemo<NavItem[]>(() => [
    { label: 'My Bills', path: '/company',         icon: FileText },
    ...(hasBankVoucher ? [{ label: 'My Bank', path: '/company/bank', icon: Landmark }] : []),
    { label: 'Settings', path: '/company/settings', icon: Settings },
  ], [hasBankVoucher])

  useEffect(() => {
    if (activeCompanyId) {
      fetchBills(activeCompanyId)
      fetchCompanies()
    }
  }, [activeCompanyId]) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <ProtectedRoute allowedRole="company">
      <AppLayout navItems={nav} role="company">
        <Outlet />
      </AppLayout>
    </ProtectedRoute>
  )
}
