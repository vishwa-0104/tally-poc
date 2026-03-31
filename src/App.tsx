import { Routes, Route, Navigate } from 'react-router-dom'

// Pages
import LandingPage  from '@/pages/LandingPage'
import LoginPage    from '@/pages/LoginPage'

// Admin layout + pages
import AdminLayout    from '@/pages/admin/AdminLayout'
import AdminDashboard from '@/pages/admin/AdminDashboard'
import AdminCompanies from '@/pages/admin/AdminCompanies'
import AdminAnalytics from '@/pages/admin/AdminAnalytics'

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
      <Route path="/"             element={<LandingPage />} />
      <Route path="/login/:role"  element={<LoginPage />} />

      {/* ── Admin portal ── */}
      <Route path="/admin" element={<AdminLayout />}>
        <Route index                  element={<AdminDashboard />} />
        <Route path="companies"       element={<AdminCompanies />} />
        <Route path="analytics"       element={<AdminAnalytics />} />
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
