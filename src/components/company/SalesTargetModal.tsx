import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { Loader2 } from 'lucide-react'
import { Modal } from '@/components/ui/Modal'
import { Button } from '@/components/ui/Button'
import { fetchSalesTargets, saveSalesTargets, fetchDashboardSettings, saveDashboardSettings } from '@/lib/api'
import { fetchTallyVoucherTypes, fetchTallyLedgers } from '@/services/tallyService'
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

type SettingsTab = 'today' | 'ytd' | 'monthly'

interface Props {
  open:          boolean
  onClose:       () => void
  companyId:     string
  tallyUrl:      string
  tallyCompany?: string
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
          <Loader2 className="w-3 h-3 animate-spin" /> Fetching from Tally…
        </div>
      ) : options.length === 0 ? (
        <p className="text-xs text-gray-400 italic py-1">No options found — is Tally running?</p>
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
          <Loader2 className="w-3 h-3 animate-spin" /> Fetching from Tally…
        </div>
      ) : options.length === 0 ? (
        <p className="text-xs text-gray-400 italic py-1">No options found — is Tally running?</p>
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
            ) : filtered.map(opt => (
              <label key={opt} className="flex items-center gap-2.5 px-3 py-1.5 cursor-pointer hover:bg-gray-50">
                <input type="checkbox" checked={selected.includes(opt)} onChange={() => toggle(opt)}
                  className="accent-blue-600 w-3.5 h-3.5 shrink-0" />
                <span className="text-xs text-gray-700">{opt}</span>
              </label>
            ))}
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
export function SalesTargetModal({ open, onClose, companyId, tallyUrl, tallyCompany }: Props) {
  const fyYear  = getCurrentFyYear()
  const fyLabel = `FY ${fyYear}–${String(fyYear + 1).slice(2)}`

  const [activeTab, setActiveTab] = useState<SettingsTab>('today')

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
  const [ytdIndirectExpenseLedgers,         setYtdIndirectExpenseLedgers]         = useState<string[]>([])
  const [ytdIndirectExpenseIncludeVouchers, setYtdIndirectExpenseIncludeVouchers] = useState<string[]>([])
  const [ytdIndirectExpenseExcludeVouchers, setYtdIndirectExpenseExcludeVouchers] = useState<string[]>([])
  const [ytdIndirectIncomeLedgers,          setYtdIndirectIncomeLedgers]          = useState<string[]>([])
  const [ytdIndirectIncomeIncludeVouchers,  setYtdIndirectIncomeIncludeVouchers]  = useState<string[]>([])
  const [ytdIndirectIncomeExcludeVouchers,  setYtdIndirectIncomeExcludeVouchers]  = useState<string[]>([])
  const [ytdGrossMarginTarget,       setYtdGrossMarginTarget]       = useState<string>('')
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
        setYtdIndirectExpenseLedgers(s.ytd?.indirectExpenseLedgers ?? [])
        setYtdIndirectExpenseIncludeVouchers(s.ytd?.indirectExpenseIncludeVouchers ?? [])
        setYtdIndirectExpenseExcludeVouchers(s.ytd?.indirectExpenseExcludeVouchers ?? [])
        setYtdIndirectIncomeLedgers(s.ytd?.indirectIncomeLedgers ?? [])
        setYtdIndirectIncomeIncludeVouchers(s.ytd?.indirectIncomeIncludeVouchers ?? [])
        setYtdIndirectIncomeExcludeVouchers(s.ytd?.indirectIncomeExcludeVouchers ?? [])
        setYtdGrossMarginTarget(s.ytd?.grossMarginTarget != null ? String(s.ytd.grossMarginTarget) : '')
      })
      .catch(() => { /* settings optional */ })

    // Fetch Tally options in parallel (best-effort)
    setLoadingOpts(true)
    Promise.allSettled([
      fetchTallyVoucherTypes(tallyUrl, tallyCompany),
      fetchTallyLedgers(tallyUrl, tallyCompany),
    ]).then(([vtRes, ledRes]) => {
      if (vtRes.status === 'fulfilled') setVoucherTypeOpts(vtRes.value.sort())
      if (ledRes.status === 'fulfilled') {
        const all  = ledRes.value.map(l => l.name).sort()
        const cash = ledRes.value.filter(l => l.group?.toLowerCase().includes('cash')).map(l => l.name).sort()
        const bank = ledRes.value.filter(l => l.group?.toLowerCase().includes('bank')).map(l => l.name).sort()
        setAllLedgerOpts(all)
        setCashLedgerOpts(cash)
        setBankLedgerOpts(bank)
      }
    }).finally(() => setLoadingOpts(false))
  }, [open, companyId, fyYear, tallyUrl, tallyCompany])

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
        indirectExpenseLedgers:         ytdIndirectExpenseLedgers.length         > 0 ? ytdIndirectExpenseLedgers         : undefined,
        indirectExpenseIncludeVouchers: ytdIndirectExpenseIncludeVouchers.length > 0 ? ytdIndirectExpenseIncludeVouchers : undefined,
        indirectExpenseExcludeVouchers: ytdIndirectExpenseExcludeVouchers.length > 0 ? ytdIndirectExpenseExcludeVouchers : undefined,
        indirectIncomeLedgers:          ytdIndirectIncomeLedgers.length          > 0 ? ytdIndirectIncomeLedgers          : undefined,
        indirectIncomeIncludeVouchers:  ytdIndirectIncomeIncludeVouchers.length  > 0 ? ytdIndirectIncomeIncludeVouchers  : undefined,
        indirectIncomeExcludeVouchers:  ytdIndirectIncomeExcludeVouchers.length  > 0 ? ytdIndirectIncomeExcludeVouchers  : undefined,
        grossMarginTarget:       ytdGrossMarginTarget ? (parseFloat(ytdGrossMarginTarget) || undefined) : undefined,
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
    { key: 'monthly', label: 'Monthly' },
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
            <p className="text-xs font-bold text-blue-700 uppercase tracking-widest mb-4">EBITDA</p>
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

      {/* ── MONTHLY PLACEHOLDER ── */}
      {activeTab === 'monthly' && (
        <div className="h-40 flex flex-col items-center justify-center gap-1 text-gray-400">
          <p className="text-sm font-medium">Coming soon</p>
          <p className="text-xs">Settings for Monthly dashboard will appear here.</p>
        </div>
      )}
    </Modal>
  )
}
