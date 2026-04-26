import { useState } from 'react'
import { Plus, Warehouse, X, ChevronRight, Zap, Pencil } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { StatusBadge } from '@/components/ui/Badge'
import { AddCompanyModal } from '@/components/admin'
import { useCompanyStore } from '@/store'
import { COMPANY_FEATURES } from '@/types'
import type { Company, CompanyFeature } from '@/types'
import { cn } from '@/lib/utils'

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
  const { updateCompanyFeature, updateCompany } = useCompanyStore()
  const [toggling, setToggling] = useState<string | null>(null)

  const [editName,  setEditName]  = useState(company.name)
  const [editGstin, setEditGstin] = useState(company.gstin ?? '')
  const [editPort,  setEditPort]  = useState(String(company.port ?? 9000))
  const [saving,    setSaving]    = useState(false)

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
                {['Company', 'GSTIN', 'Bills', 'Port', 'Tally Mapping', 'Features', ''].map((h) => (
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
