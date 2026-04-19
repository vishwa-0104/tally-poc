import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { X } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { useCompanyStore } from '@/store'
import { createTallyStockItem } from '@/services/tallyService'

interface CreateStockItemModalProps {
  open: boolean
  companyId: string
  tallyUrl: string
  tallyCompany: string
  billItemDescription: string
  hsnCode: string
  onSuccess: (tallyItemName: string) => void
  onClose: () => void
}

export function CreateStockItemModal({
  open,
  companyId,
  tallyUrl,
  tallyCompany,
  billItemDescription,
  hsnCode,
  onSuccess,
  onClose,
}: CreateStockItemModalProps) {
  const { getStockGroups, getStockUnits, addStockItem } = useCompanyStore()
  const stockGroups = getStockGroups(companyId)
  const stockUnits  = getStockUnits(companyId)

  const [creating, setCreating]               = useState(false)
  const [error, setError]                     = useState<string | null>(null)
  const [name, setName]                       = useState(billItemDescription)
  const [description, setDescription]         = useState('')
  const [group, setGroup]                     = useState('')
  const [unit, setUnit]                       = useState('')
  const [gstApplicable, setGstApplicable]     = useState<'Yes' | 'No'>('Yes')
  const [taxability, setTaxability]           = useState('Taxable')
  const [gstRate, setGstRate]                 = useState<'5' | '18'>('18')
  const [typeOfSupply, setTypeOfSupply]       = useState('Goods')

  useEffect(() => {
    document.body.style.overflow = 'hidden'
    return () => { document.body.style.overflow = '' }
  }, [])

  if (!open) return null

  const handleCreate = async () => {
    if (!name.trim())  { setError('Name is required');  return }
    if (!group.trim()) { setError('Group is required'); return }
    if (!unit.trim())  { setError('Unit is required');  return }

    setError(null)
    setCreating(true)
    try {
      const result = await createTallyStockItem(
        {
          name:          name.trim(),
          description:   description.trim() || undefined,
          group:         group.trim(),
          unit:          unit.trim(),
          gstApplicable,
          taxability,
          hsnCode,
          gstRate:       gstApplicable === 'Yes' && taxability === 'Taxable' ? Number(gstRate) : undefined,
          typeOfSupply,
          tallyCompany,
        },
        tallyUrl,
      )

      if (result.success && result.created > 0) {
        const itemName = name.trim()
        addStockItem(companyId, { name: itemName, group: group.trim(), unit: unit.trim() })
        toast.success(`"${itemName}" created in Tally`)
        onSuccess(itemName)
        onClose()
      } else {
        setError(result.message ?? 'Tally returned 0 created items. Check stock group name and try again.')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create stock item')
    } finally {
      setCreating(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg flex flex-col max-h-[90vh]">
        {/* Header — fixed */}
        <div className="flex items-center justify-between px-6 pt-6 pb-4 flex-shrink-0">
          <h2 className="text-base font-bold text-gray-900">Create Stock Item in Tally</h2>
          <button onClick={onClose} disabled={creating} className="text-gray-400 hover:text-gray-600 disabled:opacity-40">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Scrollable content */}
        <div className="overflow-y-auto px-6 flex-1">
        <div className="space-y-4 pb-2">
          {/* Name */}
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">Name *</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="input-base w-full"
              placeholder="Stock item name"
            />
          </div>

          {/* Group */}
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">
              Group *
              {stockGroups.length === 0 && (
                <span className="ml-2 text-amber-500 font-normal">— sync stock groups in Settings first</span>
              )}
            </label>
            <input
              value={group}
              onChange={(e) => setGroup(e.target.value)}
              list="csim-groups"
              autoComplete="off"
              className="input-base w-full"
              placeholder="Type or select stock group…"
            />
            <datalist id="csim-groups">
              {stockGroups.map((g) => <option key={g.name} value={g.name} />)}
            </datalist>
          </div>

          {/* Unit */}
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">
              Unit *
              {stockUnits.length === 0 && (
                <span className="ml-2 text-amber-500 font-normal">— sync stock units in Settings first</span>
              )}
            </label>
            <input
              value={unit}
              onChange={(e) => setUnit(e.target.value)}
              list="csim-units"
              autoComplete="off"
              className="input-base w-full"
              placeholder="Type or select unit…"
            />
            <datalist id="csim-units">
              {stockUnits.map((u) => <option key={u.name} value={u.symbol !== u.name ? `${u.name} (${u.symbol})` : u.name} />)}
            </datalist>
          </div>

          {/* GST Applicable */}
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">GST Applicable</label>
            <select
              value={gstApplicable}
              onChange={(e) => setGstApplicable(e.target.value as 'Yes' | 'No')}
              className="input-base w-full"
            >
              <option value="Yes">Yes</option>
              <option value="No">No</option>
            </select>
          </div>

          {/* All GST-dependent fields */}
          {gstApplicable === 'Yes' && (
            <>
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5">Taxability</label>
                <select
                  value={taxability}
                  onChange={(e) => setTaxability(e.target.value)}
                  className="input-base w-full"
                >
                  <option value="Taxable">Taxable</option>
                  <option value="Exempt">Exempt</option>
                  <option value="Nil Rated">Nil Rated</option>
                  <option value="Non-GST">Non-GST</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5">HSN No</label>
                <input
                  value={hsnCode}
                  readOnly
                  className="input-base w-full bg-gray-50 text-gray-500 cursor-not-allowed select-none"
                />
              </div>

              {taxability === 'Taxable' && (
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1.5">GST Rate %</label>
                  <select
                    value={gstRate}
                    onChange={(e) => setGstRate(e.target.value as '5' | '18')}
                    className="input-base w-full"
                  >
                    <option value="5">5%</option>
                    <option value="18">18%</option>
                  </select>
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5">Description</label>
                <input
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="input-base w-full"
                  placeholder="Optional description"
                />
              </div>
            </>
          )}

          {/* Type of Supply */}
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5">Type of Supply</label>
            <select
              value={typeOfSupply}
              onChange={(e) => setTypeOfSupply(e.target.value)}
              className="input-base w-full"
            >
              <option value="Capital Goods">Capital Goods</option>
              <option value="Goods">Goods</option>
              <option value="Services">Services</option>
            </select>
          </div>

          {/* Error */}
          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-xs text-red-700">{error}</p>
            </div>
          )}
        </div>
        </div>

        {/* Actions — fixed at bottom */}
        <div className="flex justify-end gap-3 px-6 py-4 border-t border-gray-100 flex-shrink-0">
          <Button type="button" variant="outline" onClick={onClose} disabled={creating}>
            Close
          </Button>
          <Button type="button" variant="teal" loading={creating} onClick={handleCreate}>
            Create Item in Tally
          </Button>
        </div>
      </div>
    </div>
  )
}
