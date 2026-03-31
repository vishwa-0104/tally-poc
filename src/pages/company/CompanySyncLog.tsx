import { RefreshCw } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { EmptyState } from '@/components/ui'
import { formatCurrency, formatDate } from '@/lib/utils'
import { useAuthStore, useBillStore } from '@/store'

export default function CompanySyncLog() {
  const { user }    = useAuthStore()
  const { getBills } = useBillStore()

  const bills  = user?.companyId ? getBills(user.companyId) : []
  const synced = bills.filter((b) => b.status === 'synced')
  const errors = bills.filter((b) => b.status === 'error')

  return (
    <>
      <PageHeader title="Sync Log" subtitle="History of all Tally sync operations" />

      <div className="p-7 space-y-6">
        {/* Synced */}
        <div>
          <h2 className="text-sm font-bold text-gray-800 mb-3">Successful Syncs ({synced.length})</h2>
          <div className="card overflow-hidden">
            {synced.length === 0 ? (
              <EmptyState
                icon={RefreshCw}
                title="No syncs yet"
                description="Synced bills will appear here"
              />
            ) : (
              <table className="w-full border-collapse" aria-label="Synced bills">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200">
                    {['Bill No.', 'Vendor', 'Amount', 'Bill Date', 'Synced At', 'Result'].map((h) => (
                      <th key={h} className="px-4 py-2.5 text-left text-[10px] font-bold text-gray-500 uppercase tracking-widest">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {synced.map((b) => (
                    <tr key={b.id} className="border-b border-gray-100 last:border-0 hover:bg-gray-50">
                      <td className="px-4 py-3 font-mono text-xs text-gray-500">{b.billNumber}</td>
                      <td className="px-4 py-3 text-sm font-medium text-gray-800">{b.vendorName}</td>
                      <td className="px-4 py-3 text-sm font-semibold text-gray-800">{formatCurrency(b.totalAmount)}</td>
                      <td className="px-4 py-3 text-xs text-gray-500">{formatDate(b.billDate)}</td>
                      <td className="px-4 py-3 text-xs text-gray-400">{b.syncedAt ? formatDate(b.syncedAt) : '—'}</td>
                      <td className="px-4 py-3"><span className="badge badge-green">Success</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Errors */}
        {errors.length > 0 && (
          <div>
            <h2 className="text-sm font-bold text-gray-800 mb-3">Failed Syncs ({errors.length})</h2>
            <div className="card overflow-hidden">
              <table className="w-full border-collapse" aria-label="Failed syncs">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200">
                    {['Bill No.', 'Vendor', 'Amount', 'Error'].map((h) => (
                      <th key={h} className="px-4 py-2.5 text-left text-[10px] font-bold text-gray-500 uppercase tracking-widest">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {errors.map((b) => (
                    <tr key={b.id} className="border-b border-gray-100 last:border-0 hover:bg-gray-50">
                      <td className="px-4 py-3 font-mono text-xs text-gray-500">{b.billNumber}</td>
                      <td className="px-4 py-3 text-sm font-medium text-gray-800">{b.vendorName}</td>
                      <td className="px-4 py-3 text-sm font-semibold text-gray-800">{formatCurrency(b.totalAmount)}</td>
                      <td className="px-4 py-3 text-xs text-red-600">{b.syncError}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </>
  )
}
