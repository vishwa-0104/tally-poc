import { useState } from 'react'
import { X } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { useCompanyStore } from '@/store'
import { createTallyLedger } from '@/services/tallyService'

interface CreateLedgerModalProps {
  open: boolean
  companyId: string
  vendorName: string
  vendorGstin?: string
  tallyUrl: string
  tallyCompany?: string
  onSuccess: (ledgerName: string) => void
  onClose: () => void
}

export function CreateLedgerModal({
  open,
  companyId,
  vendorName,
  vendorGstin = '',
  tallyUrl,
  tallyCompany = '',
  onSuccess,
  onClose,
}: CreateLedgerModalProps) {
  const { getLedgers, saveLedgersToDb } = useCompanyStore()

  const [name, setName]       = useState(vendorName)
  const [under, setUnder]     = useState('Sundry Creditors')
  const [gstin, setGstin]     = useState(vendorGstin)
  const [pan, setPan]         = useState('')
  const [address, setAddress] = useState('')
  const [state, setState]     = useState('')
  const [pincode, setPincode] = useState('')
  const [saving, setSaving]   = useState(false)
  const [error, setError]     = useState<string | null>(null)

  if (!open) return null

  const handleCreate = async () => {
    const trimmed = name.trim()
    if (!trimmed) { setError('Name is required'); return }

    setError(null)
    setSaving(true)
    try {
      const result = await createTallyLedger(
        {
          name:        trimmed,
          under:       under.trim() || 'Sundry Creditors',
          gstin:       gstin.trim() || undefined,
          pan:         pan.trim() || undefined,
          address:     address.trim() || undefined,
          state:       state.trim() || undefined,
          pincode:     pincode.trim() || undefined,
          tallyCompany,
        },
        tallyUrl,
      )

      if (!result.success || result.created === 0) {
        setError(result.message ?? 'Tally returned 0 created ledgers. Check the name and try again.')
        return
      }

      const group = under.trim() || 'Sundry Creditors'
      const updated = [...getLedgers(companyId), { name: trimmed, group, gstin: gstin.trim() || undefined }]
      saveLedgersToDb(companyId, updated).catch(() => {})
      onSuccess(trimmed)
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create ledger')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-60 flex items-center justify-center bg-black/30 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm max-h-[90vh] flex flex-col">
        <div className="flex items-center justify-between px-5 pt-5 pb-4 flex-shrink-0">
          <h3 className="text-sm font-bold text-gray-900">Create Vendor Ledger in Tally</h3>
          <button onClick={onClose} disabled={saving} className="text-gray-400 hover:text-gray-600 disabled:opacity-40">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="overflow-y-auto px-5 pb-5 space-y-4 flex-1">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">Name *</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="input-base w-full"
              placeholder="Vendor name"
              autoFocus
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">Under</label>
            <input
              value={under}
              onChange={(e) => setUnder(e.target.value)}
              className="input-base w-full"
              placeholder="Sundry Creditors"
            />
          </div>

          <div className="pt-1 border-t border-gray-100">
            <p className="text-xs font-bold text-gray-500 uppercase tracking-wide mb-3">Tax Registration</p>
            <div className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5">GSTIN/UIN</label>
                <input
                  value={gstin}
                  onChange={(e) => setGstin(e.target.value)}
                  className="input-base w-full font-mono"
                  placeholder="e.g. 09ABCDE1234F1ZK"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5">PAN/IT No.</label>
                <input
                  value={pan}
                  onChange={(e) => setPan(e.target.value)}
                  className="input-base w-full font-mono uppercase"
                  placeholder="e.g. ABCDE1234F"
                />
              </div>
            </div>
          </div>

          <div className="pt-1 border-t border-gray-100">
            <p className="text-xs font-bold text-gray-500 uppercase tracking-wide mb-3">Mailing Details</p>
            <div className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5">Address</label>
                <textarea
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  rows={2}
                  className="input-base w-full resize-none"
                  placeholder="Street / area / locality"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1.5">State</label>
                  <input
                    value={state}
                    onChange={(e) => setState(e.target.value)}
                    className="input-base w-full"
                    placeholder="e.g. Uttar Pradesh"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1.5">Pincode</label>
                  <input
                    value={pincode}
                    onChange={(e) => setPincode(e.target.value)}
                    className="input-base w-full"
                    placeholder="e.g. 201001"
                  />
                </div>
              </div>
            </div>
          </div>

          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-xs text-red-700">{error}</p>
            </div>
          )}
        </div>

        <div className="flex justify-end gap-3 px-5 py-4 border-t border-gray-100 flex-shrink-0">
          <Button type="button" variant="outline" onClick={onClose} disabled={saving}>
            Cancel
          </Button>
          <Button type="button" variant="teal" loading={saving} onClick={handleCreate}>
            Create Ledger
          </Button>
        </div>
      </div>
    </div>
  )
}
