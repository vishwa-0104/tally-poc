import { useState } from 'react'
import { Plus } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { Button } from '@/components/ui/Button'
import { StatusBadge } from '@/components/ui/Badge'
import { AddCompanyModal } from '@/components/admin'
import { useCompanyStore } from '@/store'

export default function AdminCompanies() {
  const [showAdd, setShowAdd] = useState(false)
  const { companies } = useCompanyStore()

  return (
    <>
      <PageHeader
        title="Companies"
        subtitle="Manage company accounts and Tally connections"
        actions={
          <Button variant="primary" size="sm" onClick={() => setShowAdd(true)}>
            <Plus className="w-3.5 h-3.5" />
            Add Company
          </Button>
        }
      />

      <div className="p-4 md:p-7">
        <div className="card overflow-hidden">
          <table className="w-full border-collapse" aria-label="Companies">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                {['Company', 'GSTIN', 'Login Email', 'Bills', 'Port', 'Tally Mapping'].map((h) => (
                  <th key={h} className="px-4 py-2.5 text-left text-[10px] font-bold text-gray-500 uppercase tracking-widest">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {companies.map((c) => (
                <tr key={c.id} className="border-b border-gray-100 last:border-0 hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm font-semibold text-gray-800">{c.name}</td>
                  <td className="px-4 py-3 font-mono text-xs text-gray-500">{c.gstin || '—'}</td>
                  <td className="px-4 py-3 text-xs text-gray-500">{c.email}</td>
                  <td className="px-4 py-3 text-sm text-gray-700">{c.totalBills}</td>
                  <td className="px-4 py-3 font-mono text-xs text-gray-500">:{c.port}</td>
                  <td className="px-4 py-3">
                    {c.mapping
                      ? <StatusBadge status="synced" />
                      : <StatusBadge status="pending" />}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <AddCompanyModal open={showAdd} onClose={() => setShowAdd(false)} />
    </>
  )
}
