import type { Company } from '@/types'

interface CompanyCardProps {
  company: Company
}

export function CompanyCard({ company }: CompanyCardProps) {
  const pct = company.totalBills > 0
    ? Math.round((company.syncedBills / company.totalBills) * 100)
    : 0

  const badge = company.errorBills > 0
    ? <span className="badge badge-red">{company.errorBills} errors</span>
    : company.pendingBills > 0
    ? <span className="badge badge-amber">{company.pendingBills} pending</span>
    : <span className="badge badge-green">All synced</span>

  return (
    <div className="card p-5">
      <div className="flex items-start justify-between mb-3">
        <div className="min-w-0">
          <h3 className="text-sm font-bold text-gray-900 truncate">{company.name}</h3>
          <p className="text-xs text-gray-500 font-mono mt-0.5">{company.gstin}</p>
        </div>
        {badge}
      </div>

      {/* Sync progress bar */}
      <div className="mb-1">
        <p className="text-[10px] text-gray-500 mb-1">Sync progress</p>
        <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
          <div
            className="h-full bg-teal-500 rounded-full transition-all duration-500"
            style={{ width: `${pct}%` }}
            role="progressbar"
            aria-valuenow={pct}
            aria-valuemin={0}
            aria-valuemax={100}
            aria-label={`${pct}% synced`}
          />
        </div>
        <p className="text-[10px] text-gray-500 mt-1">
          {company.syncedBills} of {company.totalBills} bills ({pct}%)
        </p>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-4 gap-2 mt-4 pt-4 border-t border-gray-100">
        {[
          { label: 'Total',   value: company.totalBills,   color: 'text-gray-800' },
          { label: 'Synced',  value: company.syncedBills,  color: 'text-emerald-600' },
          { label: 'Pending', value: company.pendingBills, color: 'text-amber-600' },
          { label: 'Errors',  value: company.errorBills,   color: 'text-red-500' },
        ].map((s) => (
          <div key={s.label} className="text-center">
            <p className={`text-lg font-bold ${s.color}`}>{s.value}</p>
            <p className="text-[10px] text-gray-500 mt-0.5">{s.label}</p>
          </div>
        ))}
      </div>
    </div>
  )
}
