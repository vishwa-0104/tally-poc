import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { AlertTriangle, CheckCircle, Zap } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { mappingSchema, type MappingInput } from '@/lib/validators'
import type { Bill, TallyLedger } from '@/types'
import { formatCurrency } from '@/lib/utils'

/** Read-only badge shown when a ledger is auto-matched */
function MatchedBadge({ label, value, tag }: { label: string; value: string; tag?: string }) {
  return (
    <div className="mb-4">
      <div className="flex items-center justify-between mb-1.5">
        <span className="text-xs font-semibold text-gray-700 tracking-wide">{label}</span>
        {tag && (
          <span className="flex items-center gap-1 text-xs text-teal-600 font-medium">
            <Zap className="w-3 h-3" /> {tag}
          </span>
        )}
      </div>
      <div className="flex items-center gap-2 px-3 py-2 bg-teal-50 border border-teal-200 rounded-lg">
        <CheckCircle className="w-3.5 h-3.5 text-teal-500 flex-shrink-0" />
        <span className="text-sm text-teal-800 font-medium">{value}</span>
      </div>
    </div>
  )
}

interface MappingFormProps {
  bill: Bill
  ledgers: TallyLedger[]
  ledgersLoading: boolean
  saving: boolean
  syncing: boolean
  defaultMapping?: { purchase?: string; cgst?: string; sgst?: string; igst?: string } | null
  onSaveMapping: (data: MappingInput) => void
  onSyncToTally: (data: MappingInput) => void
}

export function MappingForm({
  bill,
  ledgers,
  ledgersLoading,
  saving,
  syncing,
  defaultMapping,
  onSaveMapping,
  onSyncToTally,
}: MappingFormProps) {
  const hasIgst = bill.igstAmount > 0

  // GSTIN-based auto-match for vendor
  const gstinMatch = bill.vendorGstin
    ? ledgers.find((l) => l.gstin && l.gstin.trim().toUpperCase() === bill.vendorGstin!.trim().toUpperCase())
    : null

  const vendorNameMatch = !gstinMatch && ledgers.some((l) => l.name === bill.vendorName)

  const resolvedVendor   = gstinMatch?.name ?? (vendorNameMatch ? bill.vendorName : '')
  const resolvedPurchase = defaultMapping?.purchase ?? ''
  const resolvedCgst     = defaultMapping?.cgst ?? ''
  const resolvedSgst     = defaultMapping?.sgst ?? ''
  const resolvedIgst     = defaultMapping?.igst ?? ''

  const {
    register,
    handleSubmit,
    setValue,
  } = useForm<MappingInput>({
    resolver: zodResolver(mappingSchema),
    defaultValues: {
      vendorLedger:   resolvedVendor   || undefined,
      purchaseLedger: resolvedPurchase || undefined,
      cgstLedger:     resolvedCgst     || undefined,
      sgstLedger:     resolvedSgst     || undefined,
      igstLedger:     resolvedIgst     || undefined,
      billDate:    bill.billDate,
      billNumber:  bill.billNumber,
      totalAmount: bill.totalAmount,
      lineItems:   bill.lineItems,
    },
  })

  // Sync resolved values into form whenever they change (ledgers may load after mount)
  useEffect(() => {
    if (resolvedVendor)   setValue('vendorLedger',   resolvedVendor)
    if (resolvedPurchase) setValue('purchaseLedger', resolvedPurchase)
    if (resolvedCgst)     setValue('cgstLedger',     resolvedCgst)
    if (resolvedSgst)     setValue('sgstLedger',     resolvedSgst)
    if (resolvedIgst)     setValue('igstLedger',     resolvedIgst)
  }, [resolvedVendor, resolvedPurchase, resolvedCgst, resolvedSgst, resolvedIgst]) // eslint-disable-line react-hooks/exhaustive-deps

  const anyMatched = resolvedVendor || resolvedPurchase || resolvedCgst || resolvedSgst || (hasIgst && resolvedIgst)

  return (
    <form onSubmit={handleSubmit(onSaveMapping)} noValidate>
      {/* Vendor status banner */}
      {gstinMatch && (
        <div className="flex gap-3 p-4 bg-teal-50 border border-teal-200 rounded-xl mb-5">
          <Zap className="w-5 h-5 text-teal-500 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-teal-800">Vendor auto-matched by GSTIN</p>
            <p className="text-xs text-teal-700 mt-0.5">
              GSTIN <span className="font-mono">{bill.vendorGstin}</span> matched ledger <span className="font-medium">"{gstinMatch.name}"</span>
            </p>
          </div>
        </div>
      )}

      {!gstinMatch && vendorNameMatch && (
        <div className="flex gap-3 p-4 bg-emerald-50 border border-emerald-200 rounded-xl mb-5">
          <CheckCircle className="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5" />
          <p className="text-sm font-medium text-emerald-800">Vendor ledger matched by name in Tally</p>
        </div>
      )}

      {!gstinMatch && !vendorNameMatch && !ledgersLoading && (
        <div className="flex gap-3 p-4 bg-amber-50 border border-amber-200 rounded-xl mb-5">
          <AlertTriangle className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-amber-800">Vendor ledger not found</p>
            <p className="text-xs text-amber-700 mt-0.5">
              No ledger matched for "{bill.vendorName}" (GSTIN: {bill.vendorGstin ?? 'N/A'}).
              Create it in Tally or re-sync ledgers.
            </p>
          </div>
        </div>
      )}

      {/* Matched ledger fields */}
      {anyMatched ? (
        <div className="grid grid-cols-2 gap-x-4 mt-5">
          {resolvedVendor   && <MatchedBadge label="Vendor Ledger"   value={resolvedVendor}   tag={gstinMatch ? 'GSTIN matched' : undefined} />}
          {resolvedPurchase && <MatchedBadge label="Purchase Ledger" value={resolvedPurchase} />}
          {resolvedCgst     && <MatchedBadge label="CGST Ledger"     value={resolvedCgst} />}
          {resolvedSgst     && <MatchedBadge label="SGST Ledger"     value={resolvedSgst} />}
          {hasIgst && resolvedIgst && <MatchedBadge label="IGST Ledger" value={resolvedIgst} />}
        </div>
      ) : (
        !ledgersLoading && (
          <p className="text-xs text-gray-500 mt-4">
            No ledgers matched. Go to Settings → configure default ledger mapping and sync ledgers from Tally.
          </p>
        )
      )}

      {/* Line items */}
      {bill.lineItems.length > 0 && (
        <div className="mt-5">
          <h3 className="text-sm font-bold text-gray-800 mb-3">Line Items <span className="text-gray-400 font-normal">(editable)</span></h3>
          <div className="overflow-x-auto rounded-xl border border-gray-200">
            <table className="w-full border-collapse text-xs" aria-label="Line items">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  {['Description', 'HSN', 'Qty', 'Unit', 'Unit Price', 'GST%', 'Amount'].map((h) => (
                    <th key={h} className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {bill.lineItems.map((_item, i) => (
                  <tr key={i} className="border-b border-gray-100 last:border-0">
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.description`)} className="w-full min-w-[140px] px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.hsnCode`)} className="w-20 px-2 py-1 text-xs font-mono border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.quantity`)} type="number" step="any" className="w-16 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.unit`)} className="w-14 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.unitPrice`)} type="number" step="any" className="w-24 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.gstRate`)} type="number" step="any" className="w-14 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.amount`)} type="number" step="any" className="w-24 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-gray-50 border-t-2 border-gray-200">
                <tr className="border-t border-gray-100">
                  <td colSpan={6} className="px-3 py-2 text-right text-xs font-medium text-gray-500">Raw Amount</td>
                  <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.subtotal)}</td>
                </tr>
                {!hasIgst && (
                  <>
                    <tr className="border-t border-gray-100">
                      <td colSpan={6} className="px-3 py-2 text-right text-xs font-medium text-gray-500">CGST</td>
                      <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.cgstAmount)}</td>
                    </tr>
                    <tr className="border-t border-gray-100">
                      <td colSpan={6} className="px-3 py-2 text-right text-xs font-medium text-gray-500">SGST</td>
                      <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.sgstAmount)}</td>
                    </tr>
                  </>
                )}
                {hasIgst && (
                  <tr className="border-t border-gray-100">
                    <td colSpan={6} className="px-3 py-2 text-right text-xs font-medium text-gray-500">IGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.igstAmount)}</td>
                  </tr>
                )}
                <tr className="border-t-2 border-gray-300">
                  <td colSpan={6} className="px-3 py-2 text-right text-xs font-bold text-gray-700">Total Amount</td>
                  <td className="px-3 py-2 text-xs font-bold text-teal-700">{formatCurrency(bill.totalAmount)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Submit */}
      <div className="flex justify-end mt-6">
        <div className="flex items-center gap-3">
          <Button type="submit" variant="outline" size="lg" loading={saving} disabled={syncing || !anyMatched}>
            {saving ? 'Saving…' : 'Save mapping'}
          </Button>
          <Button
            type="button"
            variant="teal"
            size="lg"
            loading={syncing}
            disabled={saving || !anyMatched}
            onClick={handleSubmit(onSyncToTally)}
          >
            {syncing ? 'Syncing to Tally…' : 'Sync to Tally'}
          </Button>
        </div>
      </div>
    </form>
  )
}
