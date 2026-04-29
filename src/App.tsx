import { Routes, Route, Navigate } from 'react-router-dom'

// Pages
import LandingPage    from '@/pages/LandingPage'
import LoginPage      from '@/pages/LoginPage'
import PrivacyPolicy  from '@/pages/PrivacyPolicy'

// Admin layout + pages
import AdminLayout    from '@/pages/admin/AdminLayout'
import AdminDashboard from '@/pages/admin/AdminDashboard'
import AdminCompanies from '@/pages/admin/AdminCompanies'
import AdminUsers     from '@/pages/admin/AdminUsers'
import AdminAnalytics from '@/pages/admin/AdminAnalytics'
import AdminLeads     from '@/pages/admin/AdminLeads'

// Company layout + pages
import CompanyLayout   from '@/pages/company/CompanyLayout'
import CompanyBills    from '@/pages/company/CompanyBills'
import BillMapping     from '@/pages/company/BillMapping'
import CompanySyncLog  from '@/pages/company/CompanySyncLog'
import CompanySettings from '@/pages/company/CompanySettings'

export default function App() {
  return (
    <Routes>
      {/* ── Public ── */}
      <Route path="/"                element={<LandingPage />} />
      <Route path="/login"           element={<LoginPage />} />
      <Route path="/login/:role"     element={<LoginPage />} />
      <Route path="/privacy-policy"  element={<PrivacyPolicy />} />

      {/* ── Admin portal ── */}
      <Route path="/admin" element={<AdminLayout />}>
        <Route index                  element={<AdminDashboard />} />
        <Route path="companies"       element={<AdminCompanies />} />
        <Route path="users"           element={<AdminUsers />} />
        <Route path="analytics"       element={<AdminAnalytics />} />
        <Route path="leads"           element={<AdminLeads />} />
      </Route>

      {/* ── Company portal ── */}
      <Route path="/company" element={<CompanyLayout />}>
        <Route index                  element={<CompanyBills />} />
        <Route path="bills/:billId"   element={<BillMapping />} />
        <Route path="sync-log"        element={<CompanySyncLog />} />
        <Route path="settings"        element={<CompanySettings />} />
      </Route>

      {/* ── Fallback ── */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
