import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { AlertTriangle, CheckCircle, Zap } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { mappingSchema, type MappingInput } from '@/lib/validators'
import type { Bill, TallyLedger, LedgerMapping } from '@/types'
import { formatCurrency } from '@/lib/utils'


interface LedgerInputProps {
  id: string
  label: string
  required?: boolean
  matched?: boolean
  ledgers: TallyLedger[]
  pinnedNames?: string[]
  registration: ReturnType<ReturnType<typeof useForm<MappingInput>>['register']>
}

function LedgerInput({ id, label, required, matched, ledgers, pinnedNames = [], registration }: LedgerInputProps) {
  // Pinned names (from saved ledger sets) shown first, then remaining Tally ledgers
  const allNames = [
    ...pinnedNames,
    ...ledgers.map((l) => l.name).filter((n) => !pinnedNames.includes(n)),
  ]
  return (
    <div className="mb-4">
      <div className="flex items-center justify-between mb-1.5">
        <label className="block text-xs font-semibold text-gray-700 tracking-wide">
          {label}{required && ' *'}
        </label>
        {matched && (
          <span className="flex items-center gap-1 text-xs text-teal-600 font-medium">
            <CheckCircle className="w-3 h-3" /> matched
          </span>
        )}
      </div>
      <input
        {...registration}
        list={`${id}-list`}
        autoComplete="off"
        placeholder={`Type or select ${label}…`}
        className="input-base w-full"
      />
      <datalist id={`${id}-list`}>
        {allNames.map((name) => <option key={name} value={name} />)}
      </datalist>
    </div>
  )
}

interface MappingFormProps {
  bill: Bill
  ledgers: TallyLedger[]
  ledgersLoading: boolean
  stockItems: { name: string }[]
  saving: boolean
  syncing: boolean
  defaultMapping?: { purchase?: string; cgst?: string; sgst?: string; igst?: string } | null
  savedLedgerSets?: LedgerMapping | null
  onSaveMapping: (data: MappingInput) => void
  onSyncToTally: (data: MappingInput) => void
}

export function MappingForm({
  bill,
  ledgers,
  ledgersLoading,
  stockItems,
  saving,
  syncing,
  defaultMapping,
  savedLedgerSets,
  onSaveMapping,
  onSyncToTally,
}: MappingFormProps) {
  const hasIgst = bill.igstAmount > 0

  // Default round-off: use AI-parsed value if present, otherwise derive from totals
  const computedRoundOff = parseFloat(
    (bill.totalAmount - bill.subtotal - bill.cgstAmount - bill.sgstAmount - bill.igstAmount).toFixed(2)
  )
  const defaultRoundOff = bill.roundOffAmount ?? (Math.abs(computedRoundOff) >= 0.005 ? computedRoundOff : 0)

  const gstinMatch = bill.vendorGstin
    ? ledgers.find((l) => l.gstin && l.gstin.trim().toUpperCase() === bill.vendorGstin!.trim().toUpperCase())
    : null

  const vendorNameMatch = !gstinMatch && ledgers.some((l) => l.name === bill.vendorName)

  // Auto-detect from ledger group/name when defaultMapping not set
  const autoDetect = (filter: (l: TallyLedger) => boolean) => {
    const matches = ledgers.filter(filter)
    return matches.length === 1 ? matches[0].name : ''
  }

  const resolvedVendor   = gstinMatch?.name ?? (vendorNameMatch ? bill.vendorName : '')
  const resolvedPurchase = defaultMapping?.purchase
    || autoDetect((l) => l.group.toLowerCase().includes('purchase'))
  const resolvedCgst     = defaultMapping?.cgst
    || autoDetect((l) => l.name.toLowerCase().includes('cgst'))
  const resolvedSgst     = defaultMapping?.sgst
    || autoDetect((l) => l.name.toLowerCase().includes('sgst'))
  const resolvedIgst     = defaultMapping?.igst
    || autoDetect((l) => l.name.toLowerCase().includes('igst'))

  const {
    register,
    handleSubmit,
    setValue,
    watch,
  } = useForm<MappingInput>({
    resolver: zodResolver(mappingSchema),
    defaultValues: {
      vendorLedger:   resolvedVendor   || undefined,
      purchaseLedger: resolvedPurchase || undefined,
      cgstLedger:     resolvedCgst     || undefined,
      sgstLedger:     resolvedSgst     || undefined,
      igstLedger:     resolvedIgst     || undefined,
      billDate:       bill.billDate,
      billNumber:     bill.billNumber,
      totalAmount:    bill.totalAmount,
      roundOffAmount: defaultRoundOff,
      lineItems:      bill.lineItems,
    },
  })

  useEffect(() => {
    if (resolvedVendor)   setValue('vendorLedger',   resolvedVendor)
    if (resolvedPurchase) setValue('purchaseLedger', resolvedPurchase)
    if (resolvedCgst)     setValue('cgstLedger',     resolvedCgst)
    if (resolvedSgst)     setValue('sgstLedger',     resolvedSgst)
    if (resolvedIgst)     setValue('igstLedger',     resolvedIgst)
  }, [resolvedVendor, resolvedPurchase, resolvedCgst, resolvedSgst, resolvedIgst]) // eslint-disable-line react-hooks/exhaustive-deps

  const watchedPurchase = watch('purchaseLedger')
  const watchedCgst     = watch('cgstLedger')
  const watchedSgst     = watch('sgstLedger')
  const watchedIgst     = watch('igstLedger')

  // Sync requires purchase + (cgst+sgst for domestic, igst for interstate)
  const taxLedgersOk = hasIgst
    ? !!watchedIgst?.trim()
    : !!(watchedCgst?.trim() && watchedSgst?.trim())
  const canSync = !!watchedPurchase?.trim() && taxLedgersOk

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

      {/* Ledger fields — always editable inputs so RHF registers every field */}
      <div className="grid grid-cols-2 gap-x-4 mt-5">
        <LedgerInput id="vendor"   label="Vendor Ledger"   matched={!!resolvedVendor}   ledgers={ledgers} registration={register('vendorLedger')} />
        <LedgerInput id="purchase" label="Purchase Ledger" matched={!!resolvedPurchase} required ledgers={ledgers} pinnedNames={savedLedgerSets?.purchaseLedgers} registration={register('purchaseLedger')} />

        {/* CGST / SGST shown for domestic bills; IGST for interstate */}
        {!hasIgst && (
          <>
            <LedgerInput id="cgst" label="CGST Ledger" matched={!!resolvedCgst} required ledgers={ledgers} pinnedNames={savedLedgerSets?.cgstLedgers} registration={register('cgstLedger')} />
            <LedgerInput id="sgst" label="SGST Ledger" matched={!!resolvedSgst} required ledgers={ledgers} pinnedNames={savedLedgerSets?.sgstLedgers} registration={register('sgstLedger')} />
          </>
        )}
        {hasIgst && (
          <LedgerInput id="igst" label="IGST Ledger" matched={!!resolvedIgst} required ledgers={ledgers} pinnedNames={savedLedgerSets?.igstLedgers} registration={register('igstLedger')} />
        )}
      </div>

      {!canSync && !ledgersLoading && (
        <p className="text-xs text-amber-600 mt-1">
          Purchase and tax ledgers are required to sync. Configure them above or set defaults in Settings.
        </p>
      )}

      {/* Voucher number + Round Off */}
      <div className="mt-4 flex gap-6 flex-wrap">
        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
            Tally Voucher Number <span className="font-normal text-gray-400">(optional — leave blank for auto)</span>
          </label>
          <input
            {...register('voucherNumber')}
            placeholder="e.g. 1288"
            className="input-base w-48"
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
            Round Off <span className="font-normal text-gray-400">(₹ — negative to deduct)</span>
          </label>
          <input
            {...register('roundOffAmount')}
            type="number"
            step="0.01"
            placeholder="0.00"
            className="input-base w-32"
          />
        </div>
      </div>

      {/* Line items */}
      {bill.lineItems.length > 0 && (
        <div className="mt-5">
          <h3 className="text-sm font-bold text-gray-800 mb-3">Line Items <span className="text-gray-400 font-normal">(editable)</span></h3>
          <div className="overflow-x-auto rounded-xl border border-gray-200">
            <table className="w-full border-collapse text-xs" aria-label="Line items">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  {['Description', 'HSN', 'Qty', 'Unit', 'Unit Price', 'Disc%', 'GST%', 'Amount', 'Tally Item'].map((h) => (
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
                      <input {...register(`lineItems.${i}.hsnCode`)} className="w-20 px-2 py-1 text-xs font-mono border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-tally-400 focus:ring-teal-400" />
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
                      <input {...register(`lineItems.${i}.discountPercent`)} type="number" step="any" placeholder="0" className="w-14 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.gstRate`)} type="number" step="any" className="w-14 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.amount`)} type="number" step="any" className="w-24 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input
                        {...register(`lineItems.${i}.tallyStockItem`)}
                        list={`stock-items-list`}
                        autoComplete="off"
                        placeholder="Select stock item…"
                        className="w-40 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400"
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
              <datalist id="stock-items-list">
                {stockItems.map((item) => <option key={item.name} value={item.name} />)}
              </datalist>
              <tfoot className="bg-gray-50 border-t-2 border-gray-200">
                <tr className="border-t border-gray-100">
                  <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">Raw Amount</td>
                  <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.subtotal)}</td>
                </tr>
                {!hasIgst && (
                  <>
                    <tr className="border-t border-gray-100">
                      <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">CGST</td>
                      <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.cgstAmount)}</td>
                    </tr>
                    <tr className="border-t border-gray-100">
                      <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">SGST</td>
                      <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.sgstAmount)}</td>
                    </tr>
                  </>
                )}
                {hasIgst && (
                  <tr className="border-t border-gray-100">
                    <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">IGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.igstAmount)}</td>
                  </tr>
                )}
                <tr className="border-t border-gray-100">
                  <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">Round Off</td>
                  <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(defaultRoundOff)}</td>
                </tr>
                <tr className="border-t-2 border-gray-300">
                  <td colSpan={7} className="px-3 py-2 text-right text-xs font-bold text-gray-700">Total Amount</td>
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
          <Button type="submit" variant="outline" size="lg" loading={saving} disabled={syncing}>
            {saving ? 'Saving…' : 'Save mapping'}
          </Button>
          <Button
            type="button"
            variant="teal"
            size="lg"
            loading={syncing}
            disabled={saving || !canSync}
            onClick={handleSubmit(onSyncToTally, (errors) => console.error('[MappingForm] Sync validation failed:', errors))}
          >
            {syncing ? 'Syncing to Tally…' : 'Sync to Tally'}
          </Button>
        </div>
      </div>
    </form>
  )
}
