import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { Loader2 } from 'lucide-react'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { fetchSalesTargets, saveSalesTargets, fetchDashboardSettings, saveDashboardSettings } from '@/lib/api'
import { useCompanyStore } from '@/store'
import type { DashboardSettings } from '@/types'

const FY_MONTHS = [
  { month: 4,  label: 'April'     },
  { month: 5,  label: 'May'       },
  { month: 6,  label: 'June'      },
  { month: 7,  label: 'July'      },
  { month: 8,  label: 'August'    },
  { month: 9,  label: 'September' },
  { month: 10, label: 'October'   },
  { month: 11, label: 'November'  },
  { month: 12, label: 'December'  },
  { month: 1,  label: 'January'   },
  { month: 2,  label: 'February'  },
  { month: 3,  label: 'March'     },
]

function getCurrentFyYear() {
  const today = new Date()
  return today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1
}

type SettingsTab = 'today' | 'ytd' | 'ratios'
type RatioTab = 'dso' | 'dio' | 'dpo' | 'current' | 'quick' | 'roce' | 'roe' | 'debtEquity'

interface Props {
  open:      boolean
  onClose:   () => void
  companyId: string
}

// ── Simple checkbox list (short lists like cash/bank ledgers) ─────────────────
function CheckList({
  label, hint, options, selected, onChange, loading,
}: {
  label: string; hint: string; options: string[]
  selected: string[]; onChange: (v: string[]) => void; loading: boolean
}) {
  const toggle = (name: string) =>
    onChange(selected.includes(name) ? selected.filter(x => x !== name) : [...selected, name])
  return (
    <div>
      <p className="text-xs font-semibold text-gray-700 mb-1.5">{label}</p>
      {loading ? (
        <div className="flex items-center gap-2 text-xs text-gray-400 py-2">
          <Loader2 className="w-3 h-3 animate-spin" /> Loading…
        </div>
      ) : options.length === 0 ? (
        <p className="text-xs text-gray-400 italic py-1">No options found — sync ledgers/voucher types from Settings first</p>
      ) : (
        <div className="border border-gray-200 rounded-lg divide-y divide-gray-100 max-h-44 overflow-y-auto">
          {options.map(opt => (
            <label key={opt} className="flex items-center gap-2.5 px-3 py-1.5 cursor-pointer hover:bg-gray-50">
              <input type="checkbox" checked={selected.includes(opt)} onChange={() => toggle(opt)}
                className="accent-blue-600 w-3.5 h-3.5 shrink-0" />
              <span className="text-xs text-gray-700">{opt}</span>
            </label>
          ))}
        </div>
      )}
      {selected.length === 0 && !loading && options.length > 0 && (
        <p className="text-[11px] text-gray-400 italic mt-1">{hint}</p>
      )}
      {selected.length > 0 && <p className="text-[11px] text-blue-600 mt-1">{selected.length} selected</p>}
    </div>
  )
}

// ── Searchable checkbox list (large lists like all ledgers / voucher types) ────
function SearchCheckList({
  label, hint, options, selected, onChange, loading, showSelectAll = false,
}: {
  label: string; hint: string; options: string[]
  selected: string[]; onChange: (v: string[]) => void; loading: boolean
  showSelectAll?: boolean
}) {
  const [search, setSearch] = useState('')
  const toggle = (name: string) =>
    onChange(selected.includes(name) ? selected.filter(x => x !== name) : [...selected, name])
  const filtered = options.filter(o => o.toLowerCase().includes(search.toLowerCase()))
  const allSelected = options.length > 0 && selected.length === options.length

  // Companies can have thousands of ledgers — rendering every option as a DOM
  // node (unvirtualized) is what made switching tabs hang for seconds. Cap
  // the render count and keep already-selected items visible first so users
  // can still see/uncheck their picks without needing to search.
  const MAX_VISIBLE = 150
  const ordered = search
    ? filtered
    : [...filtered.filter(o => selected.includes(o)), ...filtered.filter(o => !selected.includes(o))]
  const visible = ordered.slice(0, MAX_VISIBLE)
  const hiddenCount = ordered.length - visible.length
  return (
    <div>
      <div className="flex items-center justify-between mb-1.5">
        <p className="text-xs font-semibold text-gray-700">{label}</p>
        <div className="flex items-center gap-2">
          {selected.length > 0 && (
            <button
              type="button"
              onClick={() => onChange([])}
              className="text-[11px] font-medium text-red-500 hover:text-red-600"
            >
              Clear
            </button>
          )}
          {showSelectAll && !loading && options.length > 0 && (
            <button
              type="button"
              onClick={() => onChange(allSelected ? [] : options)}
              className="text-[11px] font-medium text-blue-600 hover:text-blue-700"
            >
              {allSelected ? 'Clear All' : 'Select All'}
            </button>
          )}
        </div>
      </div>
      {loading ? (
        <div className="flex items-center gap-2 text-xs text-gray-400 py-2">
          <Loader2 className="w-3 h-3 animate-spin" /> Loading…
        </div>
      ) : options.length === 0 ? (
        <p className="text-xs text-gray-400 italic py-1">No options found — sync ledgers/voucher types from Settings first</p>
      ) : (
        <>
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search…"
            className="w-full px-2.5 py-1.5 text-xs border border-gray-200 rounded-lg outline-none focus:border-blue-500 mb-1"
          />
          <div className="border border-gray-200 rounded-lg divide-y divide-gray-100 max-h-40 overflow-y-auto">
            {filtered.length === 0 ? (
              <p className="text-xs text-gray-400 italic px-3 py-2">No matches</p>
            ) : (
              <>
                {visible.map(opt => (
                  <label key={opt} className="flex items-center gap-2.5 px-3 py-1.5 cursor-pointer hover:bg-gray-50">
                    <input type="checkbox" checked={selected.includes(opt)} onChange={() => toggle(opt)}
                      className="accent-blue-600 w-3.5 h-3.5 shrink-0" />
                    <span className="text-xs text-gray-700">{opt}</span>
                  </label>
                ))}
                {hiddenCount > 0 && (
                  <p className="text-[11px] text-gray-400 italic px-3 py-1.5">
                    +{hiddenCount} more — type to search
                  </p>
                )}
              </>
            )}
          </div>
        </>
      )}
      {selected.length === 0 && !loading && options.length > 0 && (
        <p className="text-[11px] text-gray-400 italic mt-1">{hint}</p>
      )}
      {selected.length > 0 && (
        <p className="text-[11px] text-gray-500 mt-1 leading-relaxed">
          <span className="font-medium">{label}:</span>{' '}
          <span className="text-blue-600">
            {selected.slice(0, 3).join(', ')}
            {selected.length > 3 && ` +${selected.length - 3} more`}
          </span>
        </p>
      )}
    </div>
  )
}

// ── Main modal ────────────────────────────────────────────────────────────────
export function SalesTargetModal({ open, onClose, companyId }: Props) {
  const { getLedgers, fetchLedgersFromDb, getVoucherTypes, fetchVoucherTypesFromDb } = useCompanyStore()
  const fyYear  = getCurrentFyYear()
  const fyLabel = `FY ${fyYear}–${String(fyYear + 1).slice(2)}`

  const [activeTab, setActiveTab] = useState<SettingsTab>('today')
  const [activeRatioTab, setActiveRatioTab] = useState<RatioTab>('dso')

  // Budget state
  const [budgetValues,  setBudgetValues]  = useState<Record<number, string>>({})
  const [loadingBudget, setLoadingBudget] = useState(false)

  // Today sales settings
  const [salesAccounts,        setSalesAccounts]        = useState<string[]>([])
  const [salesIncludeVouchers, setSalesIncludeVouchers] = useState<string[]>([])
  const [salesExcludeVouchers, setSalesExcludeVouchers] = useState<string[]>([])

  // YTD settings
  const [ytdPurchaseAccounts,        setYtdPurchaseAccounts]        = useState<string[]>([])
  const [ytdPurchaseIncludeVouchers, setYtdPurchaseIncludeVouchers] = useState<string[]>([])
  const [ytdPurchaseExcludeVouchers, setYtdPurchaseExcludeVouchers] = useState<string[]>([])
  const [ytdDirectExpenseLedgers,    setYtdDirectExpenseLedgers]    = useState<string[]>([])
  // DIO/DPO's own dedicated Purchases (and DIO's own Direct Expenses) —
  // deliberately separate from ytdPurchaseAccounts/ytdDirectExpenseLedgers
  // above, which feed Gross Margin/Net Profit instead.
  const [dioPurchaseAccounts,        setDioPurchaseAccounts]        = useState<string[]>([])
  const [dioPurchaseIncludeVouchers, setDioPurchaseIncludeVouchers] = useState<string[]>([])
  const [dioPurchaseExcludeVouchers, setDioPurchaseExcludeVouchers] = useState<string[]>([])
  const [dioDirectExpenseLedgers,    setDioDirectExpenseLedgers]    = useState<string[]>([])
  const [dpoPurchaseAccounts,        setDpoPurchaseAccounts]        = useState<string[]>([])
  const [dpoPurchaseIncludeVouchers, setDpoPurchaseIncludeVouchers] = useState<string[]>([])
  const [dpoPurchaseExcludeVouchers, setDpoPurchaseExcludeVouchers] = useState<string[]>([])
  const [ytdIndirectExpenseLedgers,         setYtdIndirectExpenseLedgers]         = useState<string[]>([])
  const [ytdIndirectExpenseIncludeVouchers, setYtdIndirectExpenseIncludeVouchers] = useState<string[]>([])
  const [ytdIndirectExpenseExcludeVouchers, setYtdIndirectExpenseExcludeVouchers] = useState<string[]>([])
  const [ytdIndirectIncomeLedgers,          setYtdIndirectIncomeLedgers]          = useState<string[]>([])
  const [ytdIndirectIncomeIncludeVouchers,  setYtdIndirectIncomeIncludeVouchers]  = useState<string[]>([])
  const [ytdIndirectIncomeExcludeVouchers,  setYtdIndirectIncomeExcludeVouchers]  = useState<string[]>([])
  const [ytdEbitdaLedgers,         setYtdEbitdaLedgers]         = useState<string[]>([])
  const [ytdEbitdaIncludeVouchers, setYtdEbitdaIncludeVouchers] = useState<string[]>([])
  const [ytdEbitdaExcludeVouchers, setYtdEbitdaExcludeVouchers] = useState<string[]>([])
  const [ytdGrossMarginTarget,       setYtdGrossMarginTarget]       = useState<string>('')
  // Analysis-tab ratio KPI ledger lists (ROCE/ROE/Debt-Equity)
  const [interestExpenseLedgers,        setInterestExpenseLedgers]        = useState<string[]>([])
  const [taxPaymentLedgers,             setTaxPaymentLedgers]             = useState<string[]>([])
  const [nonOperatingIncomeLedgers,     setNonOperatingIncomeLedgers]     = useState<string[]>([])
  const [nonOperatingInvestmentLedgers, setNonOperatingInvestmentLedgers] = useState<string[]>([])
  const [directorLoanLedgers,           setDirectorLoanLedgers]           = useState<string[]>([])
  const [longTermBorrowingLedgers,      setLongTermBorrowingLedgers]      = useState<string[]>([])
  const [equityLedgers,                 setEquityLedgers]                 = useState<string[]>([])
  // ROE
  const [roeEquityLedgers,         setRoeEquityLedgers]         = useState<string[]>([])
  const [internalBorrowingLedgers, setInternalBorrowingLedgers] = useState<string[]>([])
  const [intangibleAssetLedgers,   setIntangibleAssetLedgers]   = useState<string[]>([])
  // Debt/Equity
  const [debtEquityLoanLedgers,   setDebtEquityLoanLedgers]   = useState<string[]>([])
  const [debtEquityCashLedgers,   setDebtEquityCashLedgers]   = useState<string[]>([])
  const [debtEquityBankLedgers,   setDebtEquityBankLedgers]   = useState<string[]>([])
  const [debtEquityEquityLedgers, setDebtEquityEquityLedgers] = useState<string[]>([])
  // Analysis tab's own Sales definition — deliberately separate from the
  // Today tab's Sales Accounts/Include/Exclude below.
  const [analysisSalesAccounts,        setAnalysisSalesAccounts]        = useState<string[]>([])
  const [analysisSalesIncludeVouchers, setAnalysisSalesIncludeVouchers] = useState<string[]>([])
  const [analysisSalesExcludeVouchers, setAnalysisSalesExcludeVouchers] = useState<string[]>([])
  // Cash / bank settings
  const [inflowLedgers, setInflowLedgers] = useState<string[]>([])
  const [bankLedgers,   setBankLedgers]   = useState<string[]>([])

  // Options fetched from Tally
  const [allLedgerOpts,   setAllLedgerOpts]   = useState<string[]>([])
  const [voucherTypeOpts, setVoucherTypeOpts] = useState<string[]>([])
  const [cashLedgerOpts,  setCashLedgerOpts]  = useState<string[]>([])
  const [bankLedgerOpts,  setBankLedgerOpts]  = useState<string[]>([])
  const [loadingOpts,     setLoadingOpts]     = useState(false)

  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!open) return

    // Load budget
    setLoadingBudget(true)
    fetchSalesTargets(companyId, fyYear)
      .then(rows => {
        const map: Record<number, string> = {}
        rows.forEach(r => { map[r.month] = String(r.target) })
        setBudgetValues(map)
      })
      .catch(() => toast.error('Failed to load targets'))
      .finally(() => setLoadingBudget(false))

    // Load saved settings
    fetchDashboardSettings(companyId)
      .then(s => {
        setSalesAccounts(s.today?.salesAccounts ?? [])
        setSalesIncludeVouchers(s.today?.salesIncludeVouchers ?? [])
        setSalesExcludeVouchers(s.today?.salesExcludeVouchers ?? [])
        setInflowLedgers(s.today?.cashInflowLedgers ?? [])
        setBankLedgers(s.today?.bankLedgers ?? [])
        setYtdPurchaseAccounts(s.ytd?.purchaseAccounts ?? [])
        setYtdPurchaseIncludeVouchers(s.ytd?.purchaseIncludeVouchers ?? [])
        setYtdPurchaseExcludeVouchers(s.ytd?.purchaseExcludeVouchers ?? [])
        setYtdDirectExpenseLedgers(s.ytd?.directExpenseLedgers ?? [])
        setDioPurchaseAccounts(s.ytd?.dioPurchaseAccounts ?? [])
        setDioPurchaseIncludeVouchers(s.ytd?.dioPurchaseIncludeVouchers ?? [])
        setDioPurchaseExcludeVouchers(s.ytd?.dioPurchaseExcludeVouchers ?? [])
        setDioDirectExpenseLedgers(s.ytd?.dioDirectExpenseLedgers ?? [])
        setDpoPurchaseAccounts(s.ytd?.dpoPurchaseAccounts ?? [])
        setDpoPurchaseIncludeVouchers(s.ytd?.dpoPurchaseIncludeVouchers ?? [])
        setDpoPurchaseExcludeVouchers(s.ytd?.dpoPurchaseExcludeVouchers ?? [])
        setYtdIndirectExpenseLedgers(s.ytd?.indirectExpenseLedgers ?? [])
        setYtdIndirectExpenseIncludeVouchers(s.ytd?.indirectExpenseIncludeVouchers ?? [])
        setYtdIndirectExpenseExcludeVouchers(s.ytd?.indirectExpenseExcludeVouchers ?? [])
        setYtdIndirectIncomeLedgers(s.ytd?.indirectIncomeLedgers ?? [])
        setYtdIndirectIncomeIncludeVouchers(s.ytd?.indirectIncomeIncludeVouchers ?? [])
        setYtdIndirectIncomeExcludeVouchers(s.ytd?.indirectIncomeExcludeVouchers ?? [])
        setYtdEbitdaLedgers(s.ytd?.ebitdaLedgers ?? [])
        setYtdEbitdaIncludeVouchers(s.ytd?.ebitdaIncludeVouchers ?? [])
        setYtdEbitdaExcludeVouchers(s.ytd?.ebitdaExcludeVouchers ?? [])
        setYtdGrossMarginTarget(s.ytd?.grossMarginTarget != null ? String(s.ytd.grossMarginTarget) : '')
        setInterestExpenseLedgers(s.ytd?.interestExpenseLedgers ?? [])
        setTaxPaymentLedgers(s.ytd?.taxPaymentLedgers ?? [])
        setNonOperatingIncomeLedgers(s.ytd?.nonOperatingIncomeLedgers ?? [])
        setNonOperatingInvestmentLedgers(s.ytd?.nonOperatingInvestmentLedgers ?? [])
        setDirectorLoanLedgers(s.ytd?.directorLoanLedgers ?? [])
        setLongTermBorrowingLedgers(s.ytd?.longTermBorrowingLedgers ?? [])
        setEquityLedgers(s.ytd?.equityLedgers ?? [])
        setRoeEquityLedgers(s.ytd?.roeEquityLedgers ?? [])
        setInternalBorrowingLedgers(s.ytd?.internalBorrowingLedgers ?? [])
        setIntangibleAssetLedgers(s.ytd?.intangibleAssetLedgers ?? [])
        setDebtEquityLoanLedgers(s.ytd?.debtEquityLoanLedgers ?? [])
        setDebtEquityCashLedgers(s.ytd?.debtEquityCashLedgers ?? [])
        setDebtEquityBankLedgers(s.ytd?.debtEquityBankLedgers ?? [])
        setDebtEquityEquityLedgers(s.ytd?.debtEquityEquityLedgers ?? [])
        setAnalysisSalesAccounts(s.ytd?.analysisSalesAccounts ?? [])
        setAnalysisSalesIncludeVouchers(s.ytd?.analysisSalesIncludeVouchers ?? [])
        setAnalysisSalesExcludeVouchers(s.ytd?.analysisSalesExcludeVouchers ?? [])
      })
      .catch(() => { /* settings optional */ })

    // Ledgers/voucher types come from the DB cache (already synced whenever
    // the company last used the "Sync"/"Refresh" buttons on the Settings
    // page — see CompanySettings.tsx's handleSyncLedgers/handleSyncVoucherTypes),
    // never a live Tally call from here. This is what lets Admin manage these
    // settings for a company without Tally open on Admin's machine, and it
    // also means the company user doesn't need Tally running just to open
    // this modal.
    setLoadingOpts(true)
    Promise.allSettled([
      fetchVoucherTypesFromDb(companyId),
      fetchLedgersFromDb(companyId),
    ]).then(() => {
      setVoucherTypeOpts([...getVoucherTypes(companyId)].sort())
      const all = getLedgers(companyId)
      setAllLedgerOpts(all.map(l => l.name).sort())
      setCashLedgerOpts(all.filter(l => l.group.toLowerCase().includes('cash')).map(l => l.name).sort())
      setBankLedgerOpts(all.filter(l => l.group.toLowerCase().includes('bank')).map(l => l.name).sort())
    }).finally(() => setLoadingOpts(false))
  }, [open, companyId, fyYear, fetchVoucherTypesFromDb, fetchLedgersFromDb, getVoucherTypes, getLedgers])

  const handleSave = async () => {
    const targets = FY_MONTHS.map(({ month }) => ({
      month,
      target: parseFloat(budgetValues[month] || '0') || 0,
    }))

    const settings: DashboardSettings = {
      today: {
        salesAccounts:        salesAccounts.length        > 0 ? salesAccounts        : undefined,
        salesIncludeVouchers: salesIncludeVouchers.length > 0 ? salesIncludeVouchers : undefined,
        salesExcludeVouchers: salesExcludeVouchers.length > 0 ? salesExcludeVouchers : undefined,
        cashInflowLedgers:    inflowLedgers.length        > 0 ? inflowLedgers        : undefined,
        bankLedgers:          bankLedgers.length          > 0 ? bankLedgers          : undefined,
      },
      ytd: {
        purchaseAccounts:        ytdPurchaseAccounts.length        > 0 ? ytdPurchaseAccounts        : undefined,
        purchaseIncludeVouchers: ytdPurchaseIncludeVouchers.length > 0 ? ytdPurchaseIncludeVouchers : undefined,
        purchaseExcludeVouchers: ytdPurchaseExcludeVouchers.length > 0 ? ytdPurchaseExcludeVouchers : undefined,
        directExpenseLedgers:    ytdDirectExpenseLedgers.length    > 0 ? ytdDirectExpenseLedgers    : undefined,
        dioPurchaseAccounts:        dioPurchaseAccounts.length        > 0 ? dioPurchaseAccounts        : undefined,
        dioPurchaseIncludeVouchers: dioPurchaseIncludeVouchers.length > 0 ? dioPurchaseIncludeVouchers : undefined,
        dioPurchaseExcludeVouchers: dioPurchaseExcludeVouchers.length > 0 ? dioPurchaseExcludeVouchers : undefined,
        dioDirectExpenseLedgers:    dioDirectExpenseLedgers.length    > 0 ? dioDirectExpenseLedgers    : undefined,
        dpoPurchaseAccounts:        dpoPurchaseAccounts.length        > 0 ? dpoPurchaseAccounts        : undefined,
        dpoPurchaseIncludeVouchers: dpoPurchaseIncludeVouchers.length > 0 ? dpoPurchaseIncludeVouchers : undefined,
        dpoPurchaseExcludeVouchers: dpoPurchaseExcludeVouchers.length > 0 ? dpoPurchaseExcludeVouchers : undefined,
        indirectExpenseLedgers:         ytdIndirectExpenseLedgers.length         > 0 ? ytdIndirectExpenseLedgers         : undefined,
        indirectExpenseIncludeVouchers: ytdIndirectExpenseIncludeVouchers.length > 0 ? ytdIndirectExpenseIncludeVouchers : undefined,
        indirectExpenseExcludeVouchers: ytdIndirectExpenseExcludeVouchers.length > 0 ? ytdIndirectExpenseExcludeVouchers : undefined,
        indirectIncomeLedgers:          ytdIndirectIncomeLedgers.length          > 0 ? ytdIndirectIncomeLedgers          : undefined,
        indirectIncomeIncludeVouchers:  ytdIndirectIncomeIncludeVouchers.length  > 0 ? ytdIndirectIncomeIncludeVouchers  : undefined,
        indirectIncomeExcludeVouchers:  ytdIndirectIncomeExcludeVouchers.length  > 0 ? ytdIndirectIncomeExcludeVouchers  : undefined,
        ebitdaLedgers:                  ytdEbitdaLedgers.length                  > 0 ? ytdEbitdaLedgers                  : undefined,
        ebitdaIncludeVouchers:          ytdEbitdaIncludeVouchers.length          > 0 ? ytdEbitdaIncludeVouchers          : undefined,
        ebitdaExcludeVouchers:          ytdEbitdaExcludeVouchers.length          > 0 ? ytdEbitdaExcludeVouchers          : undefined,
        grossMarginTarget:       ytdGrossMarginTarget ? (parseFloat(ytdGrossMarginTarget) || undefined) : undefined,
        interestExpenseLedgers:         interestExpenseLedgers.length        > 0 ? interestExpenseLedgers        : undefined,
        taxPaymentLedgers:              taxPaymentLedgers.length             > 0 ? taxPaymentLedgers             : undefined,
        nonOperatingIncomeLedgers:      nonOperatingIncomeLedgers.length     > 0 ? nonOperatingIncomeLedgers     : undefined,
        nonOperatingInvestmentLedgers:  nonOperatingInvestmentLedgers.length > 0 ? nonOperatingInvestmentLedgers : undefined,
        directorLoanLedgers:            directorLoanLedgers.length           > 0 ? directorLoanLedgers           : undefined,
        longTermBorrowingLedgers:       longTermBorrowingLedgers.length       > 0 ? longTermBorrowingLedgers       : undefined,
        equityLedgers:                  equityLedgers.length                  > 0 ? equityLedgers                  : undefined,
        roeEquityLedgers:               roeEquityLedgers.length               > 0 ? roeEquityLedgers               : undefined,
        internalBorrowingLedgers:       internalBorrowingLedgers.length       > 0 ? internalBorrowingLedgers       : undefined,
        intangibleAssetLedgers:         intangibleAssetLedgers.length         > 0 ? intangibleAssetLedgers         : undefined,
        debtEquityLoanLedgers:          debtEquityLoanLedgers.length          > 0 ? debtEquityLoanLedgers          : undefined,
        debtEquityCashLedgers:          debtEquityCashLedgers.length          > 0 ? debtEquityCashLedgers          : undefined,
        debtEquityBankLedgers:          debtEquityBankLedgers.length          > 0 ? debtEquityBankLedgers          : undefined,
        debtEquityEquityLedgers:        debtEquityEquityLedgers.length        > 0 ? debtEquityEquityLedgers        : undefined,
        analysisSalesAccounts:          analysisSalesAccounts.length          > 0 ? analysisSalesAccounts          : undefined,
        analysisSalesIncludeVouchers:   analysisSalesIncludeVouchers.length   > 0 ? analysisSalesIncludeVouchers   : undefined,
        analysisSalesExcludeVouchers:   analysisSalesExcludeVouchers.length   > 0 ? analysisSalesExcludeVouchers   : undefined,
      },
    }

    setSaving(true)
    try {
      await Promise.all([
        saveSalesTargets(companyId, fyYear, targets),
        saveDashboardSettings(companyId, settings),
      ])
      toast.success('Settings saved')
      onClose()
    } catch {
      toast.error('Failed to save settings')
    } finally {
      setSaving(false)
    }
  }

  const totalTarget = FY_MONTHS.reduce((s, { month }) => s + (parseFloat(budgetValues[month] || '0') || 0), 0)

  const TABS: { key: SettingsTab; label: string }[] = [
    { key: 'today',   label: 'Today'   },
    { key: 'ytd',     label: 'YTD'     },
    { key: 'ratios',  label: 'Ratios'  },
  ]

  const RATIO_TABS: { key: RatioTab; label: string }[] = [
    { key: 'dso',        label: 'DSO'          },
    { key: 'dio',        label: 'DIO'          },
    { key: 'dpo',        label: 'DPO'          },
    { key: 'current',    label: 'Current Ratio' },
    { key: 'quick',      label: 'Quick Ratio'   },
    { key: 'roce',       label: 'ROCE'          },
    { key: 'roe',        label: 'ROE'           },
    { key: 'debtEquity', label: 'Debt/Equity'   },
  ]

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Dashboard Settings"
      subtitle="Configure KPI filters and monthly sales targets"
      footer={
        <>
          <Button variant="outline" onClick={onClose} disabled={saving}>Cancel</Button>
          <Button variant="primary" onClick={handleSave} loading={saving}>Save Settings</Button>
        </>
      }
    >
      {/* Tab bar */}
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 mb-5">
        {TABS.map(t => (
          <button
            key={t.key}
            onClick={() => setActiveTab(t.key)}
            className={`flex-1 py-1.5 rounded-md text-xs font-semibold transition-all ${
              activeTab === t.key
                ? 'bg-white text-gray-900 shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* ── TODAY TAB ── */}
      {activeTab === 'today' && (
        <div className="space-y-6">

          {/* Section A — Sales Budget */}
          <div>
            <p className="text-xs font-semibold text-gray-700 mb-3">
              Sales Budget
              <span className="font-normal text-gray-400 ml-1">({fyLabel}, excl. GST)</span>
            </p>
            {loadingBudget ? (
              <div className="h-24 flex items-center justify-center text-sm text-gray-400">Loading…</div>
            ) : (
              <div className="grid grid-cols-2 gap-x-6 gap-y-2">
                {FY_MONTHS.map(({ month, label }) => (
                  <div key={month} className="flex items-center gap-2">
                    <label className="text-xs text-gray-600 w-24 shrink-0">{label}</label>
                    <div className="relative flex-1">
                      <span className="absolute left-2.5 top-1/2 -translate-y-1/2 text-xs text-gray-400">₹</span>
                      <input
                        type="number"
                        min="0"
                        step="1"
                        placeholder="0"
                        value={budgetValues[month] ?? ''}
                        onChange={e => setBudgetValues(v => ({ ...v, [month]: e.target.value }))}
                        className="w-full pl-6 pr-2 py-1.5 text-xs border border-gray-200 rounded-lg outline-none focus:border-blue-500 bg-white"
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
            {totalTarget > 0 && (
              <div className="flex justify-between items-center border-t border-gray-100 pt-2 mt-3 text-xs">
                <span className="text-gray-500">Annual Target</span>
                <span className="font-semibold text-gray-800">
                  ₹{totalTarget.toLocaleString('en-IN', { maximumFractionDigits: 0 })}
                </span>
              </div>
            )}
          </div>

          {/* Section B — Sales Accounts (ledgers) */}
          <div className="border-t border-gray-100 pt-5">
            <SearchCheckList
              label="Sales Accounts"
              hint="Default: all vouchers matching voucher type filter below"
              options={allLedgerOpts}
              selected={salesAccounts}
              onChange={setSalesAccounts}
              loading={loadingOpts}
            />
          </div>

          {/* Section C — Sales Voucher Filters */}
          <div className="border-t border-gray-100 pt-5 grid grid-cols-2 gap-5">
            <SearchCheckList
              label="Sales — Include Vouchers"
              hint="Default: voucher types containing 'sales'"
              options={voucherTypeOpts}
              selected={salesIncludeVouchers}
              onChange={setSalesIncludeVouchers}
              loading={loadingOpts}
            />
            <SearchCheckList
              label="Sales — Exclude Vouchers"
              hint="Default: Credit Note"
              options={voucherTypeOpts}
              selected={salesExcludeVouchers}
              onChange={setSalesExcludeVouchers}
              loading={loadingOpts}
            />
          </div>

          {/* Section C — Cash Ledgers */}
          <div className="border-t border-gray-100 pt-5 grid grid-cols-2 gap-5">
            <CheckList
              label="Cash-in-Hand"
              hint="Default: all Cash-in-Hand ledgers"
              options={cashLedgerOpts}
              selected={inflowLedgers}
              onChange={setInflowLedgers}
              loading={loadingOpts}
            />
          </div>

          {/* Section D — Bank Ledgers */}
          <div className="border-t border-gray-100 pt-5">
            <CheckList
              label="Bank Accounts"
              hint="Default: ledgers whose name contains 'bank'"
              options={bankLedgerOpts}
              selected={bankLedgers}
              onChange={setBankLedgers}
              loading={loadingOpts}
            />
          </div>

        </div>
      )}

      {/* ── YTD TAB ── */}
      {activeTab === 'ytd' && (
        <div className="space-y-6">

          {/* Purchase Accounts — mirrors Sales Accounts in Today tab */}
          <div>
            <SearchCheckList
              label="Purchase Accounts"
              hint="Default: all vouchers matching voucher type filter below"
              options={allLedgerOpts}
              selected={ytdPurchaseAccounts}
              onChange={setYtdPurchaseAccounts}
              loading={loadingOpts}
            />
          </div>

          <div className="border-t border-gray-100 pt-5 grid grid-cols-2 gap-5">
            <SearchCheckList
              label="Purchase — Include Vouchers"
              hint="Default: voucher types containing 'purchase'"
              options={voucherTypeOpts}
              selected={ytdPurchaseIncludeVouchers}
              onChange={setYtdPurchaseIncludeVouchers}
              loading={loadingOpts}
            />
            <SearchCheckList
              label="Purchase — Exclude Vouchers"
              hint="Default: Debit Note"
              options={voucherTypeOpts}
              selected={ytdPurchaseExcludeVouchers}
              onChange={setYtdPurchaseExcludeVouchers}
              loading={loadingOpts}
            />
          </div>

          <div className="border-t border-gray-100 pt-5">
            <SearchCheckList
              label="Direct Expense Ledgers"
              hint="e.g. Freight, Wages, Power — leave empty to exclude direct expenses"
              options={allLedgerOpts}
              selected={ytdDirectExpenseLedgers}
              onChange={setYtdDirectExpenseLedgers}
              loading={loadingOpts}
            />
          </div>

          {/* ── EBITDA Section ── */}
          <div className="border-t-2 border-blue-100 pt-5">
            <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-4">Net Profit</p>
            <div className="space-y-5">
              <SearchCheckList
                label="Indirect Expense Ledgers"
                hint="e.g. Rent, Salaries, Admin costs"
                options={allLedgerOpts}
                selected={ytdIndirectExpenseLedgers}
                onChange={setYtdIndirectExpenseLedgers}
                loading={loadingOpts}
                showSelectAll
              />
              <div className="grid grid-cols-2 gap-5">
                <SearchCheckList
                  label="Expense Vouchers — Include"
                  hint="Default: all voucher types"
                  options={voucherTypeOpts}
                  selected={ytdIndirectExpenseIncludeVouchers}
                  onChange={setYtdIndirectExpenseIncludeVouchers}
                  loading={loadingOpts}
                />
                <SearchCheckList
                  label="Expense Vouchers — Exclude"
                  hint="Default: none excluded"
                  options={voucherTypeOpts}
                  selected={ytdIndirectExpenseExcludeVouchers}
                  onChange={setYtdIndirectExpenseExcludeVouchers}
                  loading={loadingOpts}
                />
              </div>
              <SearchCheckList
                label="Indirect Income Ledgers"
                hint="e.g. Interest Received, Commission Income"
                options={allLedgerOpts}
                selected={ytdIndirectIncomeLedgers}
                onChange={setYtdIndirectIncomeLedgers}
                loading={loadingOpts}
                showSelectAll
              />
              <div className="grid grid-cols-2 gap-5">
                <SearchCheckList
                  label="Income Vouchers — Include"
                  hint="Default: all voucher types"
                  options={voucherTypeOpts}
                  selected={ytdIndirectIncomeIncludeVouchers}
                  onChange={setYtdIndirectIncomeIncludeVouchers}
                  loading={loadingOpts}
                />
                <SearchCheckList
                  label="Income Vouchers — Exclude"
                  hint="Default: none excluded"
                  options={voucherTypeOpts}
                  selected={ytdIndirectIncomeExcludeVouchers}
                  onChange={setYtdIndirectIncomeExcludeVouchers}
                  loading={loadingOpts}
                />
              </div>

              {/* EBITDA addback ledgers */}
              <div className="border-t border-blue-100 pt-4">
                <p className="text-[11px] font-semibold text-blue-600 uppercase tracking-wide mb-3">EBITDA Addback Ledgers</p>
                <p className="text-[10px] text-gray-400 italic mb-3">Depreciation, Tax, Interest etc. — added back to Net Profit → EBITDA</p>
                <div className="space-y-3">
                  <SearchCheckList
                    label="EBITDA Ledgers"
                    hint="e.g. Depreciation, Income Tax, Interest Paid"
                    options={allLedgerOpts}
                    selected={ytdEbitdaLedgers}
                    onChange={setYtdEbitdaLedgers}
                    loading={loadingOpts}
                    showSelectAll
                  />
                  <div className="grid grid-cols-2 gap-5">
                    <SearchCheckList
                      label="EBITDA Vouchers — Include"
                      hint="Default: all voucher types"
                      options={voucherTypeOpts}
                      selected={ytdEbitdaIncludeVouchers}
                      onChange={setYtdEbitdaIncludeVouchers}
                      loading={loadingOpts}
                    />
                    <SearchCheckList
                      label="EBITDA Vouchers — Exclude"
                      hint="Default: none excluded"
                      options={voucherTypeOpts}
                      selected={ytdEbitdaExcludeVouchers}
                      onChange={setYtdEbitdaExcludeVouchers}
                      loading={loadingOpts}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="border-t border-gray-100 pt-5">
            <p className="text-xs font-semibold text-gray-700 mb-1.5">Gross Margin Target (%)</p>
            <div className="relative w-40">
              <input
                type="number"
                min="0"
                max="100"
                step="0.1"
                placeholder="e.g. 40"
                value={ytdGrossMarginTarget}
                onChange={e => setYtdGrossMarginTarget(e.target.value)}
                className="w-full pr-7 pl-3 py-1.5 text-xs border border-gray-200 rounded-lg outline-none focus:border-blue-500 bg-white"
              />
              <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs text-gray-400">%</span>
            </div>
            <p className="text-[11px] text-gray-400 italic mt-1">Target GM% to track achievement on the dashboard</p>
          </div>

        </div>
      )}

      {activeTab === 'ratios' && (
        <div>
          {/* Ratio sub-tab bar */}
          <div className="flex gap-1 bg-gray-50 border border-gray-100 rounded-lg p-1 mb-5 flex-wrap">
            {RATIO_TABS.map(rt => (
              <button
                key={rt.key}
                onClick={() => setActiveRatioTab(rt.key)}
                className={`px-3 py-1.5 rounded-md text-xs font-semibold transition-all ${
                  activeRatioTab === rt.key
                    ? 'bg-white text-gray-900 shadow-sm border border-gray-200'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                {rt.label}
              </button>
            ))}
          </div>

          {/* ── DSO ── */}
          {activeRatioTab === 'dso' && (
            <div>
              <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-1">Sales (Analysis Tab)</p>
              <p className="text-[11px] text-gray-400 italic mb-4">
                Used for DSO and Net Profit on the Analysis tab only — deliberately separate from the
                Today tab's Sales Accounts, so changing one never affects the other.
              </p>
              <div className="space-y-5">
                <SearchCheckList
                  label="Sales Accounts"
                  hint="Default: all vouchers matching voucher type filter below"
                  options={allLedgerOpts}
                  selected={analysisSalesAccounts}
                  onChange={setAnalysisSalesAccounts}
                  loading={loadingOpts}
                />
                <div className="grid grid-cols-2 gap-5">
                  <SearchCheckList
                    label="Sales — Include Vouchers"
                    hint="Default: voucher types containing 'sales'"
                    options={voucherTypeOpts}
                    selected={analysisSalesIncludeVouchers}
                    onChange={setAnalysisSalesIncludeVouchers}
                    loading={loadingOpts}
                  />
                  <SearchCheckList
                    label="Sales — Exclude Vouchers"
                    hint="Default: Credit Note"
                    options={voucherTypeOpts}
                    selected={analysisSalesExcludeVouchers}
                    onChange={setAnalysisSalesExcludeVouchers}
                    loading={loadingOpts}
                  />
                </div>
                <p className="text-[11px] text-gray-400 italic">
                  DSO's Debtors figure uses Tally's standard Sundry Debtors closing balance — no
                  setting needed for that half.
                </p>
              </div>
            </div>
          )}

          {/* ── DIO ── */}
          {activeRatioTab === 'dio' && (
            <div>
              <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-1">Purchases &amp; Direct Expenses (DIO)</p>
              <p className="text-[11px] text-gray-400 italic mb-4">
                DIO's own COGS inputs — deliberately separate from the YTD tab's Purchase Accounts/
                Direct Expense Ledgers (which feed Gross Margin/Net Profit), so tuning DIO never
                silently moves Net Profit/ROCE/ROE.
              </p>
              <div className="space-y-5">
                <SearchCheckList
                  label="Purchase Accounts"
                  hint="Default: all vouchers matching voucher type filter below"
                  options={allLedgerOpts}
                  selected={dioPurchaseAccounts}
                  onChange={setDioPurchaseAccounts}
                  loading={loadingOpts}
                />
                <div className="grid grid-cols-2 gap-5">
                  <SearchCheckList
                    label="Purchase — Include Vouchers"
                    hint="Default: voucher types containing 'purchase'"
                    options={voucherTypeOpts}
                    selected={dioPurchaseIncludeVouchers}
                    onChange={setDioPurchaseIncludeVouchers}
                    loading={loadingOpts}
                  />
                  <SearchCheckList
                    label="Purchase — Exclude Vouchers"
                    hint="Default: Debit Note"
                    options={voucherTypeOpts}
                    selected={dioPurchaseExcludeVouchers}
                    onChange={setDioPurchaseExcludeVouchers}
                    loading={loadingOpts}
                  />
                </div>
                <SearchCheckList
                  label="Direct Expense Ledgers"
                  hint="e.g. Freight, Wages, Power — leave empty to exclude direct expenses"
                  options={allLedgerOpts}
                  selected={dioDirectExpenseLedgers}
                  onChange={setDioDirectExpenseLedgers}
                  loading={loadingOpts}
                />
                <p className="text-[11px] text-gray-400 italic">
                  Opening/Closing Stock use Tally's standard Stock-in-Hand closing balance — no
                  setting needed for those.
                </p>
              </div>
            </div>
          )}

          {/* ── DPO ── */}
          {activeRatioTab === 'dpo' && (
            <div>
              <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-1">Purchases (DPO)</p>
              <p className="text-[11px] text-gray-400 italic mb-4">
                DPO's own Purchases figure — deliberately separate from the YTD tab's Purchase
                Accounts (Gross Margin/Net Profit) and from DIO's own Purchases.
              </p>
              <div className="space-y-5">
                <SearchCheckList
                  label="Purchase Accounts"
                  hint="Default: all vouchers matching voucher type filter below"
                  options={allLedgerOpts}
                  selected={dpoPurchaseAccounts}
                  onChange={setDpoPurchaseAccounts}
                  loading={loadingOpts}
                />
                <div className="grid grid-cols-2 gap-5">
                  <SearchCheckList
                    label="Purchase — Include Vouchers"
                    hint="Default: voucher types containing 'purchase'"
                    options={voucherTypeOpts}
                    selected={dpoPurchaseIncludeVouchers}
                    onChange={setDpoPurchaseIncludeVouchers}
                    loading={loadingOpts}
                  />
                  <SearchCheckList
                    label="Purchase — Exclude Vouchers"
                    hint="Default: Debit Note"
                    options={voucherTypeOpts}
                    selected={dpoPurchaseExcludeVouchers}
                    onChange={setDpoPurchaseExcludeVouchers}
                    loading={loadingOpts}
                  />
                </div>
                <p className="text-[11px] text-gray-400 italic">
                  Creditors uses Tally's standard Sundry Creditors closing balance — no setting
                  needed for that half.
                </p>
              </div>
            </div>
          )}

          {/* ── Current Ratio ── */}
          {activeRatioTab === 'current' && (
            <div>
              <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-1">Current Ratio</p>
              <p className="text-[11px] text-gray-400 italic mb-4">
                (Closing Stock + Debtors) / Creditors — every input here comes from Tally's standard
                closing-balance groups (Stock-in-Hand, Sundry Debtors, Sundry Creditors). No
                company-specific mapping is needed.
              </p>
            </div>
          )}

          {/* ── Quick Ratio ── */}
          {activeRatioTab === 'quick' && (
            <div>
              <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-1">Quick Ratio</p>
              <p className="text-[11px] text-gray-400 italic mb-4">
                (Cash + Bank + Investments + Debtors) / (Current Liabilities − Bank OD) — every input
                here comes from Tally's standard closing-balance groups. No company-specific mapping
                is needed.
              </p>
            </div>
          )}

          {/* ── ROCE ── */}
          {activeRatioTab === 'roce' && (
            <div>
              <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-1">ROCE</p>
              <p className="text-[11px] text-gray-400 italic mb-4">
                Tally has no standard group for these — name the specific ledgers. Any left empty
                shows "No data available" on the ROCE card rather than a guessed number.
              </p>
              <div className="space-y-5">
                <SearchCheckList
                  label="Interest Expense Ledgers"
                  hint="e.g. Interest on Loan, Interest on OD"
                  options={allLedgerOpts}
                  selected={interestExpenseLedgers}
                  onChange={setInterestExpenseLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Tax Payment Ledgers"
                  hint="e.g. Income Tax Paid, TDS Paid"
                  options={allLedgerOpts}
                  selected={taxPaymentLedgers}
                  onChange={setTaxPaymentLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Non-Operating Income Ledgers"
                  hint="e.g. Rental Income, Profit on Sale of Asset"
                  options={allLedgerOpts}
                  selected={nonOperatingIncomeLedgers}
                  onChange={setNonOperatingIncomeLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Non-Operating Investment Ledgers"
                  hint="e.g. Fixed Deposits, Mutual Funds held for non-core purposes"
                  options={allLedgerOpts}
                  selected={nonOperatingInvestmentLedgers}
                  onChange={setNonOperatingInvestmentLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Long Term Borrowing Ledgers"
                  hint="Tally has no long-term/short-term split — name the specific long-term loan ledgers"
                  options={allLedgerOpts}
                  selected={longTermBorrowingLedgers}
                  onChange={setLongTermBorrowingLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Equity Ledgers"
                  hint="e.g. Share Capital, Reserves & Surplus"
                  options={allLedgerOpts}
                  selected={equityLedgers}
                  onChange={setEquityLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
              </div>
            </div>
          )}

          {/* ── ROE ── */}
          {activeRatioTab === 'roe' && (
            <div>
              <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-1">ROE</p>
              <p className="text-[11px] text-gray-400 italic mb-4">
                Numerator reuses the existing Net Profit (YTD) figure — no setting needed for that.
                These 3 make up the denominator. Any left empty defaults to 0 for Internal Borrowings/
                Intangible Assets (commonly zero); Equity must be set for ROE to compute at all.
              </p>
              <div className="space-y-5">
                <SearchCheckList
                  label="Equity Ledgers"
                  hint="e.g. Share Capital, Reserves & Surplus"
                  options={allLedgerOpts}
                  selected={roeEquityLedgers}
                  onChange={setRoeEquityLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Internal Borrowing Ledgers"
                  hint="Related-party/internal loans not already captured elsewhere"
                  options={allLedgerOpts}
                  selected={internalBorrowingLedgers}
                  onChange={setInternalBorrowingLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Intangible Asset Ledgers"
                  hint="e.g. Goodwill, Patents, Software"
                  options={allLedgerOpts}
                  selected={intangibleAssetLedgers}
                  onChange={setIntangibleAssetLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
              </div>
            </div>
          )}

          {/* ── Debt/Equity ── */}
          {activeRatioTab === 'debtEquity' && (
            <div>
              <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-1">Debt/Equity</p>
              <p className="text-[11px] text-gray-400 italic mb-4">
                (Total Interest Bearing Loans − Cash − Bank) / (Equity + Loans from Directors) — every
                component here is its own setting, independent of Cash/Bank/Equity used elsewhere.
                Loans and Equity must be set for this to compute; Cash/Bank/Director Loans default to 0.
              </p>
              <div className="space-y-5">
                <SearchCheckList
                  label="Total Interest Bearing Loans Ledgers"
                  hint="All secured + unsecured loan ledgers"
                  options={allLedgerOpts}
                  selected={debtEquityLoanLedgers}
                  onChange={setDebtEquityLoanLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Cash Balance Ledgers"
                  hint="e.g. Cash-in-Hand ledgers"
                  options={allLedgerOpts}
                  selected={debtEquityCashLedgers}
                  onChange={setDebtEquityCashLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Bank Balance Ledgers"
                  hint="e.g. Bank Account ledgers"
                  options={allLedgerOpts}
                  selected={debtEquityBankLedgers}
                  onChange={setDebtEquityBankLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Equity Ledgers"
                  hint="e.g. Share Capital, Reserves & Surplus"
                  options={allLedgerOpts}
                  selected={debtEquityEquityLedgers}
                  onChange={setDebtEquityEquityLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
                <SearchCheckList
                  label="Loans from Directors"
                  hint="Specific unsecured-loan ledgers held by directors/promoters"
                  options={allLedgerOpts}
                  selected={directorLoanLedgers}
                  onChange={setDirectorLoanLedgers}
                  loading={loadingOpts}
                  showSelectAll
                />
              </div>
            </div>
          )}
        </div>
      )}

    </Modal>
  )
}
