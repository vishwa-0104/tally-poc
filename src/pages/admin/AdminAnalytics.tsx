import { PageHeader } from '@/components/shared'
import { useCompanyStore } from '@/store'

export default function AdminAnalytics() {
  const { companies } = useCompanyStore()

  return (
    <>
      <PageHeader
        title="Analytics"
        subtitle="High-level sync performance — counts only, no bill details"
      />

      <div className="p-4 md:p-7">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {companies.map((c) => {
            const pct = c.totalBills > 0 ? Math.round((c.syncedBills / c.totalBills) * 100) : 0
            return (
              <div key={c.id} className="card p-5">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-sm font-bold text-gray-900">{c.name}</h3>
                    <p className="text-xs font-mono text-gray-500 mt-0.5">{c.gstin}</p>
                  </div>
                  <span className="text-xs font-semibold text-gray-500">{pct}% synced</span>
                </div>

                <div className="h-2 bg-gray-100 rounded-full overflow-hidden mb-4">
                  <div className="h-full bg-teal-500 rounded-full" style={{ width: `${pct}%` }} />
                </div>

                <div className="space-y-2">
                  {[
                    { label: 'Total Bills',  value: c.totalBills,   color: 'text-gray-800' },
                    { label: 'Synced',        value: c.syncedBills,  color: 'text-emerald-600' },
                    { label: 'Pending',       value: c.pendingBills, color: 'text-amber-600' },
                    { label: 'Errors',        value: c.errorBills,   color: 'text-red-500' },
                  ].map((row) => (
                    <div key={row.label} className="flex justify-between items-center py-1.5 border-b border-gray-100 last:border-0">
                      <span className="text-xs text-gray-500">{row.label}</span>
                      <span className={`text-sm font-bold ${row.color}`}>{row.value}</span>
                    </div>
                  ))}
                </div>
              </div>
            )
          })}
        </div>

        <p className="mt-5 text-xs text-gray-500 italic text-center">
          Bill-level data is private to each company. These numbers are counts only.
        </p>
      </div>
    </>
  )
}
