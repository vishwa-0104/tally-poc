import { useNavigate } from 'react-router-dom'
import { FileText } from 'lucide-react'
import { StatusBadge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { EmptyState } from '@/components/ui/EmptyState'
import { formatCurrency, formatDate } from '@/lib/utils'
import type { Bill } from '@/types'

interface BillsTableProps {
  bills: Bill[]
  onUpload: () => void
}

export function BillsTable({ bills, onUpload }: BillsTableProps) {
  const navigate = useNavigate()

  if (bills.length === 0) {
    return (
      <EmptyState
        icon={FileText}
        title="No bills yet"
        description="Upload your first purchase bill to get started"
        action={<Button variant="teal" onClick={onUpload}>Upload Bill</Button>}
      />
    )
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse" aria-label="Bills list">
        <thead>
          <tr className="bg-gray-50 border-b border-gray-200">
            {['Bill No.', 'Vendor', 'Date', 'Amount', 'Status', 'Action'].map((h) => (
              <th key={h} className="px-4 py-2.5 text-left text-[10px] font-bold text-gray-500 uppercase tracking-widest">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {bills.map((bill) => (
            <tr key={bill.id} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
              <td className="px-4 py-3 font-mono text-xs text-gray-600">{bill.billNumber}</td>
              <td className="px-4 py-3 text-sm font-medium text-gray-800">{bill.vendorName}</td>
              <td className="px-4 py-3 text-xs text-gray-500">{formatDate(bill.billDate)}</td>
              <td className="px-4 py-3 text-sm font-semibold text-gray-800">{formatCurrency(bill.totalAmount)}</td>
              <td className="px-4 py-3"><StatusBadge status={bill.status} /></td>
              <td className="px-4 py-3">
                {(bill.status === 'parsed' || bill.status === 'mapped') && (
                  <Button variant="teal" size="sm" onClick={() => navigate(`/company/bills/${bill.id}`)}>
                    Map & Sync
                  </Button>
                )}
                {bill.status === 'error' && (
                  <Button variant="danger" size="sm" onClick={() => navigate(`/company/bills/${bill.id}`)}>
                    Retry
                  </Button>
                )}
                {bill.status === 'synced' && (
                  <span className="text-xs font-semibold text-emerald-600">✓ Synced</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
