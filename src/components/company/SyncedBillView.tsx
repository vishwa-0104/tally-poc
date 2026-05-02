import type { Bill } from '@/types'
import { formatCurrency, formatDate } from '@/lib/utils'

interface SyncedBillViewProps {
  bill: Bill
}

function Row({ label, value }: { label: string; value?: string | null }) {
  if (!value) return null
  return (
    <div className="flex flex-col gap-0.5">
      <span className="text-[10px] font-semibold text-gray-500 uppercase tracking-wide">{label}</span>
      <span className="text-xs font-medium text-gray-800 break-all">{value}</span>
    </div>
  )
}

export function SyncedBillView({ bill }: SyncedBillViewProps) {
  const isInterstate = bill.igstAmount > 0
  const isMisc       = bill.billType === 'misc'
  const mapping      = bill.tallyMapping

  return (
    <div className="space-y-5">
      {/* Bill details */}
      <div className="card p-5">
        <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Bill Details</p>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-x-6 gap-y-2">
          <Row label="Bill Number"   value={bill.billNumber} />
          <Row label="Bill Date"     value={formatDate(bill.billDate)} />
          <Row label="Vendor"        value={bill.vendorName} />
          <Row label="Vendor GSTIN"  value={bill.vendorGstin} />
          <Row label="Total Amount"  value={formatCurrency(bill.totalAmount)} />
          {bill.syncedAt && <Row label="Synced At" value={formatDate(bill.syncedAt)} />}
        </div>
      </div>

      {/* Ledger mapping */}
      {mapping && (
        <div className="card p-5">
          <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Ledger Mapping</p>
          <div className="space-y-2">
            <Row label="Vendor Ledger"   value={mapping.vendorLedger} />
            {!isMisc && <Row label="Purchase Ledger" value={mapping.purchaseLedger} />}
            {!isInterstate && <Row label="CGST Ledger" value={mapping.cgstLedger} />}
            {!isInterstate && <Row label="SGST Ledger" value={mapping.sgstLedger} />}
            {isInterstate  && <Row label="IGST Ledger" value={mapping.igstLedger} />}
          </div>
        </div>
      )}

      {/* Misc expense lines */}
      {isMisc && bill.lineItems.length > 0 && (
        <div className="card overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-100">
            <p className="text-xs font-bold text-gray-700 uppercase tracking-wide">Expense Lines</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-xs">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  {['Description', 'Amount', 'Expense Ledger'].map((h) => (
                    <th key={h} className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {bill.lineItems.map((item, i) => (
                  <tr key={i} className="border-b border-gray-100 last:border-0">
                    <td className="px-3 py-2 text-gray-800">{item.description}</td>
                    <td className="px-3 py-2 font-semibold text-gray-800">{formatCurrency(item.amount)}</td>
                    <td className="px-3 py-2 text-gray-600">{item.tallyLedger ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-gray-50 border-t-2 border-gray-200">
                <tr>
                  <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">Subtotal</td>
                  <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.subtotal)}</td>
                  <td />
                </tr>
                {!isInterstate && bill.cgstAmount > 0 && (
                  <tr>
                    <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">CGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.cgstAmount)}</td>
                    <td />
                  </tr>
                )}
                {!isInterstate && bill.sgstAmount > 0 && (
                  <tr>
                    <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">SGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.sgstAmount)}</td>
                    <td />
                  </tr>
                )}
                {isInterstate && bill.igstAmount > 0 && (
                  <tr>
                    <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">IGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.igstAmount)}</td>
                    <td />
                  </tr>
                )}
                {bill.roundOffAmount != null && Math.abs(bill.roundOffAmount) >= 0.01 && (
                  <tr>
                    <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">Round Off</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.roundOffAmount)}</td>
                    <td />
                  </tr>
                )}
                <tr className="border-t-2 border-gray-300">
                  <td className="px-3 py-2 text-right text-xs font-bold text-gray-700">Total Amount</td>
                  <td className="px-3 py-2 text-xs font-bold text-teal-700">{formatCurrency(bill.totalAmount)}</td>
                  <td />
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Purchase line items */}
      {!isMisc && bill.lineItems.length > 0 && (
        <div className="card overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-100">
            <p className="text-xs font-bold text-gray-700 uppercase tracking-wide">Line Items</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-xs">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  {['Description', 'HSN', 'Qty', 'Unit', 'Unit Price', 'Disc%', 'GST%', 'Amount', 'Tally Item'].map((h) => (
                    <th key={h} className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {bill.lineItems.map((item, i) => (
                  <tr key={i} className="border-b border-gray-100 last:border-0">
                    <td className="px-3 py-2 text-gray-800">{item.description}</td>
                    <td className="px-3 py-2 font-mono text-gray-600">{item.hsnCode}</td>
                    <td className="px-3 py-2 text-gray-700">{item.quantity}</td>
                    <td className="px-3 py-2 text-gray-700">{item.unit}</td>
                    <td className="px-3 py-2 text-gray-700">{formatCurrency(item.unitPrice)}</td>
                    <td className="px-3 py-2 text-gray-700">{item.discountPercent ?? 0}</td>
                    <td className="px-3 py-2 text-gray-700">{item.gstRate}%</td>
                    <td className="px-3 py-2 font-semibold text-gray-800">{formatCurrency(item.amount)}</td>
                    <td className="px-3 py-2 text-gray-600">{item.tallyStockItem ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-gray-50 border-t-2 border-gray-200">
                <tr>
                  <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">Taxable Amount</td>
                  <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.subtotal)}</td>
                  <td />
                </tr>
                {!isInterstate && bill.cgstAmount > 0 && (
                  <tr>
                    <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">CGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.cgstAmount)}</td>
                    <td />
                  </tr>
                )}
                {!isInterstate && bill.sgstAmount > 0 && (
                  <tr>
                    <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">SGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.sgstAmount)}</td>
                    <td />
                  </tr>
                )}
                {isInterstate && bill.igstAmount > 0 && (
                  <tr>
                    <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">IGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.igstAmount)}</td>
                    <td />
                  </tr>
                )}
                {bill.roundOffAmount != null && Math.abs(bill.roundOffAmount) >= 0.01 && (
                  <tr>
                    <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">Round Off</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.roundOffAmount)}</td>
                    <td />
                  </tr>
                )}
                <tr className="border-t-2 border-gray-300">
                  <td colSpan={7} className="px-3 py-2 text-right text-xs font-bold text-gray-700">Total Amount</td>
                  <td className="px-3 py-2 text-xs font-bold text-teal-700">{formatCurrency(bill.totalAmount)}</td>
                  <td />
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
