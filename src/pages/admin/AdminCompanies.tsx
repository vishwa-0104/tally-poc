import { useState, useEffect } from 'react'
import { Plus, Warehouse, X, ChevronRight, Zap, Pencil, CreditCard, Ban } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { StatusBadge } from '@/components/ui/Badge'
import { AddCompanyModal } from '@/components/admin'
import { useCompanyStore } from '@/store'
import { COMPANY_FEATURES } from '@/types'
import type { Company, CompanyFeature } from '@/types'
import { cn } from '@/lib/utils'
import { api } from '@/lib/api'

interface ParseUsageStats {
  total: { requests: number; inputTokens: number; outputTokens: number; cacheRead: number; cacheWrite: number }
  byModel: { model: string; success: boolean; requests: number; inputTokens: number; outputTokens: number }[]
  daily:   { date: string; requests: number; input: number; output: number }[]
}

const MODEL_LABELS: Record<string, string> = {
  'gemini-flash-latest':       'Gemini Flash Latest',
  'gemini-3.1-flash':          'Gemini Flash 3.1',
  'gemini-2.0-flash':          'Gemini Flash 2.0',
  'claude-haiku-4-5-20251001': 'Claude Haiku',
  'claude-sonnet-4-6':         'Claude Sonnet',
  'claude-opus-4-7':           'Claude Opus',
}

const SERVICE_MODELS: Record<string, { value: string; label: string }[]> = {
  gemini: [
    { value: 'gemini-flash-latest', label: 'Flash Latest — always up-to-date (~₹0.01/bill)' },
    { value: 'gemini-3.1-flash',    label: 'Flash 3.1 (~₹0.01/bill)' },
    { value: 'gemini-2.0-flash',    label: 'Flash 2.0 (~₹0.01/bill)' },
  ],
  anthropic: [
    { value: 'claude-haiku-4-5-20251001', label: 'Haiku — fast & cheap (~₹0.40/bill)' },
    { value: 'claude-sonnet-4-6',         label: 'Sonnet — high accuracy (~₹1.50/bill)' },
    { value: 'claude-opus-4-7',           label: 'Opus — best accuracy (~₹6/bill)' },
  ],
}

const SERVICE_DEFAULT_MODEL: Record<string, string> = {
  gemini:    'gemini-flash-latest',
  anthropic: 'claude-haiku-4-5-20251001',
}

function estimateCostInr(inputTokens: number, outputTokens: number, model: string): number {
  const rates: Record<string, [number, number]> = {
    'gemini-flash-latest': [0.075, 0.30],
    'gemini-3.1-flash':    [0.075, 0.30],
    'gemini-2.0-flash':    [0.075, 0.30],
    'claude-haiku-4-5-20251001': [0.80,  4.00],
    'claude-sonnet-4-6':         [3.00, 15.00],
    'claude-opus-4-7':           [15.00, 75.00],
  }
  const [inRate, outRate] = rates[model] ?? [3.00, 15.00]
  const usd = (inputTokens * inRate + outputTokens * outRate) / 1_000_000
  return parseFloat((usd * 84).toFixed(2))
}

const PLANS = [
  { label: 'Starter', bills: 50 },
  { label: 'Basic',   bills: 200 },
  { label: 'Pro',     bills: 500 },
] as const

function defaultExpiry(): string {
  const d = new Date()
  d.setDate(d.getDate() + 30)
  return d.toISOString().split('T')[0]
}

// ── Feature catalogue — add new entries here as features grow ─────────────────

const FEATURE_CATALOGUE = [
  {
    key:         COMPANY_FEATURES.GODOWN,
    label:       'Godown Tracking',
    description: 'Assign a warehouse / godown per bill before syncing to Tally.',
    Icon:        Warehouse,
    gradient:    'from-teal-500/10 to-emerald-500/10',
    ring:        'ring-teal-500/30',
    iconBg:      'bg-teal-500/10',
    iconColor:   'text-teal-400',
    dotOn:       'bg-teal-400',
  },
] as const

// ── Toggle switch ─────────────────────────────────────────────────────────────

function Toggle({ enabled, onChange, loading }: { enabled: boolean; onChange: () => void; loading: boolean }) {
  return (
    <button
      type="button"
      onClick={onChange}
      disabled={loading}
      aria-checked={enabled}
      role="switch"
      className={cn(
        'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-teal-500 focus:ring-offset-2 focus:ring-offset-gray-900',
        enabled ? 'bg-teal-500' : 'bg-gray-600',
        loading && 'opacity-50 cursor-not-allowed',
      )}
    >
      <span
        className={cn(
          'pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out',
          enabled ? 'translate-x-5' : 'translate-x-0',
        )}
      />
    </button>
  )
}

// ── Feature card ──────────────────────────────────────────────────────────────

interface FeatureCardProps {
  def: typeof FEATURE_CATALOGUE[number]
  enabled: boolean
  onToggle: () => void
  loading: boolean
}

function FeatureCard({ def, enabled, onToggle, loading }: FeatureCardProps) {
  const { Icon, label, description, gradient, ring, iconBg, iconColor, dotOn } = def
  return (
    <div className={cn(
      'relative rounded-xl p-4 bg-gradient-to-br ring-1 transition-all duration-300',
      gradient,
      enabled ? ring : 'ring-gray-700/50',
    )}>
      <div className="flex items-start gap-3">
        <div className={cn('w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0', iconBg)}>
          <Icon className={cn('w-4.5 h-4.5', iconColor)} size={18} />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <p className="text-sm font-semibold text-gray-100">{label}</p>
            {enabled && (
              <span className="flex items-center gap-1 text-[10px] font-medium text-teal-400 bg-teal-400/10 px-1.5 py-0.5 rounded-full">
                <span className={cn('w-1.5 h-1.5 rounded-full', dotOn)} />
                Active
              </span>
            )}
          </div>
          <p className="text-xs text-gray-400 leading-relaxed">{description}</p>
        </div>
        <Toggle enabled={enabled} onChange={onToggle} loading={loading} />
      </div>
    </div>
  )
}

// ── Slide-over panel ──────────────────────────────────────────────────────────

interface FeaturePanelProps {
  company: Company
  onClose: () => void
}

function FeaturePanel({ company, onClose }: FeaturePanelProps) {
  const { updateCompanyFeature, updateCompany, updateQuota } = useCompanyStore()
  const [toggling, setToggling] = useState<string | null>(null)

  const [editName,  setEditName]  = useState(company.name)
  const [editGstin, setEditGstin] = useState(company.gstin ?? '')
  const [editPort,  setEditPort]  = useState(String(company.port ?? 9000))
  const [saving,    setSaving]    = useState(false)

  const [planLimit,    setPlanLimit]    = useState(String(company.parseBillsLimit ?? 50))
  const [expiryDate,   setExpiryDate]   = useState(() =>
    company.subscriptionExpiresAt ? new Date(company.subscriptionExpiresAt).toISOString().split('T')[0] : '',
  )
  const [parseService, setParseService] = useState(company.parseService ?? 'gemini')
  const [parseModel,   setParseModel]   = useState(company.parseModel ?? 'gemini-2.0-flash-latest')
  const [savingModel,  setSavingModel]  = useState(false)
  const [renewing,     setRenewing]     = useState(false)
  const [togglingBlk,  setTogglingBlk]  = useState(false)
  const [usage,        setUsage]        = useState<ParseUsageStats | null>(null)

  useEffect(() => {
    api.get(`/companies/${company.id}/parse-usage`)
      .then((r: { data: ParseUsageStats }) => setUsage(r.data))
      .catch(() => {})
  }, [company.id])

  const handleSave = async () => {
    setSaving(true)
    try {
      await updateCompany(company.id, {
        name:  editName.trim() || company.name,
        gstin: editGstin.trim() || null,
        port:  parseInt(editPort, 10) || company.port,
      })
      toast.success('Company updated')
    } catch {
      toast.error('Failed to update company')
    } finally {
      setSaving(false)
    }
  }

  const handleRenew = async () => {
    const limit = parseInt(planLimit, 10)
    if (!limit || limit < 1) { toast.error('Enter a valid bill limit'); return }
    setRenewing(true)
    try {
      await updateQuota(company.id, {
        parseBillsLimit:       limit,
        subscriptionExpiresAt: expiryDate ? new Date(expiryDate).toISOString() : null,
        renew:                 true,
      })
      toast.success('Subscription renewed — counter reset to 0')
    } catch {
      toast.error('Failed to renew subscription')
    } finally {
      setRenewing(false)
    }
  }

  const handleToggleBlock = async () => {
    setTogglingBlk(true)
    try {
      await updateQuota(company.id, { parseBlocked: !company.parseBlocked })
      toast.success(company.parseBlocked ? 'Parsing unblocked' : 'Parsing blocked')
    } catch {
      toast.error('Failed to update block status')
    } finally {
      setTogglingBlk(false)
    }
  }

  const handleServiceChange = (svc: string) => {
    setParseService(svc)
    setParseModel(SERVICE_DEFAULT_MODEL[svc] ?? '')
  }

  const handleSaveModel = async () => {
    setSavingModel(true)
    try {
      await updateQuota(company.id, { parseService, parseModel })
      toast.success('AI service updated')
    } catch {
      toast.error('Failed to update AI service')
    } finally {
      setSavingModel(false)
    }
  }

  const isEnabled = (key: string) =>
    (company.features ?? []).some((f: CompanyFeature) => f.feature === key && f.enabled)

  const handleToggle = async (key: string) => {
    const next = !isEnabled(key)
    setToggling(key)
    try {
      await updateCompanyFeature(company.id, key, next)
      toast.success(`${FEATURE_CATALOGUE.find((f) => f.key === key)?.label ?? key} ${next ? 'enabled' : 'disabled'}`)
    } catch {
      toast.error('Failed to update feature')
    } finally {
      setToggling(null)
    }
  }

  return (
    /* backdrop */
    <div className="fixed inset-0 z-50 flex">
      <div
        className="flex-1 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* panel */}
      <div className="w-[380px] flex flex-col bg-gray-900 shadow-2xl border-l border-gray-700/50 overflow-y-auto">

        {/* header — dark gradient */}
        <div className="relative bg-gradient-to-br from-gray-800 via-gray-900 to-teal-950 px-6 pt-6 pb-8 border-b border-gray-700/50">
          {/* close */}
          <button
            onClick={onClose}
            className="absolute top-4 right-4 w-7 h-7 flex items-center justify-center rounded-full bg-gray-700/60 text-gray-400 hover:text-white hover:bg-gray-600 transition-colors"
          >
            <X size={14} />
          </button>

          {/* company initial avatar */}
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-teal-500 to-emerald-600 flex items-center justify-center mb-4 shadow-lg shadow-teal-900/40">
            <span className="text-white font-bold text-lg">
              {company.name.charAt(0).toUpperCase()}
            </span>
          </div>

          <h2 className="text-base font-bold text-white leading-tight">{company.name}</h2>
          <p className="text-xs text-gray-400 mt-0.5">{company.email}</p>
          {company.gstin && (
            <p className="text-[10px] font-mono text-teal-400/70 mt-1 tracking-wider">{company.gstin}</p>
          )}

          {/* subtle decorative orb */}
          <div className="absolute -bottom-6 -right-6 w-32 h-32 bg-teal-500/5 rounded-full blur-2xl pointer-events-none" />
        </div>

        {/* edit details */}
        <div className="px-5 py-5 border-b border-gray-700/50">
          <div className="flex items-center gap-2 mb-3">
            <Pencil size={13} className="text-gray-400" />
            <p className="text-xs font-bold text-gray-300 uppercase tracking-widest">Edit Details</p>
          </div>
          <div className="space-y-2">
            <div>
              <label className="block text-[10px] text-gray-400 mb-1">Company Name</label>
              <input
                value={editName}
                onChange={(e) => setEditName(e.target.value)}
                className="w-full text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500"
              />
            </div>
            <div>
              <label className="block text-[10px] text-gray-400 mb-1">GSTIN</label>
              <input
                value={editGstin}
                onChange={(e) => setEditGstin(e.target.value)}
                placeholder="—"
                className="w-full text-xs font-mono bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500 placeholder:text-gray-600"
              />
            </div>
            <div>
              <label className="block text-[10px] text-gray-400 mb-1">Tally Port</label>
              <input
                value={editPort}
                onChange={(e) => setEditPort(e.target.value)}
                type="number"
                className="w-full text-xs font-mono bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500"
              />
            </div>
          </div>
          <Button variant="outline" size="sm" loading={saving} onClick={handleSave} className="mt-3 w-full">
            Save Changes
          </Button>
        </div>

        {/* feature flags */}
        <div className="flex-1 px-5 py-5">
          <div className="flex items-center gap-2 mb-4">
            <Zap size={14} className="text-teal-400" />
            <p className="text-xs font-bold text-gray-300 uppercase tracking-widest">Feature Flags</p>
          </div>

          <div className="space-y-3">
            {FEATURE_CATALOGUE.map((def) => (
              <FeatureCard
                key={def.key}
                def={def}
                enabled={isEnabled(def.key)}
                onToggle={() => handleToggle(def.key)}
                loading={toggling === def.key}
              />
            ))}
          </div>

          <p className="text-[10px] text-gray-600 mt-5 text-center">
            More features can be added to the catalogue as needed.
          </p>
        </div>

        {/* Subscription & Quota */}
        <div className="px-5 py-5 border-t border-gray-700/50">
          <div className="flex items-center gap-2 mb-4">
            <CreditCard size={14} className="text-teal-400" />
            <p className="text-xs font-bold text-gray-300 uppercase tracking-widest">Subscription & Quota</p>
          </div>

          {/* Usage bar */}
          {(() => {
            const used  = company.parseBillsUsed  ?? 0
            const limit = company.parseBillsLimit ?? 50
            const pct   = limit > 0 ? Math.min(100, Math.round((used / limit) * 100)) : 0
            const expiresAt = company.subscriptionExpiresAt ? new Date(company.subscriptionExpiresAt) : null
            const renewedAt = company.subscriptionRenewedAt ? new Date(company.subscriptionRenewedAt) : null
            const isExpired = expiresAt && expiresAt < new Date()
            const barColor  = company.parseBlocked || isExpired ? 'bg-red-500' : pct >= 90 ? 'bg-red-500' : pct >= 70 ? 'bg-amber-400' : 'bg-teal-500'
            return (
              <div className="mb-4 space-y-1.5">
                <div className="flex justify-between text-[11px]">
                  <span className="text-gray-400">Bills parsed this period</span>
                  <span className={cn('font-semibold', company.parseBlocked || isExpired ? 'text-red-400' : 'text-gray-200')}>{used} / {limit}</span>
                </div>
                <div className="w-full h-1.5 bg-gray-700 rounded-full overflow-hidden">
                  <div className={cn('h-full rounded-full', barColor)} style={{ width: `${pct}%` }} />
                </div>
                {renewedAt && <p className="text-[10px] text-gray-500">Last renewed: {renewedAt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}</p>}
                {expiresAt && (
                  <p className={cn('text-[10px]', isExpired ? 'text-red-400' : 'text-gray-500')}>
                    {isExpired ? 'Expired: ' : 'Expires: '}
                    {expiresAt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
                  </p>
                )}
              </div>
            )
          })()}

          {/* Plan quick-select */}
          <p className="text-[10px] text-gray-400 mb-1.5">Select plan</p>
          <div className="flex gap-1.5 mb-3">
            {PLANS.map((p) => (
              <button
                key={p.bills}
                onClick={() => { setPlanLimit(String(p.bills)); setExpiryDate(defaultExpiry()) }}
                className={cn(
                  'flex-1 py-1 rounded-lg text-[11px] font-semibold border transition-colors',
                  planLimit === String(p.bills)
                    ? 'bg-teal-500 border-teal-400 text-white'
                    : 'bg-gray-800 border-gray-600 text-gray-300 hover:border-teal-500',
                )}
              >
                {p.label}<br /><span className="text-[10px] font-normal opacity-75">{p.bills} bills</span>
              </button>
            ))}
          </div>

          {/* Custom limit + expiry */}
          <div className="space-y-2 mb-3">
            <div>
              <label className="block text-[10px] text-gray-400 mb-1">Custom limit</label>
              <input
                type="number"
                min={1}
                value={planLimit}
                onChange={(e) => setPlanLimit(e.target.value)}
                className="w-full text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500"
              />
            </div>
            <div>
              <label className="block text-[10px] text-gray-400 mb-1">Subscription expiry</label>
              <input
                type="date"
                value={expiryDate}
                onChange={(e) => setExpiryDate(e.target.value)}
                className="w-full text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500"
              />
            </div>
          </div>

          <Button variant="primary" size="sm" loading={renewing} onClick={handleRenew} className="w-full mb-3">
            Renew Subscription
          </Button>

          {/* AI service + model */}
          <div className="mb-3">
            <label className="block text-[10px] text-gray-400 mb-1">AI Service</label>
            <select
              value={parseService}
              onChange={(e) => handleServiceChange(e.target.value)}
              className="w-full text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500 mb-2"
            >
              <option value="gemini">Google Gemini</option>
              <option value="anthropic">Anthropic Claude</option>
            </select>
            <label className="block text-[10px] text-gray-400 mb-1">AI Model</label>
            <div className="flex gap-2">
              <select
                value={parseModel}
                onChange={(e) => setParseModel(e.target.value)}
                className="flex-1 text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500"
              >
                {(SERVICE_MODELS[parseService] ?? []).map((m) => (
                  <option key={m.value} value={m.value}>{m.label}</option>
                ))}
              </select>
              <Button variant="primary" size="sm" loading={savingModel} onClick={handleSaveModel}>
                Save
              </Button>
            </div>
          </div>

          {/* Parse usage stats */}
          {usage && (
            <div className="mt-4 pt-4 border-t border-gray-700/50">
              <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-3">Parse Usage (All Time)</p>

              {/* Totals row */}
              <div className="grid grid-cols-3 gap-2 mb-3">
                {[
                  { label: 'Requests', value: usage.total.requests.toLocaleString() },
                  { label: 'Input Tokens', value: (usage.total.inputTokens + usage.total.cacheRead).toLocaleString() },
                  { label: 'Output Tokens', value: usage.total.outputTokens.toLocaleString() },
                ].map(({ label, value }) => (
                  <div key={label} className="bg-gray-800 rounded-lg px-2.5 py-2 text-center">
                    <p className="text-[10px] text-gray-400">{label}</p>
                    <p className="text-sm font-bold text-white">{value}</p>
                  </div>
                ))}
              </div>

              {/* By model breakdown */}
              {usage.byModel.length > 0 && (
                <div className="space-y-1.5 mb-3">
                  {Object.entries(
                    usage.byModel.reduce<Record<string, { requests: number; inputTokens: number; outputTokens: number; failed: number }>>((acc, r) => {
                      if (!acc[r.model]) acc[r.model] = { requests: 0, inputTokens: 0, outputTokens: 0, failed: 0 }
                      acc[r.model].requests    += r.requests
                      acc[r.model].inputTokens += r.inputTokens
                      acc[r.model].outputTokens += r.outputTokens
                      if (!r.success) acc[r.model].failed += r.requests
                      return acc
                    }, {})
                  ).map(([model, stats]) => (
                    <div key={model} className="flex items-center justify-between bg-gray-800/60 rounded-lg px-2.5 py-1.5">
                      <div>
                        <span className="text-xs font-medium text-gray-200">{MODEL_LABELS[model] ?? model}</span>
                        {stats.failed > 0 && <span className="ml-1.5 text-[10px] text-red-400">{stats.failed} failed</span>}
                      </div>
                      <div className="text-right">
                        <p className="text-xs text-gray-300">{stats.requests} reqs</p>
                        <p className="text-[10px] text-teal-400 font-medium">
                          ₹{estimateCostInr(stats.inputTokens, stats.outputTokens, model)}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Last 7 days */}
              {usage.daily.length > 0 && (
                <div>
                  <p className="text-[10px] text-gray-500 mb-1.5">Last 30 days activity</p>
                  <div className="flex items-end gap-0.5 h-10">
                    {usage.daily.slice(-30).map((d) => {
                      const max = Math.max(...usage.daily.map((x) => x.requests), 1)
                      const pct = Math.max((d.requests / max) * 100, 8)
                      return (
                        <div key={d.date} className="flex-1 relative group">
                          <div
                            className="bg-teal-500/70 hover:bg-teal-400 rounded-sm transition-colors"
                            style={{ height: `${pct}%` }}
                          />
                          <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block bg-gray-700 text-[10px] text-white px-1.5 py-0.5 rounded whitespace-nowrap z-10">
                            {d.date}: {d.requests} req
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Block toggle */}
          <button
            onClick={handleToggleBlock}
            disabled={togglingBlk}
            className={cn(
              'w-full flex items-center justify-center gap-2 py-1.5 rounded-lg text-xs font-semibold border transition-colors',
              company.parseBlocked
                ? 'bg-gray-700 border-gray-600 text-gray-300 hover:border-teal-500'
                : 'bg-red-900/30 border-red-700/50 text-red-400 hover:bg-red-900/50',
              togglingBlk && 'opacity-50 cursor-not-allowed',
            )}
          >
            <Ban size={12} />
            {company.parseBlocked ? 'Unblock Parsing' : 'Block Parsing'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Main page ─────────────────────────────────────────────────────────────────

export default function AdminCompanies() {
  const [showAdd, setShowAdd]             = useState(false)
  const [selectedCompany, setSelectedCompany] = useState<Company | null>(null)
  const { companies } = useCompanyStore()

  const activeFeatureCount = (c: Company) =>
    (c.features ?? []).filter((f: CompanyFeature) => f.enabled).length

  return (
    <>
      <PageHeader
        title="Companies"
        subtitle="Manage company accounts and feature access"
        actions={
          <Button variant="primary" size="sm" onClick={() => setShowAdd(true)}>
            <Plus className="w-3.5 h-3.5" />
            Add Company
          </Button>
        }
      />

      <div className="p-4 md:p-7">
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
          <table className="w-full border-collapse" aria-label="Companies">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                {['Company', 'GSTIN', 'Bills', 'Quota', 'Port', 'Tally Mapping', 'Features', ''].map((h) => (
                  <th key={h} className="px-4 py-2.5 text-left text-[10px] font-bold text-gray-500 uppercase tracking-widest">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {companies.map((c) => {
                const featureCount = activeFeatureCount(c)
                return (
                  <tr key={c.id} className="border-b border-gray-100 last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm font-semibold text-gray-800">{c.name}</td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">{c.gstin || '—'}</td>
                    <td className="px-4 py-3 text-sm text-gray-700">{c.totalBills}</td>
                    <td className="px-4 py-3">
                      {(() => {
                        const used  = c.parseBillsUsed  ?? 0
                        const limit = c.parseBillsLimit ?? 50
                        const expiresAt = c.subscriptionExpiresAt ? new Date(c.subscriptionExpiresAt) : null
                        const isExpired = expiresAt && expiresAt < new Date()
                        const color = c.parseBlocked || isExpired
                          ? 'text-red-600' : used >= limit ? 'text-amber-600' : 'text-gray-700'
                        return (
                          <div className="flex flex-col gap-0.5">
                            <span className={cn('text-xs font-semibold', color)}>{used} / {limit}</span>
                            {c.parseBlocked && <span className="text-[10px] font-medium text-red-500">Blocked</span>}
                            {!c.parseBlocked && isExpired && <span className="text-[10px] font-medium text-red-500">Expired</span>}
                          </div>
                        )
                      })()}
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">:{c.port}</td>
                    <td className="px-4 py-3">
                      {c.mapping ? <StatusBadge status="synced" /> : <StatusBadge status="pending" />}
                    </td>
                    <td className="px-4 py-3">
                      {featureCount > 0 ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-teal-50 text-teal-700 text-[10px] font-semibold border border-teal-200">
                          <Zap size={10} />
                          {featureCount} active
                        </span>
                      ) : (
                        <span className="text-xs text-gray-400">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => setSelectedCompany(c)}
                        className="flex items-center gap-1 text-xs font-medium text-teal-600 hover:text-teal-800 transition-colors"
                      >
                        Manage <ChevronRight size={12} />
                      </button>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
          </div>
        </div>
      </div>

      <AddCompanyModal open={showAdd} onClose={() => setShowAdd(false)} />

      {selectedCompany && (
        <FeaturePanel
          company={companies.find((c) => c.id === selectedCompany.id) ?? selectedCompany}
          onClose={() => setSelectedCompany(null)}
        />
      )}
    </>
  )
}
