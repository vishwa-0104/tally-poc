import { useNavigate } from 'react-router-dom'
import { Shield, Building2, ChevronRight } from 'lucide-react'
import { useAuthStore } from '@/store'
import { useEffect } from 'react'

export default function LandingPage() {
  const { isAuthenticated, user } = useAuthStore()
  const navigate = useNavigate()

  useEffect(() => {
    if (isAuthenticated && user) {
      navigate(user.role === 'admin' ? '/admin' : '/company', { replace: true })
    }
  }, [isAuthenticated, user, navigate])

  return (
    <div className="min-h-screen bg-gray-900 flex items-center justify-center p-5">
      <div className="w-full max-w-3xl">
        {/* Logo */}
        <div className="flex items-center justify-center gap-3 mb-12">
          <div className="w-11 h-11 bg-brand-500 rounded-xl flex items-center justify-center">
            <svg className="w-6 h-6 stroke-white fill-none stroke-2" viewBox="0 0 24 24">
              <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
          </div>
          <span className="text-2xl font-bold text-white">Tally Bill Sync</span>
        </div>

        {/* Portal cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <PortalCard
            theme="admin"
            icon={Shield}
            title="Admin Portal"
            description="Business owner oversight — monitor all companies at a glance."
            features={[
              'Aggregate stats across all companies',
              'Add & manage company accounts',
              'Monitor sync status at a glance',
              'No access to individual bill details',
            ]}
            cta="Enter as Admin"
            onClick={() => navigate('/login/admin')}
          />
          <PortalCard
            theme="company"
            icon={Building2}
            title="Company Portal"
            description="For individual businesses — upload, parse, and sync bills to Tally."
            features={[
              'Your bills only — fully private',
              'Upload images or PDFs',
              'AI parsing with Claude Vision',
              'One-click sync to Tally ERP',
            ]}
            cta="Enter as Company"
            onClick={() => navigate('/login/company')}
          />
        </div>
      </div>
    </div>
  )
}

interface PortalCardProps {
  theme: 'admin' | 'company'
  icon: typeof Shield
  title: string
  description: string
  features: string[]
  cta: string
  onClick: () => void
}

function PortalCard({ theme, icon: Icon, title, description, features, cta, onClick }: PortalCardProps) {
  const isAdmin = theme === 'admin'

  return (
    <button
      onClick={onClick}
      className={`text-left rounded-2xl p-8 border-2 transition-all duration-200 group focus:outline-none focus-visible:ring-2 focus-visible:ring-white/40 ${
        isAdmin
          ? 'bg-brand-700 border-brand-500 hover:bg-brand-600 hover:border-blue-400'
          : 'bg-teal-700 border-teal-500 hover:bg-teal-600 hover:border-teal-400'
      }`}
    >
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center mb-5 ${isAdmin ? 'bg-blue-900/50' : 'bg-teal-900/50'}`}>
        <Icon className={`w-6 h-6 ${isAdmin ? 'text-blue-300' : 'text-teal-300'}`} />
      </div>

      <h2 className="text-lg font-bold text-white mb-2">{title}</h2>
      <p className={`text-sm mb-5 leading-relaxed ${isAdmin ? 'text-blue-200' : 'text-teal-200'}`}>{description}</p>

      <ul className="space-y-2 mb-6">
        {features.map((f) => (
          <li key={f} className={`text-xs flex items-center gap-2 ${isAdmin ? 'text-blue-200' : 'text-teal-200'}`}>
            <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${isAdmin ? 'bg-blue-400' : 'bg-teal-400'}`} />
            {f}
          </li>
        ))}
      </ul>

      <div className={`flex items-center gap-2 text-sm font-semibold ${isAdmin ? 'text-white' : 'text-white'}`}>
        {cta}
        <ChevronRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
      </div>
    </button>
  )
}
