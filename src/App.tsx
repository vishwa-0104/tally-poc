import { Routes, Route, Navigate } from 'react-router-dom'

// Pages
import LandingPage    from '@/pages/LandingPage'
import LoginPage      from '@/pages/LoginPage'
import PrivacyPolicy  from '@/pages/PrivacyPolicy'
import TermsAndConditions from '@/pages/TermsAndConditions'

// Admin layout + pages
import AdminLayout    from '@/pages/admin/AdminLayout'
import AdminDashboard from '@/pages/admin/AdminDashboard'
import AdminCompanies from '@/pages/admin/AdminCompanies'
import AdminUsers     from '@/pages/admin/AdminUsers'
import AdminAnalytics from '@/pages/admin/AdminAnalytics'
import AdminLeads          from '@/pages/admin/AdminLeads'
import AdminUsageDashboard from '@/pages/admin/AdminUsageDashboard'

// Company layout + pages
import CompanyLayout   from '@/pages/company/CompanyLayout'
import CompanyBills    from '@/pages/company/CompanyBills'
import BillMapping     from '@/pages/company/BillMapping'
import CompanySyncLog  from '@/pages/company/CompanySyncLog'
import CompanySettings from '@/pages/company/CompanySettings'
import BankStatement       from '@/pages/company/BankStatement'
import BankMapping         from '@/pages/company/BankMapping'
import BankReconciliation  from '@/pages/company/BankReconciliation'
import ReconciliationDetail from '@/pages/company/ReconciliationDetail'
import CashBook            from '@/pages/company/CashBook'
import CashBookMapping     from '@/pages/company/CashBookMapping'
import VendorReconciliation       from '@/pages/company/VendorReconciliation'
import VendorReconciliationDetail from '@/pages/company/VendorReconciliationDetail'
import Dashboard                  from '@/pages/company/Dashboard'


export default function App() {
  return (
    <Routes>
      {/* ── Public ── */}
      <Route path="/"                element={<LandingPage />} />
      <Route path="/login"           element={<LoginPage />} />
      <Route path="/login/:role"     element={<LoginPage />} />
      <Route path="/privacy-policy"  element={<PrivacyPolicy />} />
      <Route path="/terms-and-conditions"  element={<TermsAndConditions />} />

      {/* ── Admin portal ── */}
      <Route path="/admin" element={<AdminLayout />}>
        <Route index                  element={<AdminDashboard />} />
        <Route path="companies"       element={<AdminCompanies />} />
        <Route path="users"           element={<AdminUsers />} />
        <Route path="analytics"       element={<AdminAnalytics />} />
        <Route path="leads"           element={<AdminLeads />} />
        <Route path="usage"           element={<AdminUsageDashboard />} />
      </Route>

      {/* ── Company portal ── */}
      <Route path="/company" element={<CompanyLayout />}>
        <Route index                  element={<Navigate to="dashboard" replace />} />
        <Route path="bills"           element={<CompanyBills />} />
        <Route path="bills/:billId"   element={<BillMapping />} />
        <Route path="sync-log"        element={<CompanySyncLog />} />
        <Route path="settings"        element={<CompanySettings />} />
        <Route path="bank"            element={<BankStatement />} />
        <Route path="bank/:bankId"    element={<BankMapping />} />
        <Route path="reconcile"            element={<BankReconciliation />} />
        <Route path="reconcile/:reportId" element={<ReconciliationDetail />} />
        <Route path="cash-book"            element={<CashBook />} />
        <Route path="cash-book/:cashId"    element={<CashBookMapping />} />
        <Route path="vendor-reconcile"              element={<VendorReconciliation />} />
        <Route path="vendor-reconcile/:reportId"    element={<VendorReconciliationDetail />} />
        <Route path="dashboard"                     element={<Dashboard />} />
      </Route>

      {/* ── Fallback ── */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
