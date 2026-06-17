import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { fetchSalesTargets, saveSalesTargets } from '@/lib/api'

const FY_MONTHS = [
  { month: 4,  label: 'April'     },
  { month: 5,  label: 'May'       },
  { month: 6,  label: 'June'      },
  { month: 7,  label: 'July'      },
  { month: 8,  label: 'August'    },
  { month: 9,  label: 'September' },
  { month: 10, label: 'October'   },
  { month: 11, label: 'November'  },
  { month: 12, label: 'December'  },
  { month: 1,  label: 'January'   },
  { month: 2,  label: 'February'  },
  { month: 3,  label: 'March'     },
]

function getCurrentFyYear() {
  const today = new Date()
  return today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1
}

interface Props {
  open:      boolean
  onClose:   () => void
  companyId: string
}

export function SalesTargetModal({ open, onClose, companyId }: Props) {
  const fyYear  = getCurrentFyYear()
  const fyLabel = `FY ${fyYear}–${String(fyYear + 1).slice(2)}`

  const [values,  setValues]  = useState<Record<number, string>>({})
  const [loading, setLoading] = useState(false)
  const [saving,  setSaving]  = useState(false)

  useEffect(() => {
    if (!open) return
    setLoading(true)
    fetchSalesTargets(companyId, fyYear)
      .then(rows => {
        const map: Record<number, string> = {}
        rows.forEach(r => { map[r.month] = String(r.target) })
        setValues(map)
      })
      .catch(() => toast.error('Failed to load targets'))
      .finally(() => setLoading(false))
  }, [open, companyId, fyYear])

  const handleSave = async () => {
    const targets = FY_MONTHS.map(({ month }) => ({
      month,
      target: parseFloat(values[month] || '0') || 0,
    }))
    setSaving(true)
    try {
      await saveSalesTargets(companyId, fyYear, targets)
      toast.success('Targets saved')
      onClose()
    } catch {
      toast.error('Failed to save targets')
    } finally {
      setSaving(false)
    }
  }

  const totalTarget = FY_MONTHS.reduce((s, { month }) => s + (parseFloat(values[month] || '0') || 0), 0)

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Sales Targets"
      subtitle={`Set monthly sales targets for ${fyLabel} (excl. GST)`}
      footer={
        <>
          <Button variant="outline" onClick={onClose} disabled={saving}>Cancel</Button>
          <Button variant="primary" onClick={handleSave} loading={saving}>Save Targets</Button>
        </>
      }
    >
      {loading ? (
        <div className="h-40 flex items-center justify-center text-sm text-gray-400">Loading…</div>
      ) : (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-x-6 gap-y-3">
            {FY_MONTHS.map(({ month, label }) => (
              <div key={month} className="flex items-center gap-3">
                <label className="text-xs text-gray-600 w-24 shrink-0">{label}</label>
                <div className="relative flex-1">
                  <span className="absolute left-2.5 top-1/2 -translate-y-1/2 text-xs text-gray-400">₹</span>
                  <input
                    type="number"
                    min="0"
                    step="1"
                    placeholder="0"
                    value={values[month] ?? ''}
                    onChange={e => setValues(v => ({ ...v, [month]: e.target.value }))}
                    className="w-full pl-6 pr-2 py-1.5 text-xs border border-gray-200 rounded-lg outline-none focus:border-blue-500 bg-white"
                  />
                </div>
              </div>
            ))}
          </div>

          {totalTarget > 0 && (
            <div className="flex justify-between items-center border-t border-gray-100 pt-3 text-xs">
              <span className="text-gray-500">Annual Target</span>
              <span className="font-semibold text-gray-800">
                ₹{totalTarget.toLocaleString('en-IN', { maximumFractionDigits: 0 })}
              </span>
            </div>
          )}
        </div>
      )}
    </Modal>
  )
}
