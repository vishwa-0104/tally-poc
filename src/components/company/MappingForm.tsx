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
  savedLedgerSets?: LedgerMapping | null
  nextVoucherNumber?: string
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
  savedLedgerSets,
  nextVoucherNumber,
  onSaveMapping,
  onSyncToTally,
}: MappingFormProps) {

  // ── Determine tax type ──────────────────────────────────────────────────────
  const isInterstate = bill.igstAmount > 0

  // ── Derive rate buckets from line items ─────────────────────────────────────
  const ratesPresent = new Set(bill.lineItems.map((i) => i.gstRate))
  let show5      = ratesPresent.has(5)
  let show18     = ratesPresent.has(18)
  let showExempt = ratesPresent.has(0)

  // Fallback: when line items are absent or carry no recognised rate, infer from bill totals
  if (!show5 && !show18 && !showExempt) {
    const totalTax    = bill.cgstAmount + bill.sgstAmount + bill.igstAmount
    const effectiveRate = bill.subtotal > 0 ? Math.round(totalTax / bill.subtotal * 100) : 0
    if (totalTax === 0)        showExempt = true
    else if (effectiveRate <= 7) show5    = true   // ~5 %
    else                         show18   = true   // ~18 %
  }

  // Safety: always show at least one field
  if (!show5 && !show18 && !showExempt) showExempt = true

  // ── Pre-fill values from company mapping ────────────────────────────────────
  const prefillPurchase5      = isInterstate ? savedLedgerSets?.purchase_interstate_5  : savedLedgerSets?.purchase_up_5
  const prefillPurchase18     = isInterstate ? savedLedgerSets?.purchase_interstate_18 : savedLedgerSets?.purchase_up_18
  const prefillPurchaseExempt = savedLedgerSets?.purchase_exempt
  const prefillCgst5          = savedLedgerSets?.input_cgst_2_5
  const prefillSgst5          = savedLedgerSets?.input_sgst_2_5
  const prefillCgst18         = savedLedgerSets?.input_cgst_9
  const prefillSgst18         = savedLedgerSets?.input_sgst_9
  const prefillIgst5          = savedLedgerSets?.igst_5
  const prefillIgst18         = savedLedgerSets?.igst_18

  // ── Vendor matching ─────────────────────────────────────────────────────────
  const gstinMatch = bill.vendorGstin
    ? ledgers.find((l) => l.gstin && l.gstin.trim().toUpperCase() === bill.vendorGstin!.trim().toUpperCase())
    : null
  const vendorNameMatch = !gstinMatch && ledgers.some((l) => l.name === bill.vendorName)
  const resolvedVendor  = gstinMatch?.name ?? (vendorNameMatch ? bill.vendorName : '')

  // ── Round-off ───────────────────────────────────────────────────────────────
  // Use AI-extracted value if present; otherwise derive from the bill's own totals.
  // Only treat as meaningful when the absolute value is ≥ ₹0.01.
  const computedRoundOff = parseFloat(
    (bill.totalAmount - bill.subtotal - bill.cgstAmount - bill.sgstAmount - bill.igstAmount).toFixed(2)
  )
  const roundOffValue  = bill.roundOffAmount ?? (Math.abs(computedRoundOff) >= 0.01 ? computedRoundOff : null)
  const hasRoundOff    = roundOffValue !== null && Math.abs(roundOffValue) >= 0.01

  // ── Form ────────────────────────────────────────────────────────────────────
  const { register, handleSubmit, setValue, watch } = useForm<MappingInput>({
    resolver: zodResolver(mappingSchema),
    defaultValues: {
      vendorLedger:          resolvedVendor || undefined,
      purchaseLedger_5:      show5      ? prefillPurchase5      || undefined : undefined,
      purchaseLedger_18:     show18     ? prefillPurchase18     || undefined : undefined,
      purchaseLedger_exempt: showExempt ? prefillPurchaseExempt || undefined : undefined,
      cgstLedger_5:  !isInterstate && show5  ? prefillCgst5  || undefined : undefined,
      sgstLedger_5:  !isInterstate && show5  ? prefillSgst5  || undefined : undefined,
      cgstLedger_18: !isInterstate && show18 ? prefillCgst18 || undefined : undefined,
      sgstLedger_18: !isInterstate && show18 ? prefillSgst18 || undefined : undefined,
      igstLedger_5:  isInterstate  && show5  ? prefillIgst5  || undefined : undefined,
      igstLedger_18: isInterstate  && show18 ? prefillIgst18 || undefined : undefined,
      billDate:       bill.billDate,
      billNumber:     bill.billNumber,
      totalAmount:    bill.totalAmount,
      roundOffAmount: hasRoundOff ? roundOffValue! : undefined,
      lineItems:      bill.lineItems,
    },
  })

  // Re-fill when ledger sets or vendor resolve after async load
  useEffect(() => {
    if (resolvedVendor) setValue('vendorLedger', resolvedVendor)

    if (show5      && prefillPurchase5)      setValue('purchaseLedger_5',      prefillPurchase5)
    if (show18     && prefillPurchase18)     setValue('purchaseLedger_18',     prefillPurchase18)
    if (showExempt && prefillPurchaseExempt) setValue('purchaseLedger_exempt', prefillPurchaseExempt)

    if (!isInterstate) {
      if (show5  && prefillCgst5)  setValue('cgstLedger_5',  prefillCgst5)
      if (show5  && prefillSgst5)  setValue('sgstLedger_5',  prefillSgst5)
      if (show18 && prefillCgst18) setValue('cgstLedger_18', prefillCgst18)
      if (show18 && prefillSgst18) setValue('sgstLedger_18', prefillSgst18)
    } else {
      if (show5  && prefillIgst5)  setValue('igstLedger_5',  prefillIgst5)
      if (show18 && prefillIgst18) setValue('igstLedger_18', prefillIgst18)
    }
  }, [resolvedVendor, savedLedgerSets]) // eslint-disable-line react-hooks/exhaustive-deps

  // ── Can-sync guard ──────────────────────────────────────────────────────────
  const wP5  = watch('purchaseLedger_5')
  const wP18 = watch('purchaseLedger_18')
  const wPEx = watch('purchaseLedger_exempt')
  const wC5  = watch('cgstLedger_5');  const wS5  = watch('sgstLedger_5')
  const wC18 = watch('cgstLedger_18'); const wS18 = watch('sgstLedger_18')
  const wI5  = watch('igstLedger_5');  const wI18 = watch('igstLedger_18')

  const purchaseOk = (!show5 || !!wP5?.trim()) && (!show18 || !!wP18?.trim()) && (!showExempt || !!wPEx?.trim())
  const taxOk = isInterstate
    ? (!show5 || !!wI5?.trim()) && (!show18 || !!wI18?.trim())
    : (!show5 || (!!wC5?.trim() && !!wS5?.trim())) && (!show18 || (!!wC18?.trim() && !!wS18?.trim()))
  const canSync = purchaseOk && ((!show5 && !show18) || taxOk)

  // All ledger options for datalist
  const allLedgerNames = ledgers.map((l) => l.name)

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

      {/* ── Vendor ── */}
      <div className="mt-5">
        <LedgerInput
          id="vendor"
          label="Vendor Ledger"
          matched={!!resolvedVendor}
          ledgers={ledgers}
          registration={register('vendorLedger')}
        />
      </div>

      {/* ── Purchase Ledgers ── */}
      <div className="mt-2">
        <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Purchase Ledgers</p>
        <div className="grid grid-cols-2 gap-x-4">
          {show5 && (
            <LedgerInput
              id="purchase-5"
              label="Purchase Ledger (5%)"
              required
              ledgers={ledgers}
              pinnedNames={prefillPurchase5 ? [prefillPurchase5] : []}
              registration={register('purchaseLedger_5')}
            />
          )}
          {show18 && (
            <LedgerInput
              id="purchase-18"
              label="Purchase Ledger (18%)"
              required
              ledgers={ledgers}
              pinnedNames={prefillPurchase18 ? [prefillPurchase18] : []}
              registration={register('purchaseLedger_18')}
            />
          )}
          {showExempt && (
            <LedgerInput
              id="purchase-exempt"
              label="Purchase Ledger (Exempt)"
              ledgers={ledgers}
              pinnedNames={prefillPurchaseExempt ? [prefillPurchaseExempt] : []}
              registration={register('purchaseLedger_exempt')}
            />
          )}
        </div>
      </div>

      {/* ── CGST / SGST (intra-state) ── */}
      {!isInterstate && (show5 || show18) && (
        <div className="mt-2">
          <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">CGST / SGST</p>
          <div className="grid grid-cols-2 gap-x-4">
            {show5 && (
              <>
                <LedgerInput
                  id="cgst-5"
                  label="CGST (5%)"
                  required
                  ledgers={ledgers}
                  pinnedNames={prefillCgst5 ? [prefillCgst5] : []}
                  registration={register('cgstLedger_5')}
                />
                <LedgerInput
                  id="sgst-5"
                  label="SGST (5%)"
                  required
                  ledgers={ledgers}
                  pinnedNames={prefillSgst5 ? [prefillSgst5] : []}
                  registration={register('sgstLedger_5')}
                />
              </>
            )}
            {show18 && (
              <>
                <LedgerInput
                  id="cgst-18"
                  label="CGST (18%)"
                  required
                  ledgers={ledgers}
                  pinnedNames={prefillCgst18 ? [prefillCgst18] : []}
                  registration={register('cgstLedger_18')}
                />
                <LedgerInput
                  id="sgst-18"
                  label="SGST (18%)"
                  required
                  ledgers={ledgers}
                  pinnedNames={prefillSgst18 ? [prefillSgst18] : []}
                  registration={register('sgstLedger_18')}
                />
              </>
            )}
          </div>
        </div>
      )}

      {/* ── IGST (interstate) ── */}
      {isInterstate && (show5 || show18) && (
        <div className="mt-2">
          <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">IGST</p>
          <div className="grid grid-cols-2 gap-x-4">
            {show5 && (
              <LedgerInput
                id="igst-5"
                label="IGST (5%)"
                required
                ledgers={ledgers}
                pinnedNames={prefillIgst5 ? [prefillIgst5] : []}
                registration={register('igstLedger_5')}
              />
            )}
            {show18 && (
              <LedgerInput
                id="igst-18"
                label="IGST (18%)"
                required
                ledgers={ledgers}
                pinnedNames={prefillIgst18 ? [prefillIgst18] : []}
                registration={register('igstLedger_18')}
              />
            )}
          </div>
        </div>
      )}

      {!canSync && !ledgersLoading && (
        <p className="text-xs text-amber-600 mt-1">
          Fill all required purchase and tax ledgers to enable sync.
        </p>
      )}

      {/* Voucher number + Round Off */}
      <div className="mt-4 flex gap-6 flex-wrap">
        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
            Tally Voucher Number
          </label>
          <div className="input-base w-48 bg-gray-50 text-gray-500 cursor-not-allowed select-none">
            {nextVoucherNumber ?? `${bill.billNumber}_1`}
          </div>
          <p className="text-xs text-gray-400 mt-1">Auto-assigned on sync</p>
        </div>
        {hasRoundOff && (
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
        )}
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
                        list="stock-items-list"
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
              <datalist id="all-ledgers-list">
                {allLedgerNames.map((name) => <option key={name} value={name} />)}
              </datalist>
              <tfoot className="bg-gray-50 border-t-2 border-gray-200">
                <tr className="border-t border-gray-100">
                  <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">Raw Amount</td>
                  <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.subtotal)}</td>
                </tr>
                {!isInterstate && (
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
                {isInterstate && (
                  <tr className="border-t border-gray-100">
                    <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">IGST</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.igstAmount)}</td>
                  </tr>
                )}
                {hasRoundOff && (
                  <tr className="border-t border-gray-100">
                    <td colSpan={7} className="px-3 py-2 text-right text-xs font-medium text-gray-500">Round Off</td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(roundOffValue!)}</td>
                  </tr>
                )}
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
          <Button type="submit" variant="outline" loading={saving} disabled={syncing} className="whitespace-nowrap px-6 py-2.5">
            {saving ? 'Saving…' : 'Save mapping'}
          </Button>
          <Button
            type="button"
            variant="teal"
            loading={syncing}
            disabled={saving || !canSync}
            className="whitespace-nowrap px-6 py-2.5"
            onClick={handleSubmit(onSyncToTally, (errors) => console.error('[MappingForm] Sync validation failed:', errors))}
          >
            {syncing ? 'Pushing to Tally…' : 'Push to Tally'}
          </Button>
        </div>
      </div>
    </form>
  )
}
