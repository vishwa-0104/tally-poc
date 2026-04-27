import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { AlertTriangle, CheckCircle, Plus, Zap } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { CreateStockItemModal } from '@/components/company/CreateStockItemModal'
import { mappingSchema, type MappingInput } from '@/lib/validators'
import type { Bill, TallyGodown, TallyLedger, TallyStockUnit, LedgerMapping, StockItemAlias } from '@/types'
import { formatCurrency, decodeHtmlEntities } from '@/lib/utils'


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

interface TallyItemCellProps {
  index: number
  register: ReturnType<typeof useForm<MappingInput>>['register']
  watch: ReturnType<typeof useForm<MappingInput>>['watch']
  onCreateClick: () => void
}

function TallyItemCell({ index, register, watch, onCreateClick }: TallyItemCellProps) {
  const value = watch(`lineItems.${index}.tallyStockItem`)
  const isEmpty = !value?.trim()
  return (
    <div className="flex items-center gap-1">
      <input
        {...register(`lineItems.${index}.tallyStockItem`)}
        list="stock-items-list"
        autoComplete="off"
        placeholder="Select stock item…"
        className="w-52 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400"
      />
      {isEmpty && (
        <button
          type="button"
          title="Create new stock item in Tally"
          onClick={onCreateClick}
          className="flex-shrink-0 w-5 h-5 flex items-center justify-center rounded border border-teal-400 text-teal-600 hover:bg-teal-50 transition-colors"
        >
          <Plus className="w-3 h-3" />
        </button>
      )}
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
  stockItemAliases?: StockItemAlias[]
  companyId: string
  tallyUrl: string
  tallyCompany?: string
  godownEnabled?: boolean
  godowns?: TallyGodown[]
  stockUnits?: TallyStockUnit[]
  billType?: 'purchase' | 'misc'
  onSaveMapping: (data: MappingInput) => void
  onSyncToTally: (data: MappingInput) => void
}

export function MappingForm({
  bill,
  ledgers: rawLedgers,
  ledgersLoading,
  stockItems,
  saving,
  syncing,
  savedLedgerSets,
  nextVoucherNumber,
  stockItemAliases = [],
  companyId,
  tallyUrl,
  tallyCompany = '',
  godownEnabled = false,
  godowns = [],
  stockUnits = [],
  billType = 'purchase' as const,
  onSaveMapping,
  onSyncToTally,
}: MappingFormProps) {
  const [createItemRowIndex, setCreateItemRowIndex] = useState<number | null>(null)

  // Decode HTML entities in ledger names from existing DB data (&amp; → &, etc.)
  const ledgers = rawLedgers.map((l) => ({
    ...l,
    name:  decodeHtmlEntities(l.name),
    gstin: l.gstin ? decodeHtmlEntities(l.gstin) : l.gstin,
  }))

  // ── Determine tax type ──────────────────────────────────────────────────────
  const isInterstate = bill.igstAmount > 0

  // ── Derive rate buckets ──────────────────────────────────────────────────────
  // Misc bill line items always carry gstRate=0 (expense entries) so line item
  // rates are unreliable for misc — always use bill-level tax totals instead.
  let show5: boolean
  let show18: boolean
  let showExempt: boolean

  if (billType === 'misc') {
    const totalTax      = bill.cgstAmount + bill.sgstAmount + bill.igstAmount
    const effectiveRate = bill.subtotal > 0 ? Math.round(totalTax / bill.subtotal * 100) : 0
    show5      = totalTax > 0 && effectiveRate <= 7
    show18     = totalTax > 0 && effectiveRate > 7
    showExempt = totalTax === 0
  } else {
    const ratesPresent = new Set(bill.lineItems.map((i) => i.gstRate))
    show5      = ratesPresent.has(5)
    show18     = ratesPresent.has(18)
    showExempt = ratesPresent.has(0)

    // Fallback: when line items carry no recognised rate, infer from bill totals
    if (!show5 && !show18 && !showExempt) {
      const totalTax      = bill.cgstAmount + bill.sgstAmount + bill.igstAmount
      const effectiveRate = bill.subtotal > 0 ? Math.round(totalTax / bill.subtotal * 100) : 0
      if (totalTax === 0)          showExempt = true
      else if (effectiveRate <= 7) show5      = true
      else                         show18     = true
    }

    // Safety: always show at least one field
    if (!show5 && !show18 && !showExempt) showExempt = true
  }

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

  const exactNameMatch = !gstinMatch
    ? ledgers.find((l) => l.name.toLowerCase() === bill.vendorName.toLowerCase())
    : null

  const resolvedVendor = gstinMatch?.name ?? exactNameMatch?.name ?? ''

  // ── Round-off ───────────────────────────────────────────────────────────────
  const roundOffValue = (bill.roundOffAmount != null && Math.abs(bill.roundOffAmount) >= 0.01)
    ? bill.roundOffAmount
    : null
  const hasRoundOff = roundOffValue !== null

  // ── Invoice-level discount ───────────────────────────────────────────────────
  const hasInvoiceDiscount = bill.invoiceDiscountAmount != null && bill.invoiceDiscountAmount > 0

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
      voucherDate:    new Date().toISOString().split('T')[0],
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

  // Pre-fill unit for each line item:
  // keep the AI-parsed value if present, otherwise default to the first Tally stock unit.
  useEffect(() => {
    if (!stockUnits.length) return
    bill.lineItems.forEach((_item, i) => {
      const current = (watch(`lineItems.${i}.unit`) ?? '').trim()
      if (!current) {
        setValue(`lineItems.${i}.unit`, stockUnits[0].name)
      }
    })
  }, [stockUnits]) // eslint-disable-line react-hooks/exhaustive-deps

  // Auto-populate tallyStockItem from saved aliases (case-insensitive match on description)
  useEffect(() => {
    if (!stockItemAliases.length) return
    bill.lineItems.forEach((item, i) => {
      const alias = stockItemAliases.find(
        (a) => a.billItemName === item.description.trim().toLowerCase()
      )
      if (alias) setValue(`lineItems.${i}.tallyStockItem`, alias.tallyStockItemName)
    })
  }, [stockItemAliases]) // eslint-disable-line react-hooks/exhaustive-deps

  // ── Can-sync guard ──────────────────────────────────────────────────────────
  const wP5  = watch('purchaseLedger_5')
  const wP18 = watch('purchaseLedger_18')
  const wPEx = watch('purchaseLedger_exempt')
  const wC5  = watch('cgstLedger_5');  const wS5  = watch('sgstLedger_5')
  const wC18 = watch('cgstLedger_18'); const wS18 = watch('sgstLedger_18')
  const wI5  = watch('igstLedger_5');  const wI18 = watch('igstLedger_18')

  const watchedLineItems = watch('lineItems')
  const watchedRoundOff  = watch('roundOffAmount')

  // Round off mismatch check — expected = totalAmount − (subtotal + taxes)
  // Same formula used server-side when correcting the AI-parsed sign.
  let roundOffSuggestion: number | null = null
  if (hasRoundOff) {
    const recomputedSubtotal = (watchedLineItems ?? bill.lineItems)
      .reduce((sum, item) => sum + (Number(item.amount) || 0), 0)
    const net      = recomputedSubtotal + bill.cgstAmount + bill.sgstAmount + bill.igstAmount
    const expected = parseFloat((bill.totalAmount + (bill.invoiceDiscountAmount ?? 0) - net).toFixed(2))
    if (Math.abs(expected - Number(watchedRoundOff)) >= 0.01) {
      roundOffSuggestion = expected
    }
  }

  const purchaseOk = billType === 'misc'
    ? true
    : (!show5 || !!wP5?.trim()) && (!show18 || !!wP18?.trim()) && (!showExempt || !!wPEx?.trim())
  const taxOk = isInterstate
    ? (!show5 || !!wI5?.trim()) && (!show18 || !!wI18?.trim())
    : (!show5 || (!!wC5?.trim() && !!wS5?.trim())) && (!show18 || (!!wC18?.trim() && !!wS18?.trim()))
  const miscExpenseLedgersOk = billType !== 'misc'
    || (watchedLineItems ?? bill.lineItems).every((item) => item.tallyLedger?.trim())
  const canSync = purchaseOk && ((!show5 && !show18) || taxOk) && miscExpenseLedgersOk

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

      {!gstinMatch && exactNameMatch && (
        <div className="flex gap-3 p-4 bg-emerald-50 border border-emerald-200 rounded-xl mb-5">
          <CheckCircle className="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5" />
          <p className="text-sm font-medium text-emerald-800">Vendor ledger matched by name in Tally</p>
        </div>
      )}

      {!gstinMatch && !exactNameMatch && !ledgersLoading && (
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

      {billType !== 'misc' && (
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
      )}

      {/* ── CGST / SGST (intra-state) ── */}
      {!isInterstate && (show5 || show18) && (
        <div className="mt-2">
          <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">CGST / SGST</p>
          <div className="grid grid-cols-2 gap-x-4">
            {show5 && (
              <>
                <LedgerInput
                  id="cgst-5"
                  label="CGST (2.5%)"
                  required
                  ledgers={ledgers}
                  pinnedNames={prefillCgst5 ? [prefillCgst5] : []}
                  registration={register('cgstLedger_5')}
                />
                <LedgerInput
                  id="sgst-5"
                  label="SGST (2.5%)"
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
                  label="CGST (9%)"
                  required
                  ledgers={ledgers}
                  pinnedNames={prefillCgst18 ? [prefillCgst18] : []}
                  registration={register('cgstLedger_18')}
                />
                <LedgerInput
                  id="sgst-18"
                  label="SGST (9%)"
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

      {/* ── Godown (admin-enabled feature) ── */}
      {billType !== 'misc' && godownEnabled && (
        <div className="mt-2">
          <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Godown</p>
          <div className="w-1/2 pr-2">
            <div className="mb-4">
              <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">Godown Name</label>
              <input
                {...register('godownName')}
                list="godowns-list"
                autoComplete="off"
                placeholder="Select or type godown…"
                className="input-base w-full"
              />
              <datalist id="godowns-list">
                {godowns.map((g) => <option key={g.name} value={g.name} />)}
              </datalist>
              <p className="text-xs text-gray-500 mt-1">Applied to all line items in this bill.</p>
            </div>
          </div>
        </div>
      )}

      {!canSync && !ledgersLoading && (
        <p className="text-xs text-amber-600 mt-1">
          {billType === 'misc' && !miscExpenseLedgersOk
            ? 'Select an expense ledger for each row to enable sync.'
            : 'Fill all required purchase and tax ledgers to enable sync.'}
        </p>
      )}

      {/* Bill Details */}
      <div className="mt-5">
        <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Bill Details</p>
        <div className="grid grid-cols-3 gap-x-4 gap-y-0">
          <div className="mb-4">
            <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">Bill Number *</label>
            <input
              {...register('billNumber')}
              type="text"
              placeholder="e.g. INV-001"
              className="input-base w-full"
            />
          </div>
          <div className="mb-4">
            <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">Bill Date *</label>
            <input
              {...register('billDate')}
              type="date"
              className="input-base w-full"
            />
          </div>
          <div className="mb-4">
            <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">Total Amount *</label>
            <input
              {...register('totalAmount')}
              type="number"
              step="0.01"
              placeholder="0.00"
              className="input-base w-full"
            />
          </div>
        </div>
      </div>

      {/* Voucher number + Voucher Date + Round Off */}
      <div className="mt-2 flex gap-6 flex-wrap">
        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
            Tally Voucher Number
          </label>
          <div className="input-base w-48 bg-gray-50 text-gray-500 cursor-not-allowed select-none">
            {nextVoucherNumber ?? `${bill.billNumber}_1`}
          </div>
          <p className="text-xs text-gray-500 mt-1">Auto-assigned on sync</p>
        </div>
        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
            Tally Voucher Date
          </label>
          <input
            {...register('voucherDate')}
            type="date"
            className="input-base w-40"
          />
          <p className="text-xs text-gray-500 mt-1">Entry date in Tally (<span className="font-mono">DATE</span>)</p>
        </div>
        {hasRoundOff && (
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
              Round Off <span className="font-normal text-gray-500">(₹ — negative to deduct)</span>
            </label>
            <input
              {...register('roundOffAmount')}
              type="number"
              step="0.01"
              placeholder="0.00"
              className="input-base w-32"
            />
            {roundOffSuggestion !== null && (
              <p className="text-xs text-amber-600 mt-1">
                Value seems incorrect, try ₹{roundOffSuggestion}
              </p>
            )}
          </div>
        )}
        {hasInvoiceDiscount && (
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
              Discount Ledger <span className="font-normal text-gray-500">(₹{bill.invoiceDiscountAmount?.toFixed(2)})</span>
            </label>
            <input
              {...register('discountLedger')}
              list="discount-ledger-list"
              autoComplete="off"
              placeholder="Select discount ledger…"
              className="input-base w-52"
            />
            <datalist id="discount-ledger-list">
              {allLedgerNames.map((name) => <option key={name} value={name} />)}
            </datalist>
            <p className="text-xs text-gray-500 mt-1">Invoice-level discount of ₹{bill.invoiceDiscountAmount?.toFixed(2)}</p>
          </div>
        )}
      </div>

      {/* Line items — purchase bill: editable stock item table */}
      {billType !== 'misc' && bill.lineItems.length > 0 && (
        <div className="mt-5">
          <h3 className="text-sm font-bold text-gray-800 mb-3">Line Items <span className="text-gray-500 font-normal">(editable)</span></h3>
          <div className="overflow-x-auto rounded-xl border border-gray-200">
            <table className="w-full border-collapse text-xs" aria-label="Line items">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider min-w-[380px]">Description</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">HSN</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">Qty</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">Unit</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">Unit Price</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">Disc%</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">GST%</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">Amount</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider min-w-[220px]">Tally Item</th>
                </tr>
              </thead>
              <tbody>
                {bill.lineItems.map((_item, i) => (
                  <tr key={i} className="border-b border-gray-100 last:border-0">
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.description`)} className="w-full px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.hsnCode`)} className="w-20 px-2 py-1 text-xs font-mono border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <input {...register(`lineItems.${i}.quantity`)} type="number" step="any" className="w-16 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400" />
                    </td>
                    <td className="px-2 py-1.5">
                      <select
                        {...register(`lineItems.${i}.unit`)}
                        className="w-20 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400 bg-white"
                      >
                        {stockUnits.map((u) => (
                          <option key={u.name} value={u.name}>{u.name}</option>
                        ))}
                        {watch(`lineItems.${i}.unit`) && !stockUnits.some((u) => u.name === watch(`lineItems.${i}.unit`)) && (
                          <option value={watch(`lineItems.${i}.unit`)}>{watch(`lineItems.${i}.unit`)}</option>
                        )}
                      </select>
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
                      <TallyItemCell
                        index={i}
                        register={register}
                        watch={watch}
                        onCreateClick={() => setCreateItemRowIndex(i)}
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

      {/* Expense ledger rows — misc bill only */}
      {billType === 'misc' && bill.lineItems.length > 0 && (
        <div className="mt-5">
          <h3 className="text-sm font-bold text-gray-800 mb-3">Expense Ledgers <span className="text-gray-500 font-normal">(select a ledger for each expense)</span></h3>
          <div className="overflow-x-auto rounded-xl border border-gray-200">
            <table className="w-full border-collapse text-xs" aria-label="Expense ledger rows">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">Description</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">Expense Ledger *</th>
                  <th className="px-3 py-2 text-left font-bold text-gray-500 uppercase tracking-wider">Amount</th>
                </tr>
              </thead>
              <tbody>
                {bill.lineItems.map((_item, i) => (
                  <tr key={i} className="border-b border-gray-100 last:border-0">
                    <td className="px-3 py-2 text-sm text-gray-700">{bill.lineItems[i].description}</td>
                    <td className="px-2 py-1.5">
                      <input
                        {...register(`lineItems.${i}.tallyLedger`)}
                        list="all-ledgers-list"
                        autoComplete="off"
                        placeholder="Select expense ledger…"
                        className="w-56 px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:border-teal-400 focus:ring-1 focus:ring-teal-400"
                      />
                    </td>
                    <td className="px-3 py-2 text-sm font-semibold text-gray-800">{formatCurrency(bill.lineItems[i].amount)}</td>
                  </tr>
                ))}
              </tbody>
              <datalist id="all-ledgers-list">
                {allLedgerNames.map((name) => <option key={name} value={name} />)}
              </datalist>
              <tfoot className="bg-gray-50 border-t-2 border-gray-200">
                <tr className="border-t border-gray-100">
                  <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">Subtotal</td>
                  <td></td>
                  <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.subtotal)}</td>
                </tr>
                {!isInterstate && (
                  <>
                    <tr className="border-t border-gray-100">
                      <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">CGST</td>
                      <td></td>
                      <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.cgstAmount)}</td>
                    </tr>
                    <tr className="border-t border-gray-100">
                      <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">SGST</td>
                      <td></td>
                      <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.sgstAmount)}</td>
                    </tr>
                  </>
                )}
                {isInterstate && (
                  <tr className="border-t border-gray-100">
                    <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">IGST</td>
                    <td></td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(bill.igstAmount)}</td>
                  </tr>
                )}
                {hasRoundOff && (
                  <tr className="border-t border-gray-100">
                    <td className="px-3 py-2 text-right text-xs font-medium text-gray-500">Round Off</td>
                    <td></td>
                    <td className="px-3 py-2 text-xs font-semibold text-gray-800">{formatCurrency(roundOffValue!)}</td>
                  </tr>
                )}
                <tr className="border-t-2 border-gray-300">
                  <td className="px-3 py-2 text-right text-xs font-bold text-gray-700">Total Amount</td>
                  <td></td>
                  <td className="px-3 py-2 text-xs font-bold text-teal-700">{formatCurrency(bill.totalAmount)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Create stock item modal */}
      {billType !== 'misc' && createItemRowIndex !== null && (
        <CreateStockItemModal
          open
          companyId={companyId}
          tallyUrl={tallyUrl}
          tallyCompany={tallyCompany}
          billItemDescription={bill.lineItems[createItemRowIndex]?.description ?? ''}
          hsnCode={bill.lineItems[createItemRowIndex]?.hsnCode ?? ''}
          onSuccess={(itemName) => setValue(`lineItems.${createItemRowIndex}.tallyStockItem`, itemName)}
          onClose={() => setCreateItemRowIndex(null)}
        />
      )}

      {/* Narration */}
      <div className="mt-5">
        <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
          Narration <span className="font-normal text-gray-400">(optional)</span>
        </label>
        <textarea
          {...register('narration')}
          rows={2}
          placeholder="Add a note or narration for this voucher…"
          className="input-base w-full resize-none"
        />
      </div>

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
