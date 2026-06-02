import { useEffect, useMemo } from 'react'
import { Outlet } from 'react-router-dom'
import { FileText, Settings, Landmark, Scale, BookOpen, Users, TrendingUp } from 'lucide-react'
import { AppLayout, ProtectedRoute } from '@/components/shared'
import type { NavItem } from '@/components/shared/AppLayout'
import { useAuthStore } from '@/store/authStore'
import { useBillStore } from '@/store/billStore'
import { useCompanyStore } from '@/store/companyStore'
import { COMPANY_FEATURES } from '@/types'
import { useAutoSyncTally } from '@/hooks/useAutoSyncTally'

export default function CompanyLayout() {
  const { activeCompanyId } = useAuthStore()
  const { fetchBills } = useBillStore()
  const { fetchCompanies, getCompany } = useCompanyStore()

  const company = getCompany(activeCompanyId ?? '')
  useAutoSyncTally(activeCompanyId ?? '')
  const hasBankVoucher = useMemo(
    () => (company?.features ?? []).some((f) => f.feature === COMPANY_FEATURES.BANK_VOUCHER && f.enabled),
    [company?.features],
  )

  const hasBankReconcile = useMemo(
    () => (company?.features ?? []).some((f) => f.feature === COMPANY_FEATURES.BANK_RECONCILE && f.enabled),
    [company?.features],
  )

  const hasCashBook = useMemo(
    () => (company?.features ?? []).some((f) => f.feature === COMPANY_FEATURES.CASH_BOOK      && f.enabled),
    [company?.features],
  )

  const settingsHidden = useMemo(
    () => (company?.features ?? []).some((f) => f.feature === COMPANY_FEATURES.HIDE_SETTINGS  && f.enabled),
    [company?.features],
  )

  const hasVendorReconcile = useMemo(
    () => (company?.features ?? []).some((f) => f.feature === COMPANY_FEATURES.VENDOR_RECONCILE && f.enabled),
    [company?.features],
  )

  const nav = useMemo<NavItem[]>(() => [
    { label: 'My Bills',    path: '/company',                    icon: FileText },
    ...(hasBankVoucher      ? [{ label: 'My Bank',      path: '/company/bank',              icon: Landmark }] : []),
    ...(hasCashBook         ? [{ label: 'Cash Book',    path: '/company/cash-book',         icon: BookOpen }] : []),
    ...(hasBankReconcile    ? [{ label: 'Reconcile',    path: '/company/reconcile',         icon: Scale    }] : []),
    ...(hasVendorReconcile  ? [{ label: 'Vendor Rec.',  path: '/company/vendor-reconcile',  icon: Users       }] : []),
    { label: 'Dashboard',   path: '/company/dashboard',                                     icon: TrendingUp },
    ...(!settingsHidden     ? [{ label: 'Settings',     path: '/company/settings',          icon: Settings    }] : []),
  ], [hasBankVoucher, hasCashBook, hasBankReconcile, hasVendorReconcile, settingsHidden])

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
