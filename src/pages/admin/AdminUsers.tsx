import { useState, useEffect, useCallback } from 'react'
import { Plus, X, ChevronRight, Star, KeyRound } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { AddUserModal } from '@/components/admin/AddUserModal'
import { useCompanyStore } from '@/store'
import { api } from '@/lib/api'
import { cn } from '@/lib/utils'

// Matches backend GET /users response shape
interface EnterpriseUser {
  id: string
  name: string
  email: string
  enterpriseName?: string
  companies: { id: string; name: string; isDefault: boolean }[]
}

// ── User manage panel ─────────────────────────────────────────────────────────

interface UserPanelProps {
  user: EnterpriseUser
  onClose: () => void
  onChanged: () => void
}

function UserPanel({ user, onClose, onChanged }: UserPanelProps) {
  const { companies: allCompanies } = useCompanyStore()
  const [linked, setLinked]            = useState(user.companies)
  const [selectedCompany, setSelected] = useState('')
  const [linking, setLinking]          = useState(false)
  const [newPassword, setNewPassword]  = useState('')
  const [resetting, setResetting]      = useState(false)

  const unlinked = allCompanies.filter((c) => !linked.some((l) => l.id === c.id))

  const handleLink = async () => {
    if (!selectedCompany) return
    setLinking(true)
    try {
      await api.post(`/users/${user.id}/link-company`, { companyId: selectedCompany })
      const company = allCompanies.find((c) => c.id === selectedCompany)
      if (company) {
        setLinked((prev) => [...prev, { id: company.id, name: company.name, isDefault: prev.length === 0 }])
      }
      setSelected('')
      onChanged()
      toast.success('Company linked')
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error ?? 'Failed to link company'
      toast.error(msg)
    } finally {
      setLinking(false)
    }
  }

  const handleUnlink = async (companyId: string) => {
    try {
      await api.delete(`/users/${user.id}/link-company/${companyId}`)
      setLinked((prev) => {
        const next = prev.filter((l) => l.id !== companyId)
        // If removed was default, promote first remaining
        const hadDefault = prev.find((l) => l.id === companyId)?.isDefault
        if (hadDefault && next.length > 0) next[0] = { ...next[0], isDefault: true }
        return next
      })
      onChanged()
      toast.success('Company unlinked')
    } catch {
      toast.error('Failed to unlink company')
    }
  }

  const handleSetDefault = async (companyId: string) => {
    try {
      await api.patch(`/users/${user.id}/default-company`, { companyId })
      setLinked((prev) => prev.map((l) => ({ ...l, isDefault: l.id === companyId })))
      toast.success('Default company updated')
    } catch {
      toast.error('Failed to set default company')
    }
  }

  const handleResetPassword = async () => {
    if (newPassword.length < 8) { toast.error('Password must be at least 8 characters'); return }
    setResetting(true)
    try {
      await api.patch(`/users/${user.id}/reset-password`, { password: newPassword })
      setNewPassword('')
      toast.success('Password reset successfully')
    } catch {
      toast.error('Failed to reset password')
    } finally {
      setResetting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex">
      <div className="flex-1 bg-black/50 backdrop-blur-sm" onClick={onClose} />

      <div className="w-[400px] flex flex-col bg-gray-900 shadow-2xl border-l border-gray-700/50 overflow-y-auto">

        {/* header */}
        <div className="relative bg-gradient-to-br from-gray-800 via-gray-900 to-blue-950 px-6 pt-6 pb-8 border-b border-gray-700/50">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 w-7 h-7 flex items-center justify-center rounded-full bg-gray-700/60 text-gray-400 hover:text-white hover:bg-gray-600 transition-colors"
          >
            <X size={14} />
          </button>

          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-500 to-blue-600 flex items-center justify-center mb-4 shadow-lg shadow-blue-900/40">
            <span className="text-white font-bold text-lg">{user.name.charAt(0).toUpperCase()}</span>
          </div>

          <h2 className="text-base font-bold text-white leading-tight">{user.name}</h2>
          <p className="text-xs text-gray-400 mt-0.5">{user.email}</p>
          {user.enterpriseName && (
            <p className="text-[10px] text-blue-400/70 mt-1 tracking-wider uppercase">{user.enterpriseName}</p>
          )}
        </div>

        {/* linked companies */}
        <div className="flex-1 px-5 py-5">
          <p className="text-xs font-bold text-gray-300 uppercase tracking-widest mb-3">Linked Companies</p>

          <div className="space-y-1.5 mb-4">
            {linked.length === 0 && (
              <p className="text-xs text-gray-500">No companies linked yet.</p>
            )}
            {linked.map((l) => (
              <div key={l.id} className="flex items-center gap-2 py-2 px-3 rounded-lg bg-gray-800/60">
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-medium text-gray-200 truncate">{l.name}</p>
                  {l.isDefault && (
                    <span className="text-[10px] text-amber-400">Default</span>
                  )}
                </div>
                <button
                  onClick={() => handleSetDefault(l.id)}
                  title="Set as default"
                  className={cn(
                    'flex-shrink-0 w-6 h-6 flex items-center justify-center rounded transition-colors',
                    l.isDefault
                      ? 'text-amber-400'
                      : 'text-gray-600 hover:text-amber-400 hover:bg-amber-400/10',
                  )}
                >
                  <Star size={12} fill={l.isDefault ? 'currentColor' : 'none'} />
                </button>
                <button
                  onClick={() => handleUnlink(l.id)}
                  title="Unlink"
                  className="flex-shrink-0 w-6 h-6 flex items-center justify-center rounded text-gray-600 hover:text-red-400 hover:bg-red-400/10 transition-colors"
                >
                  <X size={12} />
                </button>
              </div>
            ))}
          </div>

          {unlinked.length > 0 && (
            <div>
              <p className="text-xs font-bold text-gray-300 uppercase tracking-widest mb-2">Link a Company</p>
              <div className="flex gap-2">
                <select
                  value={selectedCompany}
                  onChange={(e) => setSelected(e.target.value)}
                  className="flex-1 text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500"
                >
                  <option value="">— Select company —</option>
                  {unlinked.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
                <Button variant="outline" size="sm" loading={linking} onClick={handleLink}>
                  Link
                </Button>
              </div>
              <p className="text-[10px] text-gray-600 mt-1.5">
                Star (★) sets the company that loads by default on login.
              </p>
            </div>
          )}

          {/* Reset password */}
          <div className="mt-6 pt-5 border-t border-gray-700/50">
            <p className="text-xs font-bold text-gray-300 uppercase tracking-widest mb-3 flex items-center gap-1.5">
              <KeyRound size={11} /> Reset Password
            </p>
            <div className="flex gap-2">
              <input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="New password (min 8 chars)"
                className="flex-1 text-xs bg-gray-800 border border-gray-700 text-gray-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-teal-500 placeholder:text-gray-600"
              />
              <Button variant="outline" size="sm" loading={resetting} onClick={handleResetPassword}>
                Reset
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// ── Main page ─────────────────────────────────────────────────────────────────

export default function AdminUsers() {
  const [users, setUsers]       = useState<EnterpriseUser[]>([])
  const [showAdd, setShowAdd]   = useState(false)
  const [selected, setSelected] = useState<EnterpriseUser | null>(null)

  const fetchUsers = useCallback(async () => {
    try {
      const { data } = await api.get<EnterpriseUser[]>('/users')
      setUsers(data)
    } catch {
      toast.error('Failed to load users')
    }
  }, [])

  useEffect(() => { fetchUsers() }, [fetchUsers])

  return (
    <>
      <PageHeader
        title="Enterprise Users"
        subtitle="Manage login accounts and their linked companies"
        actions={
          <Button variant="primary" size="sm" onClick={() => setShowAdd(true)}>
            <Plus className="w-3.5 h-3.5" />
            Add User
          </Button>
        }
      />

      <div className="p-4 md:p-7">
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full border-collapse" aria-label="Enterprise users">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  {['Enterprise', 'Name', 'Email', 'Companies', ''].map((h) => (
                    <th key={h} className="px-4 py-2.5 text-left text-[10px] font-bold text-gray-500 uppercase tracking-widest">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {users.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-sm text-gray-400">
                      No users yet. Click "Add User" to create the first enterprise account.
                    </td>
                  </tr>
                )}
                {users.map((u) => (
                  <tr key={u.id} className="border-b border-gray-100 last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm font-semibold text-gray-800">
                      {u.enterpriseName || <span className="text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-700">{u.name}</td>
                    <td className="px-4 py-3 text-xs text-gray-500">{u.email}</td>
                    <td className="px-4 py-3 text-xs text-gray-500">
                      {u.companies.length === 0
                        ? <span className="text-amber-500">No companies linked</span>
                        : u.companies.map((c) => c.name).join(', ')
                      }
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => setSelected(u)}
                        className="flex items-center gap-1 text-xs font-medium text-brand-600 hover:text-brand-800 transition-colors"
                      >
                        Manage <ChevronRight size={12} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <AddUserModal
        open={showAdd}
        onClose={() => setShowAdd(false)}
        onCreated={fetchUsers}
      />

      {selected && (
        <UserPanel
          user={users.find((u) => u.id === selected.id) ?? selected}
          onClose={() => setSelected(null)}
          onChanged={fetchUsers}
        />
      )}
    </>
  )
}
