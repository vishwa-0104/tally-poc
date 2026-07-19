import { useEffect, useMemo, useState } from 'react'
import { Outlet } from 'react-router-dom'
import {
  LayoutDashboard, FileText, Landmark,
  ArrowLeftRight, Banknote, Handshake, Settings, Menu,
  ShoppingCart, Receipt, FileMinus, FilePlus, Wallet,
} from 'lucide-react'
import { ProtectedRoute } from '@/components/shared'
import { CompanySidebar, type NavLeaf, type NavGroup } from '@/shadcn/components/company-sidebar'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store/authStore'
import { useBillStore } from '@/store/billStore'
import { useCompanyStore } from '@/store/companyStore'
import { useThemeStore } from '@/store/themeStore'
import { COMPANY_FEATURES } from '@/types'
import { useAutoSyncTally } from '@/hooks/useAutoSyncTally'
import { useDaybookNotifications } from '@/hooks/useDaybookNotifications'

export default function CompanyLayout() {
  const { activeCompanyId } = useAuthStore()
  const { fetchBills } = useBillStore()
  const { fetchCompanies, getCompany } = useCompanyStore()
  const { dark } = useThemeStore()

  const company = getCompany(activeCompanyId ?? '')
  useAutoSyncTally(activeCompanyId ?? '')
  useDaybookNotifications(activeCompanyId ?? '')
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

  const hasDebitVoucher = useMemo(
    () => (company?.features ?? []).some((f) => f.feature === COMPANY_FEATURES.DEBIT_VOUCHER && f.enabled),
    [company?.features],
  )

  const hasCreditVoucher = useMemo(
    () => (company?.features ?? []).some((f) => f.feature === COMPANY_FEATURES.CREDIT_VOUCHER && f.enabled),
    [company?.features],
  )

  const topItems = useMemo<NavLeaf[]>(() => [
    { label: 'Dashboard', path: '/company/dashboard', icon: LayoutDashboard },
  ], [])

  const groups = useMemo<NavGroup[]>(() => [
    {
      label: 'Vouchers',
      icon: FileText,
      items: [
        { label: 'Purchase', path: '/company/bills', icon: ShoppingCart },
        { label: 'Expenses', path: '/company/bills?type=misc', icon: Receipt },
        ...(hasDebitVoucher  ? [{ label: 'Debit Note',  path: '/company/bills?type=debit',  icon: FileMinus }] : []),
        ...(hasCreditVoucher ? [{ label: 'Credit Note', path: '/company/bills?type=credit', icon: FilePlus  }] : []),
        ...(hasCashBook      ? [{ label: 'Cash', path: '/company/cash-book', icon: Wallet }] : []),
        ...(hasBankVoucher   ? [{ label: 'Bank', path: '/company/bank', icon: Landmark }] : []),
      ],
    },
    {
      label: 'Reconciliation',
      icon: ArrowLeftRight,
      items: [
        ...(hasBankReconcile   ? [{ label: 'Bank Reconciliation', path: '/company/reconcile', icon: Banknote }] : []),
        ...(hasVendorReconcile ? [{ label: 'Vendor Reconciliation', path: '/company/vendor-reconcile', icon: Handshake }] : []),
      ],
    },
  ], [hasBankVoucher, hasCashBook, hasBankReconcile, hasVendorReconcile, hasDebitVoucher, hasCreditVoucher])

  const bottomItems = useMemo<NavLeaf[]>(() => (
    !settingsHidden ? [{ label: 'Settings', path: '/company/settings', icon: Settings }] : []
  ), [settingsHidden])

  const [collapsed, setCollapsed] = useState(true)
  const [isOverlay, setIsOverlay] = useState(false)

  useEffect(() => {
    const check = () => setIsOverlay(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  useEffect(() => {
    if (activeCompanyId) {
      fetchBills(activeCompanyId)
      fetchCompanies()
    }
  }, [activeCompanyId]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark)
  }, [dark])

  return (
    <ProtectedRoute allowedRole="company">
      <div className="h-screen overflow-hidden">
        <CompanySidebar
          topItems={topItems}
          groups={groups}
          bottomItems={bottomItems}
          collapsed={collapsed}
          onToggle={setCollapsed}
          isOverlay={isOverlay}
          onClose={() => setCollapsed(true)}
        />
        {isOverlay && !collapsed && (
          <div
            className="fixed inset-0 z-30 bg-black/30 backdrop-blur-sm"
            onClick={() => setCollapsed(true)}
          />
        )}
        <div
          className={cn(
            'h-screen overflow-y-auto bg-background transition-all duration-300',
            isOverlay ? '' : collapsed ? 'md:ml-16' : 'md:ml-60',
          )}
        >
          {isOverlay && collapsed && (
            <button
              type="button"
              aria-label="Open menu"
              onClick={() => setCollapsed(false)}
              className="sticky top-3 left-3 z-20 flex size-9 items-center justify-center rounded-full border border-border bg-background shadow-sm"
            >
              <Menu className="size-4" />
            </button>
          )}
          <Outlet />
        </div>
      </div>
    </ProtectedRoute>
  )
}
