import { useEffect } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { Upload, Brain, RefreshCw, Building2, Shield, Clock, CheckCircle, Zap, FileText } from 'lucide-react'
import { useAuthStore } from '@/store'

export default function LandingPage() {
  const { isAuthenticated, user } = useAuthStore()
  const navigate = useNavigate()

  useEffect(() => {
    if (isAuthenticated && user) {
      navigate(user.role === 'admin' ? '/admin' : '/company', { replace: true })
    }
  }, [isAuthenticated, user, navigate])

  return (
    <div className="min-h-screen bg-gray-950 text-white">

      {/* ── Sticky header ── */}
      <header className="sticky top-0 z-50 bg-gray-900/95 backdrop-blur border-b border-white/10">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 bg-teal-500 rounded-lg flex items-center justify-center flex-shrink-0">
              <svg className="w-4.5 h-4.5 stroke-white fill-none stroke-2" viewBox="0 0 24 24" width="18" height="18">
                <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </div>
            <span className="text-base font-bold text-white">Tally Bill Sync</span>
          </div>
          <Link
            to="/login"
            className="px-4 py-2 text-sm font-semibold text-teal-400 border border-teal-500/50 rounded-lg hover:bg-teal-500/10 transition-colors"
          >
            Sign In
          </Link>
        </div>
      </header>

      {/* ── Hero ── */}
      <section className="relative bg-gradient-to-b from-gray-950 via-gray-900 to-gray-950 pt-20 pb-28 px-6 text-center overflow-hidden">
        {/* Glow blobs */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[400px] bg-teal-600/10 rounded-full blur-3xl pointer-events-none" />

        <div className="relative max-w-3xl mx-auto">
          <span className="inline-flex items-center gap-2 px-3 py-1 text-xs font-semibold tracking-widest uppercase text-teal-400 bg-teal-400/10 rounded-full border border-teal-400/20 mb-6">
            <Zap className="w-3 h-3" /> AI-powered · GST-ready · Tally-native
          </span>

          <h1 className="text-4xl sm:text-5xl font-extrabold leading-tight text-white mb-5">
            Feed Tally invoices in{' '}
            <span className="text-teal-400">minutes</span>,<br className="hidden sm:block" /> not hours.
          </h1>

          <p className="text-lg text-gray-400 max-w-xl mx-auto mb-8 leading-relaxed">
            Upload any purchase bill — photo or PDF — and our AI extracts every field.
            One click syncs a perfect voucher straight into Tally ERP. No typing. No errors.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
            <Link
              to="/login"
              className="w-full sm:w-auto px-7 py-3 bg-teal-500 hover:bg-teal-400 text-white font-bold rounded-xl transition-colors text-sm shadow-lg shadow-teal-500/25"
            >
              Get Started — It's Free
            </Link>
            <a
              href="#how-it-works"
              className="w-full sm:w-auto px-7 py-3 border border-white/20 hover:bg-white/5 text-gray-300 font-semibold rounded-xl transition-colors text-sm"
            >
              See How It Works
            </a>
          </div>

          {/* Trust badges */}
          <div className="flex flex-wrap items-center justify-center gap-6 mt-12 text-xs text-gray-500">
            {[
              { icon: Brain,        text: 'AI Bill Parsing'   },
              { icon: CheckCircle,  text: 'Tally Ready'       },
              { icon: FileText,     text: 'GST Compliant'     },
            ].map(({ icon: Icon, text }) => (
              <span key={text} className="flex items-center gap-1.5">
                <Icon className="w-3.5 h-3.5 text-teal-500" />
                {text}
              </span>
            ))}
          </div>
        </div>
      </section>

      {/* ── How it works ── */}
      <section id="how-it-works" className="py-20 px-6 bg-gray-900">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-2xl font-bold text-center text-white mb-2">How it works</h2>
          <p className="text-sm text-gray-500 text-center mb-12">Three steps to a fully posted Tally voucher</p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 relative">
            {/* Connector line (desktop) */}
            <div className="hidden md:block absolute top-12 left-[calc(33.33%-16px)] right-[calc(33.33%-16px)] h-px bg-gradient-to-r from-teal-600/50 via-teal-400/50 to-teal-600/50" />

            {[
              {
                step: '01',
                icon: Upload,
                title: 'Upload your bill',
                desc:  'Snap a photo or drag-drop a PDF. We accept any format — printed or handwritten.',
              },
              {
                step: '02',
                icon: Brain,
                title: 'AI extracts data',
                desc:  'Claude Vision reads vendor, GSTIN, HSN codes, line items, GST amounts — everything.',
              },
              {
                step: '03',
                icon: RefreshCw,
                title: 'Sync to Tally',
                desc:  'Map to your ledgers once. A structured purchase voucher is created in Tally instantly.',
              },
            ].map(({ step, icon: Icon, title, desc }) => (
              <div key={step} className="relative flex flex-col items-center text-center p-6 rounded-2xl bg-gray-800/50 border border-white/5">
                <div className="w-12 h-12 bg-teal-500/15 border border-teal-500/30 rounded-2xl flex items-center justify-center mb-4 z-10">
                  <Icon className="w-6 h-6 text-teal-400" />
                </div>
                <span className="text-[10px] font-bold tracking-widest text-teal-500 mb-1">STEP {step}</span>
                <h3 className="font-bold text-white mb-2">{title}</h3>
                <p className="text-sm text-gray-400 leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Features ── */}
      <section className="py-20 px-6 bg-gray-950">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-2xl font-bold text-center text-white mb-2">Everything you need</h2>
          <p className="text-sm text-gray-500 text-center mb-12">Built for Indian GST businesses using Tally ERP</p>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            {[
              {
                icon: Brain,
                title: 'AI Bill Parsing',
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
            ].map(({ icon: Icon, title, desc, color }) => (
              <div key={title} className="p-6 rounded-2xl bg-gray-800/40 border border-white/5 hover:border-white/10 transition-colors">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-4 bg-${color}-500/15`}>
                  <Icon className={`w-5 h-5 text-${color}-400`} />
                </div>
                <h3 className="font-bold text-white mb-2">{title}</h3>
                <p className="text-sm text-gray-400 leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Who is it for ── */}
      <section className="py-20 px-6 bg-gray-900">
        <div className="max-w-4xl mx-auto">
          <h2 className="text-2xl font-bold text-center text-white mb-2">Two portals, one platform</h2>
          <p className="text-sm text-gray-500 text-center mb-12">Sign in once — you'll be routed to the right portal automatically</p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Company */}
            <div className="p-8 rounded-2xl border border-teal-500/30 bg-teal-900/10">
              <div className="w-11 h-11 bg-teal-500/20 rounded-xl flex items-center justify-center mb-5">
                <Building2 className="w-6 h-6 text-teal-400" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">Company Portal</h3>
              <p className="text-sm text-gray-400 mb-5 leading-relaxed">
                For individual businesses. Upload bills, review AI-extracted data, map to Tally ledgers, and sync with one click.
              </p>
              <ul className="space-y-2">
                {[
                  'Upload photos or PDFs',
                  'AI-powered data extraction',
                  'Default + per-bill ledger mapping',
                  'One-click Tally ERP sync',
                  'Full sync log with error retry',
                ].map((f) => (
                  <li key={f} className="flex items-center gap-2 text-sm text-teal-300">
                    <CheckCircle className="w-3.5 h-3.5 flex-shrink-0 text-teal-500" />
                    {f}
                  </li>
                ))}
              </ul>
            </div>

            {/* Admin */}
            <div className="p-8 rounded-2xl border border-blue-500/30 bg-blue-900/10">
              <div className="w-11 h-11 bg-blue-500/20 rounded-xl flex items-center justify-center mb-5">
                <Shield className="w-6 h-6 text-blue-400" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">Admin Portal</h3>
              <p className="text-sm text-gray-400 mb-5 leading-relaxed">
                For business owners managing multiple companies. Monitor sync stats, create accounts, and oversee all activity.
              </p>
              <ul className="space-y-2">
                {[
                  'Aggregate stats across companies',
                  'Create & manage company accounts',
                  'Monitor bills synced / pending / errors',
                  'Analytics dashboard',
                  'Strict data isolation per company',
                ].map((f) => (
                  <li key={f} className="flex items-center gap-2 text-sm text-blue-300">
                    <CheckCircle className="w-3.5 h-3.5 flex-shrink-0 text-blue-500" />
                    {f}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* ── CTA banner ── */}
      <section className="py-20 px-6 bg-gradient-to-r from-teal-900/40 via-gray-900 to-teal-900/40 border-y border-teal-500/20">
        <div className="max-w-xl mx-auto text-center">
          <h2 className="text-2xl font-bold text-white mb-3">Ready to automate?</h2>
          <p className="text-sm text-gray-400 mb-7">
            Join businesses that have eliminated manual invoice entry from their Tally workflow.
          </p>
          <Link
            to="/login"
            className="inline-flex items-center gap-2 px-8 py-3 bg-teal-500 hover:bg-teal-400 text-white font-bold rounded-xl transition-colors text-sm shadow-lg shadow-teal-500/25"
          >
            Sign In to Get Started
          </Link>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="py-8 px-6 bg-gray-950 border-t border-white/5">
        <div className="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-gray-600">
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 bg-teal-500/80 rounded flex items-center justify-center">
              <svg className="stroke-white fill-none stroke-2" viewBox="0 0 24 24" width="10" height="10">
                <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </div>
            <span className="font-medium text-gray-500">Tally Bill Sync</span>
          </div>
          <span>© 2026 Tally Bill Sync. All rights reserved.</span>
        </div>
      </footer>
    </div>
  )
}
