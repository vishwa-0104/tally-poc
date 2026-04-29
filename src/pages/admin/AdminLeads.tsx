import { useState, useEffect, useMemo } from 'react'
import { X, ClipboardList, ChevronLeft, ChevronRight } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { api } from '@/lib/api'
import { formatDate } from '@/lib/utils'
import { cn } from '@/lib/utils'
import type { Lead, LeadStatus } from '@/types'

const STATUS_LABELS: Record<LeadStatus, string> = {
  new_lead:      'New Lead',
  onboarded:     'Onboarded',
  not_onboarded: 'Not Onboarded',
  rejected:      'Rejected',
}

const STATUS_COLORS: Record<LeadStatus, string> = {
  new_lead:      'bg-blue-100 text-blue-700',
  onboarded:     'bg-green-100 text-green-700',
  not_onboarded: 'bg-orange-100 text-orange-700',
  rejected:      'bg-red-100 text-red-700',
}

const STATUS_OPTIONS: { value: string; label: string }[] = [
  { value: 'NEW_LEAD',      label: 'New Lead' },
  { value: 'ONBOARDED',     label: 'Onboarded' },
  { value: 'NOT_ONBOARDED', label: 'Not Onboarded' },
  { value: 'REJECTED',      label: 'Rejected' },
]

function statusToApi(s: LeadStatus): string {
  return s.toUpperCase()
}

interface ManagePanelProps {
  lead: Lead
  onClose: () => void
  onSaved: (updated: Lead) => void
}

function ManagePanel({ lead, onClose, onSaved }: ManagePanelProps) {
  const [status,  setStatus]  = useState(statusToApi(lead.status))
  const [remarks, setRemarks] = useState(lead.remarks ?? '')
  const [saving,  setSaving]  = useState(false)

  const handleSave = async () => {
    setSaving(true)
    try {
      const { data } = await api.patch<Lead>(`/leads/${lead.id}`, { status, remarks })
      onSaved(data)
      toast.success('Lead updated')
    } catch {
      toast.error('Failed to update lead')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex">
      <div className="flex-1 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="w-full max-w-sm bg-gray-900 h-full overflow-y-auto shadow-2xl flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-700/60">
          <p className="font-semibold text-gray-100 text-sm">Manage Lead</p>
          <button onClick={onClose} className="w-7 h-7 rounded-lg bg-gray-800 hover:bg-gray-700 flex items-center justify-center transition-colors">
            <X className="w-3.5 h-3.5 text-gray-400" />
          </button>
        </div>

        <div className="flex-1 p-5 space-y-5">
          {/* Details */}
          <div className="space-y-2">
            <p className="text-[10px] font-semibold text-gray-400 uppercase tracking-wider">Details</p>
            <div className="bg-gray-800 rounded-xl p-4 space-y-2.5">
              {[
                { label: 'Company',     value: lead.companyName },
                { label: 'Email',       value: lead.email },
                { label: 'Phone',       value: lead.phone },
                { label: 'Submitted',   value: formatDate(lead.createdAt) },
              ].map(({ label, value }) => (
                <div key={label}>
                  <p className="text-[10px] text-gray-500">{label}</p>
                  <p className="text-xs text-gray-200 mt-0.5">{value}</p>
                </div>
              ))}
              {lead.description && (
                <div>
                  <p className="text-[10px] text-gray-500">Description</p>
                  <p className="text-xs text-gray-200 mt-0.5 leading-relaxed">{lead.description}</p>
                </div>
              )}
            </div>
          </div>

          {/* Status */}
          <div>
            <label className="block text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-1.5">Status</label>
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value)}
              className="w-full text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500"
            >
              {STATUS_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </select>
          </div>

          {/* Remarks */}
          <div>
            <label className="block text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-1.5">Remarks</label>
            <textarea
              value={remarks}
              onChange={(e) => setRemarks(e.target.value)}
              rows={4}
              placeholder="Add notes about this lead..."
              className="w-full text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-2 resize-none focus:outline-none focus:border-teal-500 placeholder:text-gray-600"
            />
          </div>
        </div>

        <div className="px-5 pb-5">
          <Button variant="primary" size="sm" loading={saving} onClick={handleSave} className="w-full">
            Save Changes
          </Button>
        </div>
      </div>
    </div>
  )
}

const PAGE_SIZE = 10

export default function AdminLeads() {
  const [leads,      setLeads]      = useState<Lead[]>([])
  const [loading,    setLoading]    = useState(true)
  const [activeLead, setActiveLead] = useState<Lead | null>(null)
  const [page,       setPage]       = useState(1)

  useEffect(() => {
    api.get<Lead[]>('/leads')
      .then((r) => setLeads(r.data))
      .catch(() => toast.error('Failed to load leads'))
      .finally(() => setLoading(false))
  }, [])

  const sorted = useMemo(
    () => [...leads].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()),
    [leads],
  )

  const totalPages  = Math.max(1, Math.ceil(sorted.length / PAGE_SIZE))
  const paginated   = sorted.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)
  const rangeStart  = sorted.length === 0 ? 0 : (page - 1) * PAGE_SIZE + 1
  const rangeEnd    = Math.min(page * PAGE_SIZE, sorted.length)

  const handleSaved = (updated: Lead) => {
    setLeads((prev) => prev.map((l) => l.id === updated.id ? updated : l))
    setActiveLead(updated)
  }

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <PageHeader
        title="Leads"
        subtitle={`${leads.length} enquier${leads.length === 1 ? 'y' : 'ies'} received`}
      />

      {loading ? (
        <div className="flex items-center justify-center h-48 text-gray-400 text-sm">Loading...</div>
      ) : leads.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-48 gap-2 text-gray-500">
          <ClipboardList className="w-8 h-8 opacity-30" />
          <p className="text-sm">No leads yet — they'll appear here once someone submits the form.</p>
        </div>
      ) : (
        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Company', 'Email', 'Phone', 'Status', 'Submitted', ''].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {paginated.map((lead) => (
                <tr key={lead.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3">
                    <p className="font-medium text-gray-900">{lead.companyName}</p>
                    {lead.remarks && <p className="text-xs text-gray-400 mt-0.5 truncate max-w-[200px]">{lead.remarks}</p>}
                  </td>
                  <td className="px-4 py-3 text-gray-600">{lead.email}</td>
                  <td className="px-4 py-3 text-gray-600">{lead.phone}</td>
                  <td className="px-4 py-3">
                    <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium', STATUS_COLORS[lead.status])}>
                      {STATUS_LABELS[lead.status]}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500 text-xs">{formatDate(lead.createdAt)}</td>
                  <td className="px-4 py-3">
                    <Button variant="outline" size="sm" onClick={() => setActiveLead(lead)}>Manage</Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-gray-50">
            <p className="text-xs text-gray-500">
              {sorted.length === 0 ? 'No results' : `Showing ${rangeStart}–${rangeEnd} of ${sorted.length}`}
            </p>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="w-7 h-7 flex items-center justify-center rounded-md border border-gray-200 bg-white text-gray-500 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                <button
                  key={p}
                  onClick={() => setPage(p)}
                  className={cn(
                    'w-7 h-7 flex items-center justify-center rounded-md text-xs font-medium transition-colors',
                    p === page
                      ? 'bg-teal-500 text-white border border-teal-500'
                      : 'border border-gray-200 bg-white text-gray-600 hover:bg-gray-50',
                  )}
                >
                  {p}
                </button>
              ))}
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="w-7 h-7 flex items-center justify-center rounded-md border border-gray-200 bg-white text-gray-500 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {activeLead && (
        <ManagePanel
          lead={activeLead}
          onClose={() => setActiveLead(null)}
          onSaved={handleSaved}
        />
      )}
    </div>
  )
}
