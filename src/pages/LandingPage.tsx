import { useEffect, useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { Upload, Brain, RefreshCw, Building2, Clock } from 'lucide-react'
import { useAuthStore } from '@/store'
import { LeadFormModal } from '@/components/LeadFormModal'
import invoiceSyncSvg from '../assets/invoice-sync-logo-blue.svg'

export default function LandingPage() {
  const { isAuthenticated, user } = useAuthStore()
  const navigate = useNavigate()
  const [showLeadModal, setShowLeadModal] = useState(false)

  useEffect(() => {
    if (isAuthenticated && user) {
      navigate(user.role === 'admin' ? '/admin' : '/company', { replace: true })
    }
  }, [isAuthenticated, user, navigate])

  return (
    <>
    <div className="min-h-screen bg-gray-950 text-white">

      {/* ── Sticky header ── */}
      <header className="sticky top-0 z-50 bg-gray-100 backdrop-blur border-b border-white/10">
        <div className="max-w-6xl mx-auto px-6 h-[80px] flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-32 h-8  rounded-lg flex items-center justify-center flex-shrink-0">
              
              <img className='w-2xl h-4.5 stroke-white fill-none stroke-2' src={invoiceSyncSvg} alt="Tally Bill Sync" />
              {/* <svg className="w-4.5 h-4.5 stroke-white fill-none stroke-2" viewBox="0 0 24 24" width="18" height="18">
                <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg> */}
            </div>
            {/* <span className="text-base font-bold text-white">Tally Bill Sync</span> */}
          </div>
          <Link
            to="/login"
            className="px-4 py-2 text-sm font-semibold text-blue-600 border border-blue-300 rounded-lg hover:bg-blue-100 transition-colors"
          >
            Sign In
          </Link>
        </div>
      </header>

      {/* ── Hero ── */}
      <section className="relative bg-gradient-to-b from-gray-100 via-gray-600 to-gray-950 pt-20 pb-28 px-6 text-center overflow-hidden">
        {/* Glow blobs */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[400px] bg-blue-600/10 rounded-full blur-3xl pointer-events-none" />

        <div className="relative max-w-3xl mx-auto">
          {/* <span className="inline-flex items-center gap-2 px-3 py-1 text-xs font-semibold tracking-widest uppercase text-blue-400 bg-blue-400/10 rounded-full border border-blue-400/20 mb-6">
            <Zap className="w-3 h-3" /> AI-powered · GST-ready · Tally-native
          </span> */}

          <h1 className="text-4xl sm:text-5xl font-extrabold leading-tight text-white mb-5">
            Feed invoices in{' '}
            <span className="text-blue-500">minutes</span>,<br className="hidden sm:block" /> not hours.
          </h1>

          <p className="text-lg text-gray-400 max-w-xl mx-auto mb-8 leading-relaxed">
            Upload any purchase bill — photo or PDF — and our tool extracts every field.
            Sync your invoices with single click and your invoices straight into your Accounting Software. 
            <p>No typing. No errors.</p>
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
            <button
              onClick={() => setShowLeadModal(true)}
              className="w-full sm:w-auto px-7 py-3 bg-teal-500 hover:bg-teal-400 text-white font-bold rounded-xl transition-colors text-sm shadow-lg shadow-teal-500/25"
            >
              Get Started — It's Free
            </button>
          </div>

         
        </div>
      </section>

      {/* ── How it works ── */}
      <section id="how-it-works" className="py-20 px-6 bg-gray-200">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-3xl font-bold text-center text-gray-600 mb-2">How it works</h2>
          <p className="text-xl text-gray-500 text-center mb-12">Three steps to post your voucher into a ERP</p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 relative">
            {/* Connector line (desktop) */}
            <div className="hidden md:block absolute top-12 left-[calc(33.33%-16px)] right-[calc(33.33%-16px)] h-px bg-gradient-to-r from-blue-600/50 via-blue-400/50 to-blue-600/50" />

            {[
              {
                step: '01',
                icon: Upload,
                title: 'Upload your bill',
                desc:  'Snap a photo or drag-drop a PDF.',
              },
              {
                step: '02',
                icon: Brain,
                title: 'Our tool extracts the data',
                desc:  'Our website reads everything in the invoices.',
              },
              {
                step: '03',
                icon: RefreshCw,
                title: 'Sync to your ERP',
                desc:  'Map to your ledgers once. A structured purchase voucher is created in instantly.',
              },
            ].map(({ step, icon: Icon, title, desc }) => (
              <div key={step} className="relative flex flex-col items-center text-center p-6 rounded-2xl bg-blue-400 border border-white">
                <div className="w-12 h-12 bg-teal-500/15 border-2 border-white rounded-2xl flex items-center justify-center mb-4 z-10">
                  <Icon className="w-6 h-6 text-white" />
                </div>
                <span className="text-[16px] font-bold tracking-widest text-white mb-1">STEP {step}</span>
                <h3 className="font-bold text-white mb-2">{title}</h3>
                <p className="text-sm text-white leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Features ── */}
      <section className="py-20 px-6 bg-gray-00">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-2xl font-bold text-center text-white mb-8">Everything you need</h2>
          {/* <p className="text-sm text-gray-500 text-center mb-12">Built for Indian GST businesses using Tally ERP</p> */}

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {[
              {
                icon: Brain,
                title: 'Bill Parsing',
                desc:  'Powered by Claude Vision. Reads CGST, SGST, IGST, HSN codes, and round-off amounts from any bill format.',
                color: 'teal',
              },
              {
                icon: RefreshCw,
                title: 'Auto Ledger Mapping',
                desc:  'Save default purchase, CGST, SGST, and IGST ledgers. Pre-fills on every bill — change per bill if needed.',
                color: 'blue',
              },
              {
                icon: Building2,
                title: 'Multi-Company',
                desc:  'Each company sees only their own bills. Admin controls all accounts from a single dashboard.',
                color: 'violet',
              },
              {
                icon: Clock,
                title: 'Save Hours Daily',
                desc:  'What took 10 minutes per bill now takes 30 seconds. Handle 100+ bills a month with ease.',
                color: 'amber',
              },
            ].map(({ icon: Icon, title, color }) => (
              <div key={title} className="p-6 rounded-2xl bg-gray-800/40 border border-white/5 hover:border-white/10 transition-colors">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-4 bg-${color}-500/15`}>
                  <Icon className={`w-5 h-5 text-${color}-400`} />
                </div>
                <h3 className="font-bold text-white mb-8">{title}</h3>
                {/* <p className="text-sm text-gray-400 leading-relaxed">{desc}</p> */}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Who is it for ── */}
     

      {/* ── Footer ── */}
      <footer className="py-8 px-6 bg-gray-950 border-t border-white/5">
        <div className="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-gray-400">
          <div className="flex items-center gap-2">
            <span>© 2026 Invoice Sync. All rights reserved.</span>
          </div>
          <Link to="/privacy-policy" className="text-teal-400 hover:text-teal-300 underline underline-offset-2 transition-colors">Privacy Policy</Link>
        </div>
      </footer>
    </div>

    <LeadFormModal open={showLeadModal} onClose={() => setShowLeadModal(false)} />
    </>
  )
}
