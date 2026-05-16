import { useState } from 'react'
import { X } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { useCompanyStore } from '@/store'
import { createTallyStockGroup } from '@/services/tallyService'

interface CreateStockGroupModalProps {
  open: boolean
  companyId: string
  tallyUrl: string
  tallyCompany: string
  onSuccess: (groupName: string) => void
  onClose: () => void
}

export function CreateStockGroupModal({
  open,
  companyId,
  tallyUrl,
  tallyCompany,
  onSuccess,
  onClose,
}: CreateStockGroupModalProps) {
  const { getStockGroups, addStockGroup, fetchStockGroupsFromDb } = useCompanyStore()
  const stockGroups = getStockGroups(companyId)

  const [name, setName]     = useState('')
  const [under, setUnder]   = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError]   = useState<string | null>(null)

  if (!open) return null

  const handleCreate = async () => {
    const trimmed = name.trim()
    if (!trimmed) { setError('Name is required'); return }
    if (stockGroups.some((g) => g.name.toLowerCase() === trimmed.toLowerCase())) {
      setError('A group with this name already exists')
      return
    }

    setError(null)
    setSaving(true)
    try {
      const result = await createTallyStockGroup(
        { name: trimmed, parent: under, tallyCompany },
        tallyUrl,
      )

      if (!result.success || result.created === 0) {
        setError(result.message ?? 'Tally returned 0 created groups. Check group name and try again.')
        return
      }

      await addStockGroup(companyId, { name: trimmed, parent: under })
      fetchStockGroupsFromDb(companyId).catch(() => {})
      onSuccess(trimmed)
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create group')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-60 flex items-center justify-center bg-black/20 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm">
        <div className="flex items-center justify-between px-5 pt-5 pb-4">
          <h3 className="text-sm font-bold text-gray-900">Create Stock Group</h3>
          <button onClick={onClose} disabled={saving} className="text-gray-400 hover:text-gray-600 disabled:opacity-40">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="px-5 pb-5 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">Name *</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="input-base w-full"
              placeholder="Stock group name"
              autoFocus
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">Under</label>
            <select
              value={under}
              onChange={(e) => setUnder(e.target.value)}
              className="input-base w-full"
            >
              <option value="">Primary</option>
              {stockGroups.map((g) => (
                <option key={g.name} value={g.name}>{g.name}</option>
              ))}
            </select>
          </div>

          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-xs text-red-700">{error}</p>
            </div>
          )}

          <div className="flex justify-end gap-3 pt-1">
            <Button type="button" variant="outline" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button type="button" variant="teal" loading={saving} onClick={handleCreate}>
              Create Group
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
