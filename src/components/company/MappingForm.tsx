import { useEffect } from 'react'
import { useForm, Controller, useFieldArray } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { AlertTriangle, CheckCircle, Zap } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { mappingSchema, type MappingInput } from '@/lib/validators'
import type { Bill, TallyLedger } from '@/types'
import { cn, formatCurrency } from '@/lib/utils'

/** Free-text input with autocomplete from Tally ledgers (works even when list is empty) */
function LedgerInput({
  label,
  listId,
  ledgerOptions,
  error,
  disabled,
  autoMatched,
  value,
  onChange,
  onBlur,
  name,
}: {
  label: string
  listId: string
  ledgerOptions: { value: string; label: string }[]
  error?: string
  disabled?: boolean
  autoMatched?: boolean
  value: string | undefined
  onChange: (v: string) => void
  onBlur: () => void
  name: string
}) {
  return (
    <div className="mb-4">
      <div className="flex items-center justify-between mb-1.5">
        <label htmlFor={listId} className="block text-xs font-semibold text-gray-700 tracking-wide">
          {label}
        </label>
        {autoMatched && (
          <span className="flex items-center gap-1 text-xs text-teal-600 font-medium">
            <Zap className="w-3 h-3" /> GSTIN matched
          </span>
        )}
      </div>
      <input
        id={listId}
        name={name}
        list={`${listId}-list`}
        value={value ?? ''}
        onChange={(e) => onChange(e.target.value)}
        onBlur={onBlur}
        disabled={disabled}
        placeholder="Type or select ledger…"
        autoComplete="off"
        className={cn(
          'input-base',
          error && 'input-error',
          disabled && 'bg-gray-50 text-gray-500 cursor-not-allowed',
        )}
        aria-invalid={!!error}
      />
      <datalist id={`${listId}-list`}>
        {ledgerOptions.map((o) => (
          <option key={o.value} value={o.value} />
        ))}
      </datalist>
      {error && <p role="alert" className="text-xs text-red-600 mt-1">{error}</p>}
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
  const toOptions = (list: typeof ledgers) => list.map((l) => ({ value: l.name, label: l.name }))

  const byGroup = (keywords: string[]) =>
    toOptions(ledgers.filter((l) => keywords.some((kw) => l.group.toLowerCase().includes(kw.toLowerCase()))))

  const byName = (keywords: string[]) =>
    toOptions(ledgers.filter((l) => keywords.some((kw) => l.name.toLowerCase().includes(kw.toLowerCase()))))

  const vendorOptions   = byGroup(['sundry creditor', 'sundry debtor'])
  const purchaseOptions = byGroup(['purchase'])
  const cgstOptions     = byName(['cgst'])
  const sgstOptions     = byName(['sgst'])
  const igstOptions     = byName(['igst'])

  const opts = (filtered: ReturnType<typeof toOptions>) =>
    filtered.length > 0 ? filtered : toOptions(ledgers)

  // GSTIN-based auto-match — takes priority over name match
  const gstinMatch = bill.vendorGstin
    ? ledgers.find((l) => l.gstin && l.gstin.trim().toUpperCase() === bill.vendorGstin!.trim().toUpperCase())
    : null

  const vendorNameMatch = !gstinMatch && ledgers.some((l) => l.name === bill.vendorName)

  const resolvedVendor = gstinMatch?.name ?? (vendorNameMatch ? bill.vendorName : '')

  const {
    register,
    control,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<MappingInput>({
    resolver: zodResolver(mappingSchema),
    defaultValues: {
      vendorLedger:   resolvedVendor,
      purchaseLedger: defaultMapping?.purchase ?? '',
      cgstLedger:     defaultMapping?.cgst     ?? '',
      sgstLedger:     defaultMapping?.sgst     ?? '',
      igstLedger:     defaultMapping?.igst     ?? '',
      billDate:       bill.billDate,
      billNumber:     bill.billNumber,
      totalAmount:    bill.totalAmount,
      lineItems:      bill.lineItems,
    },
  })

  // Re-apply GSTIN match if ledgers load after mount
  useEffect(() => {
    if (gstinMatch) setValue('vendorLedger', gstinMatch.name)
  }, [gstinMatch?.name]) // eslint-disable-line react-hooks/exhaustive-deps

  const { fields } = useFieldArray({ control, name: 'lineItems' })

  const hasIgst = bill.igstAmount > 0

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
          <p className="text-sm font-medium text-emerald-800">Vendor ledger found by name in Tally</p>
        </div>
      )}

      {!gstinMatch && !vendorNameMatch && !ledgersLoading && (
        <div className="flex gap-3 p-4 bg-amber-50 border border-amber-200 rounded-xl mb-5">
          <AlertTriangle className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-amber-800">Vendor ledger not found in Tally</p>
            <p className="text-xs text-amber-700 mt-0.5">
              "{bill.vendorName}" has no matching ledger. Select one below or create it in Tally first.
            </p>
          </div>
        </div>
      )}

      {/* Ledger mapping */}
      <div className="grid grid-cols-2 gap-4 mt-5">
        <Controller
          name="vendorLedger"
          control={control}
          render={({ field }) => (
            <LedgerInput
              label="Vendor Ledger"
              listId="vendor-ledger"
              ledgerOptions={opts(vendorOptions)}
              error={errors.vendorLedger?.message}
              disabled={ledgersLoading || !!gstinMatch}
              autoMatched={!!gstinMatch}
              {...field}
              onChange={field.onChange}
            />
          )}
        />
        <Controller
          name="purchaseLedger"
          control={control}
          render={({ field }) => (
            <LedgerInput
              label="Purchase Ledger"
              listId="purchase-ledger"
              ledgerOptions={opts(purchaseOptions)}
              error={errors.purchaseLedger?.message}
              disabled={ledgersLoading || !!defaultMapping?.purchase}
              {...field}
              onChange={field.onChange}
            />
          )}
        />
        <Controller
          name="cgstLedger"
          control={control}
          render={({ field }) => (
            <LedgerInput
              label="CGST Ledger"
              listId="cgst-ledger"
              ledgerOptions={opts(cgstOptions)}
              error={errors.cgstLedger?.message}
              disabled={ledgersLoading || !!defaultMapping?.cgst}
              {...field}
              onChange={field.onChange}
            />
          )}
        />
        <Controller
          name="sgstLedger"
          control={control}
          render={({ field }) => (
            <LedgerInput
              label="SGST Ledger"
              listId="sgst-ledger"
              ledgerOptions={opts(sgstOptions)}
              error={errors.sgstLedger?.message}
              disabled={ledgersLoading || !!defaultMapping?.sgst}
              {...field}
              onChange={field.onChange}
            />
          )}
        />
        {hasIgst && (
          <Controller
            name="igstLedger"
            control={control}
            render={({ field }) => (
              <LedgerInput
                label="IGST Ledger"
                listId="igst-ledger"
                ledgerOptions={opts(igstOptions)}
                disabled={ledgersLoading || !!defaultMapping?.igst}
                {...field}
                onChange={field.onChange}
              />
            )}
          />
        )}
      </div>

      {/* Line items */}
      {fields.length > 0 && (
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
                {fields.map((field, i) => (
                  <tr key={field.id} className="border-b border-gray-100 last:border-0">
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
          <Button type="submit" variant="outline" size="lg" loading={saving} disabled={syncing}>
            {saving ? 'Saving…' : 'Save mapping'}
          </Button>
          <Button
            type="button"
            variant="teal"
            size="lg"
            loading={syncing}
            disabled={saving}
            onClick={handleSubmit(onSyncToTally)}
          >
            {syncing ? 'Syncing to Tally…' : 'Sync to Tally'}
          </Button>
        </div>
      </div>
    </form>
  )
}
