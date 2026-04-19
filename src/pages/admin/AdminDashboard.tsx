import { useState } from 'react'
import { Plus, Building2 } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { StatCard } from '@/components/ui'
import { Button } from '@/components/ui/Button'
import { CompanyCard, AddCompanyModal } from '@/components/admin'
import { useCompanyStore } from '@/store'

export default function AdminDashboard() {
  const [showAddModal, setShowAddModal] = useState(false)
  const { companies } = useCompanyStore()

  const totals = companies.reduce(
    (acc, c) => ({
      bills:   acc.bills   + c.totalBills,
      synced:  acc.synced  + c.syncedBills,
      pending: acc.pending + c.pendingBills,
      errors:  acc.errors  + c.errorBills,
    }),
    { bills: 0, synced: 0, pending: 0, errors: 0 },
  )

  return (
    <>
      <PageHeader
        title="Admin Dashboard"
        subtitle="Aggregate overview — bill details are not visible at this level"
        actions={
          <Button variant="primary" size="sm" onClick={() => setShowAddModal(true)}>
            <Plus className="w-3.5 h-3.5" />
            Add Company
          </Button>
        }
      />

      <div className="p-4 md:p-7">
        {/* Stats */}
        <div className="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-7">
          <StatCard label="Companies"    value={companies.length} sub="Registered"      accent="blue" />
          <StatCard label="Total Synced" value={totals.synced}    sub="All companies"   accent="green" />
          <StatCard label="Pending"      value={totals.pending}   sub="Awaiting sync"   accent="amber" />
          <StatCard label="Errors"       value={totals.errors}    sub="Need attention"  accent="red" />
        </div>

        {/* Companies grid */}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-sm font-bold text-gray-800">Company Overview</h2>
          <Button variant="outline" size="sm" onClick={() => setShowAddModal(true)}>
            <Plus className="w-3.5 h-3.5" />
            Add Company
          </Button>
        </div>

        {companies.length === 0 ? (
          <div className="card p-14 text-center">
            <div className="w-14 h-14 bg-gray-100 rounded-xl flex items-center justify-center mx-auto mb-4">
              <Building2 className="w-6 h-6 text-gray-500" />
            </div>
            <p className="text-sm font-semibold text-gray-700 mb-1">No companies yet</p>
            <p className="text-sm text-gray-500 mb-5">Add your first company to start tracking bills</p>
            <Button variant="primary" onClick={() => setShowAddModal(true)}>Add Company</Button>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
            {companies.map((c) => <CompanyCard key={c.id} company={c} />)}
            {/* Add new tile */}
            <button
              onClick={() => setShowAddModal(true)}
              className="card border-2 border-dashed border-gray-200 min-h-[160px] flex flex-col items-center justify-center gap-3 hover:border-brand-400 hover:bg-brand-50/50 transition-all cursor-pointer"
            >
              <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                <Plus className="w-5 h-5 text-gray-500" />
              </div>
              <p className="text-sm font-semibold text-gray-500">Add Company</p>
            </button>
          </div>
        )}

        {/* Privacy note */}
        <div className="mt-6 p-4 bg-brand-50 border border-brand-100 rounded-xl text-xs text-brand-700">
          <strong>Privacy:</strong> As admin you see only aggregate numbers. Individual bill details, vendor names,
          and amounts are visible only to each company when they log in with their own credentials.
        </div>
      </div>

      <AddCompanyModal open={showAddModal} onClose={() => setShowAddModal(false)} />
    </>
  )
}
