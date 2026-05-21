import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { RefreshCw, CheckCircle, AlertTriangle, CreditCard, Plus, Trash2, Landmark, BookOpen } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { Button } from '@/components/ui/Button'
import { useAuthStore, useCompanyStore } from '@/store'
import { Navigate } from 'react-router-dom'
import { cn } from '@/lib/utils'
import { fetchTallyGodowns, fetchTallyLedgers, fetchTallyStockItems, fetchTallyStockGroups, fetchTallyStockUnits, fetchTallyVoucherTypes } from '@/services/tallyService'
import { COMPANY_FEATURES, normalizeLedgerMapping } from '@/types'
import type { LedgerMapping, BankDefaultLedger } from '@/types'

export const TALLY_URL_KEY         = 'tally-server-url'
export const DEFAULT_TALLY_URL     = 'http://localhost:9000'
export const DEFAULT_VOUCHER_TYPE  = 'GST PURCHASE'


/** Returns the effective Tally URL.
 *  Priority: localStorage manual override → company port from DB → localhost:9000 */
export function getTallyUrl(companyId: string, companyPort?: number): string {
  const override = localStorage.getItem(`${TALLY_URL_KEY}-${companyId}`)
  if (override) return override
  if (companyPort) return `http://localhost:${companyPort}`
  return DEFAULT_TALLY_URL
}

// ── Single ledger combobox (input + datalist) ─────────────────────────────────

let _ledgerSelectId = 0

interface LedgerSelectProps {
  label: string
  value: string | undefined
  ledgerOptions: string[]
  onChange: (v: string) => void
}

function LedgerSelect({ label, value, ledgerOptions, onChange }: LedgerSelectProps) {
  const [id] = useState(() => `ls-${++_ledgerSelectId}`)

  return (
    <div className="mb-3">
      <label htmlFor={id} className="block text-xs font-medium text-gray-600 mb-1">{label}</label>
      <input
        id={id}
        list={`${id}-list`}
        value={value ?? ''}
        onChange={(e) => onChange(e.target.value)}
        autoComplete="off"
        placeholder="Type or select…"
        className="input-base w-full text-sm"
      />
      <datalist id={`${id}-list`}>
        {ledgerOptions.map((name) => <option key={name} value={name} />)}
      </datalist>
    </div>
  )
}

// ── Sync row ─────────────────────────────────────────────────────────────────

function formatSyncTs(iso: string): string {
  const d = new Date(iso)
  return d.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })
}

interface SyncRowProps {
  label: string
  count: number
  loading: boolean
  lastSync?: string | null
  onSync: () => void
}

function SyncRow({ label, count, loading, lastSync, onSync }: SyncRowProps) {
  return (
    <div className="flex items-center gap-3 py-2.5 border-b border-gray-100 last:border-0">
      <div className="flex-1 min-w-0">
        <p className="text-xs font-semibold text-gray-700">{label}</p>
        {count > 0 && (
          <p className="text-[10px] text-teal-600 font-medium flex items-center gap-1 mt-0.5">
            <CheckCircle className="w-3 h-3" /> {count} synced
          </p>
        )}
      </div>
      <div className="flex flex-col items-end gap-0.5 flex-shrink-0">
        <Button variant="outline" size="sm" loading={loading} onClick={onSync}>
          <RefreshCw className="w-3 h-3" />
          {count > 0 ? 'Refresh' : 'Sync'}
        </Button>
        {lastSync && (
          <p className="text-[10px] text-gray-500">{formatSyncTs(lastSync)}</p>
        )}
      </div>
    </div>
  )
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

type Tab = 'connection' | 'ledgers' | 'bank_cash' | 'subscription'

interface TabBarProps {
  active: Tab
  onChange: (t: Tab) => void
  showBankCash: boolean
}

function TabBar({ active, onChange, showBankCash }: TabBarProps) {
  const tabs: { id: Tab; label: string }[] = [
    { id: 'connection',   label: 'Connection' },
    { id: 'ledgers',      label: 'Default Ledgers' },
    ...(showBankCash ? [{ id: 'bank_cash' as Tab, label: 'Bank & Cash' }] : []),
    { id: 'subscription', label: 'Subscription' },
  ]
  return (
    <div className="flex border-b border-gray-200 mb-5">
      {tabs.map((t) => (
        <button
          key={t.id}
          onClick={() => onChange(t.id)}
          className={`px-4 py-2.5 text-xs font-semibold border-b-2 transition-colors -mb-px ${
            active === t.id
              ? 'border-teal-600 text-teal-700'
              : 'border-transparent text-gray-500 hover:text-gray-700'
          }`}
        >
          {t.label}
        </button>
      ))}
    </div>
  )
}

// ── Main settings page ────────────────────────────────────────────────────────

export default function CompanySettings() {
  const { activeCompanyId, companies: authCompanies } = useAuthStore()
  const { getCompany, getLedgers, fetchLedgersFromDb, saveLedgersToDb, updateMapping, getStockItems, fetchStockItemsFromDb, saveStockItemsToDb, getStockGroups, fetchStockGroupsFromDb, saveStockGroupsToDb, getStockUnits, fetchStockUnitsFromDb, saveStockUnitsToDb, getGodowns, fetchGodownsFromDb, saveGodownsToDb, getVoucherTypes, fetchVoucherTypesFromDb, saveVoucherTypesToDb, saveSelectedVoucherType, saveSelectedDebitVoucherType, saveSelectedCreditVoucherType } = useCompanyStore()
  const company     = activeCompanyId ? getCompany(activeCompanyId) : null
  const companyId   = activeCompanyId ?? ''
  const companyName = company?.name ?? authCompanies.find((c) => c.id === activeCompanyId)?.name ?? ''

  const godownEnabled        = company?.features?.some((f) => f.feature === COMPANY_FEATURES.GODOWN          && f.enabled) ?? false
  const debitVoucherEnabled  = company?.features?.some((f) => f.feature === COMPANY_FEATURES.DEBIT_VOUCHER   && f.enabled) ?? false
  const creditVoucherEnabled = company?.features?.some((f) => f.feature === COMPANY_FEATURES.CREDIT_VOUCHER  && f.enabled) ?? false
  const bankVoucherEnabled   = company?.features?.some((f) => f.feature === COMPANY_FEATURES.BANK_VOUCHER    && f.enabled) ?? false
  const cashBookEnabled      = company?.features?.some((f) => f.feature === COMPANY_FEATURES.CASH_BOOK       && f.enabled) ?? false
  const settingsHidden       = company?.features?.some((f) => f.feature === COMPANY_FEATURES.HIDE_SETTINGS   && f.enabled) ?? false
  const showBankCash         = bankVoucherEnabled || cashBookEnabled

  if (settingsHidden) return <Navigate to="/company" replace />

  const [activeTab,          setActiveTab]          = useState<Tab>('connection')
  const [syncing,            setSyncing]            = useState(false)
  const [syncingItems,       setSyncingItems]       = useState(false)
  const [syncingGroups,      setSyncingGroups]      = useState(false)
  const [syncingUnits,       setSyncingUnits]       = useState(false)
  const [syncingGodowns,     setSyncingGodowns]     = useState(false)
  const [savingMap,          setSavingMap]          = useState(false)
  const [tallyUrl,           setTallyUrl]           = useState(() => getTallyUrl(companyId, company?.port))
  const [voucherType,        setVoucherType]        = useState(() => company?.voucherType || DEFAULT_VOUCHER_TYPE)
  const [debitVoucherType,   setDebitVoucherType]   = useState(() => (company?.mapping as Record<string, string> | null)?.debit_voucher_type ?? '')
  const [creditVoucherType,  setCreditVoucherType]  = useState(() => (company?.mapping as Record<string, string> | null)?.credit_voucher_type ?? '')
  const [voucherTypes,       setVoucherTypes]       = useState<string[]>(() => companyId ? getVoucherTypes(companyId) : [])
  const [fetchingVTypes,     setFetchingVTypes]     = useState(false)
  const [savingDebitVType,   setSavingDebitVType]   = useState(false)
  const [savingCreditVType,  setSavingCreditVType]  = useState(false)

  const storedLedgers     = companyId ? getLedgers(companyId)     : []
  const storedStockItems  = companyId ? getStockItems(companyId)  : []
  const storedStockGroups = companyId ? getStockGroups(companyId) : []
  const storedStockUnits  = companyId ? getStockUnits(companyId)  : []
  const storedGodowns     = companyId ? getGodowns(companyId)     : []
  const ledgerOptions     = storedLedgers.map((l) => l.name)

  const [mapping, setMapping] = useState<LedgerMapping>(() => normalizeLedgerMapping(company?.mapping))

  // Bank & Cash default ledger state
  const [bankDefaults,     setBankDefaults]     = useState<BankDefaultLedger[]>(() => normalizeLedgerMapping(company?.mapping).bank_default_ledgers      ?? [])
  const [cashDefaults,     setCashDefaults]     = useState<string[]>           (() => normalizeLedgerMapping(company?.mapping).cash_book_default_ledgers  ?? [])
  const [bankKeywordInput, setBankKeywordInput] = useState('')
  const [bankLedgerInput,  setBankLedgerInput]  = useState('')
  const [cashLedgerInput,  setCashLedgerInput]  = useState('')
  const [savingBankCash,   setSavingBankCash]   = useState(false)

  useEffect(() => {
    const m = normalizeLedgerMapping(company?.mapping)
    setMapping(m)
    setBankDefaults(m.bank_default_ledgers      ?? [])
    setCashDefaults(m.cash_book_default_ledgers ?? [])
  }, [company?.mapping]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (company?.voucherType) setVoucherType(company.voucherType)
  }, [company?.voucherType]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    const saved = (company?.mapping as Record<string, string> | null)?.debit_voucher_type
    if (saved !== undefined) setDebitVoucherType(saved)
    const savedCredit = (company?.mapping as Record<string, string> | null)?.credit_voucher_type
    if (savedCredit !== undefined) setCreditVoucherType(savedCredit)
  }, [company?.mapping]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (companyId && storedLedgers.length === 0)     fetchLedgersFromDb(companyId).catch(() => {})
    if (companyId && storedStockItems.length === 0)  fetchStockItemsFromDb(companyId).catch(() => {})
    if (companyId && storedStockGroups.length === 0) fetchStockGroupsFromDb(companyId).catch(() => {})
    if (companyId && storedStockUnits.length === 0)  fetchStockUnitsFromDb(companyId).catch(() => {})
    if (companyId && godownEnabled && storedGodowns.length === 0) fetchGodownsFromDb(companyId).catch(() => {})
    if (companyId && voucherTypes.length === 0) fetchVoucherTypesFromDb(companyId).catch(() => {})
  }, [companyId, godownEnabled]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleSaveTallyUrl = () => {
    localStorage.setItem(`${TALLY_URL_KEY}-${companyId}`, tallyUrl.trim() || DEFAULT_TALLY_URL)
    toast.success('Tally server URL saved')
  }

  const handleSaveVoucherType = async () => {
    try {
      await saveSelectedVoucherType(companyId, voucherType.trim() || DEFAULT_VOUCHER_TYPE)
      toast.success('Voucher type saved')
    } catch {
      toast.error('Failed to save voucher type')
    }
  }

  const handleSaveDebitVoucherType = async () => {
    setSavingDebitVType(true)
    try {
      await saveSelectedDebitVoucherType(companyId, debitVoucherType.trim())
      toast.success('Debit voucher type saved')
    } catch {
      toast.error('Failed to save debit voucher type')
    } finally {
      setSavingDebitVType(false)
    }
  }

  const handleSaveCreditVoucherType = async () => {
    setSavingCreditVType(true)
    try {
      await saveSelectedCreditVoucherType(companyId, creditVoucherType.trim())
      toast.success('Credit voucher type saved')
    } catch {
      toast.error('Failed to save credit voucher type')
    } finally {
      setSavingCreditVType(false)
    }
  }

  const handleFetchVoucherTypes = async () => {
    if (!companyId) return
    setFetchingVTypes(true)
    try {
      const types = await fetchTallyVoucherTypes(getTallyUrl(companyId, company?.port), companyName || undefined)
      if (types.length === 0) { toast.error('No voucher types found'); return }
      setVoucherTypes(types)
      await saveVoucherTypesToDb(companyId, types)
      toast.success(`${types.length} voucher types fetched`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch voucher types')
    } finally {
      setFetchingVTypes(false)
    }
  }

  const handleSyncLedgers = async () => {
    if (!companyId) return
    setSyncing(true)
    try {
      const ledgers = await fetchTallyLedgers(getTallyUrl(companyId, company?.port), companyName || undefined)
      await saveLedgersToDb(companyId, ledgers)
      toast.success(`${ledgers.length} ledgers synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch ledgers. Is Accounting Software running?')
    } finally { setSyncing(false) }
  }

  const handleSyncStockItems = async () => {
    if (!companyId) return
    setSyncingItems(true)
    try {
      const items = await fetchTallyStockItems(getTallyUrl(companyId, company?.port), companyName || undefined)
      await saveStockItemsToDb(companyId, items)
      toast.success(`${items.length} stock items synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch stock items. Is Accounting Software running?')
    } finally { setSyncingItems(false) }
  }

  const handleSyncStockGroups = async () => {
    if (!companyId) return
    setSyncingGroups(true)
    try {
      const groups = await fetchTallyStockGroups(getTallyUrl(companyId, company?.port), companyName || undefined)
      await saveStockGroupsToDb(companyId, groups)
      toast.success(`${groups.length} stock groups synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch stock groups. Is Accounting Software running?')
    } finally { setSyncingGroups(false) }
  }

  const handleSyncStockUnits = async () => {
    if (!companyId) return
    setSyncingUnits(true)
    try {
      const units = await fetchTallyStockUnits(getTallyUrl(companyId, company?.port), companyName || undefined)
      await saveStockUnitsToDb(companyId, units)
      toast.success(`${units.length} stock units synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch stock units. Is Accounting Software running?')
    } finally { setSyncingUnits(false) }
  }

  const handleSyncGodowns = async () => {
    if (!companyId) return
    setSyncingGodowns(true)
    try {
      const godowns = await fetchTallyGodowns(getTallyUrl(companyId, company?.port), companyName || undefined)
      await saveGodownsToDb(companyId, godowns)
      toast.success(`${godowns.length} godowns synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch godowns. Is Accounting Software running?')
    } finally { setSyncingGodowns(false) }
  }

  const set = (key: keyof LedgerMapping) => (v: string) =>
    setMapping((m) => ({ ...m, [key]: v || undefined }))

  const addBankDefault = () => {
    const kw = bankKeywordInput.trim()
    const lg = bankLedgerInput.trim()
    if (!kw || !lg) return
    if (bankDefaults.some((e) => e.keyword.toLowerCase() === kw.toLowerCase())) {
      toast.error('That bank keyword is already mapped')
      return
    }
    setBankDefaults((prev) => [...prev, { keyword: kw, ledger: lg }])
    setBankKeywordInput('')
    setBankLedgerInput('')
  }

  const removeBankDefault = (idx: number) =>
    setBankDefaults((prev) => prev.filter((_, i) => i !== idx))

  const addCashDefault = () => {
    const lg = cashLedgerInput.trim()
    if (!lg) return
    if (cashDefaults.includes(lg)) { toast.error('Ledger already added'); return }
    setCashDefaults((prev) => [...prev, lg])
    setCashLedgerInput('')
  }

  const removeCashDefault = (idx: number) =>
    setCashDefaults((prev) => prev.filter((_, i) => i !== idx))

  const handleSaveBankCash = async () => {
    if (!companyId) return
    setSavingBankCash(true)
    try {
      await updateMapping(companyId, {
        ...normalizeLedgerMapping(company?.mapping),
        bank_default_ledgers:      bankDefaults,
        cash_book_default_ledgers: cashDefaults,
      })
      toast.success('Bank & Cash defaults saved')
    } catch {
      toast.error('Failed to save')
    } finally {
      setSavingBankCash(false)
    }
  }

  const handleSaveMapping = async () => {
    if (!companyId) return
    setSavingMap(true)
    try {
      await updateMapping(companyId, mapping)
      toast.success('Default ledger mapping saved')
    } catch {
      toast.error('Failed to save mapping')
    } finally { setSavingMap(false) }
  }

  return (
    <>
      <PageHeader title="Settings" subtitle="Accounting Software connection and ledger defaults" />

      <div className="p-4 md:p-7 max-w-3xl">
        <div className="card p-6">
          <TabBar active={activeTab} onChange={setActiveTab} showBankCash={showBankCash} />

          {/* ── Tab: Tally Connection ── */}
          {activeTab === 'connection' && (
            <div className="space-y-5">
              <div>
                <ExtensionStatus />
              </div>

              {/* Server URL */}
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
                  Server URL
                </label>
                <div className="flex gap-2">
                  <input
                    value={tallyUrl}
                    onChange={(e) => setTallyUrl(e.target.value)}
                    placeholder="http://localhost:9000"
                    className="input-base flex-1"
                  />
                  <Button variant="outline" size="sm" onClick={handleSaveTallyUrl}>Save</Button>
                </div>
                <p className="text-xs text-gray-500 mt-1">
                  Leave blank to use company port <span className="font-mono">(localhost:{company?.port ?? 9000})</span>.
                </p>
              </div>

              {/* Tally Company Name */}
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
                  Company Name
                </label>
                <input
                  value={companyName}
                  disabled
                  className="input-base w-full bg-gray-100 text-gray-500 cursor-not-allowed"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Automatically set from the selected company. Scopes ledger and stock syncs to this company only.
                </p>
              </div>

              {/* Voucher type */}
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
                  Purchase Voucher Type
                </label>
                <div className="flex gap-2">
                  <input
                    list="voucher-type-list"
                    value={voucherType}
                    onChange={(e) => setVoucherType(e.target.value)}
                    placeholder="GST PURCHASE"
                    className="input-base flex-1"
                  />
                  <datalist id="voucher-type-list">
                    {voucherTypes.map((t) => <option key={t} value={t} />)}
                  </datalist>
                  <Button variant="outline" size="sm" loading={fetchingVTypes} onClick={handleFetchVoucherTypes}>
                    Fetch
                  </Button>
                  <Button variant="outline" size="sm" onClick={handleSaveVoucherType}>Save</Button>
                </div>
                <p className="text-xs text-gray-500 mt-1">
                  Click <strong>Fetch</strong> to load types, then pick one. Must match exactly as it appears in Accounting Software.
                </p>
              </div>

              {/* Debit Voucher Type — only when feature is enabled */}
              {debitVoucherEnabled && (
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
                    Debit Voucher Type
                  </label>
                  <div className="flex gap-2">
                    <input
                      list="debit-voucher-type-list"
                      value={debitVoucherType}
                      onChange={(e) => setDebitVoucherType(e.target.value)}
                      placeholder="Debit Note"
                      className="input-base flex-1"
                    />
                    <datalist id="debit-voucher-type-list">
                      {voucherTypes.map((t) => <option key={t} value={t} />)}
                    </datalist>
                    <Button variant="outline" size="sm" loading={fetchingVTypes} onClick={handleFetchVoucherTypes}>
                      Fetch
                    </Button>
                    <Button variant="outline" size="sm" loading={savingDebitVType} onClick={handleSaveDebitVoucherType}>Save</Button>
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    Voucher type used when creating a Debit Note in Accounting Software. Fetches the same list as Purchase Voucher Type.
                  </p>
                </div>
              )}

              {/* Credit Voucher Type — only when feature is enabled */}
              {creditVoucherEnabled && (
                <div>
                  <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
                    Credit Voucher Type
                  </label>
                  <div className="flex gap-2">
                    <input
                      list="credit-voucher-type-list"
                      value={creditVoucherType}
                      onChange={(e) => setCreditVoucherType(e.target.value)}
                      placeholder="Credit Note"
                      className="input-base flex-1"
                    />
                    <datalist id="credit-voucher-type-list">
                      {voucherTypes.map((t) => <option key={t} value={t} />)}
                    </datalist>
                    <Button variant="outline" size="sm" loading={fetchingVTypes} onClick={handleFetchVoucherTypes}>
                      Fetch
                    </Button>
                    <Button variant="outline" size="sm" loading={savingCreditVType} onClick={handleSaveCreditVoucherType}>Save</Button>
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    Voucher type used when creating a Credit Note in Accounting Software. Fetches the same list as Purchase Voucher Type.
                  </p>
                </div>
              )}

              {/* Tally data sync */}
              <div>
                <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">Data Sync</p>
                <p className="text-xs text-gray-500 mb-3">Sync once — data is saved to DB and available without Accounting Software open.</p>
                <SyncRow label="Ledgers"      count={storedLedgers.length}     loading={syncing}         lastSync={company?.syncTimestamps?.ledgers}     onSync={handleSyncLedgers} />
                <SyncRow label="Stock Items"  count={storedStockItems.length}  loading={syncingItems}    lastSync={company?.syncTimestamps?.stockItems}  onSync={handleSyncStockItems} />
                <SyncRow label="Stock Groups" count={storedStockGroups.length} loading={syncingGroups}   lastSync={company?.syncTimestamps?.stockGroups} onSync={handleSyncStockGroups} />
                <SyncRow label="Stock Units"  count={storedStockUnits.length}  loading={syncingUnits}    lastSync={company?.syncTimestamps?.stockUnits}  onSync={handleSyncStockUnits} />
                {godownEnabled && (
                  <SyncRow label="Godowns" count={storedGodowns.length} loading={syncingGodowns} lastSync={company?.syncTimestamps?.godowns} onSync={handleSyncGodowns} />
                )}
              </div>
            </div>
          )}

          {/* ── Tab: Default Ledgers ── */}
          {activeTab === 'ledgers' && (
            <div>
              <div className="flex items-center justify-between mb-1">
                {company?.mapping && (
                  <span className="flex items-center gap-1 text-xs text-teal-600 font-medium">
                    <CheckCircle className="w-3.5 h-3.5" /> Configured
                  </span>
                )}
              </div>
              <p className="text-xs text-gray-500 mb-5">
                Assign one Accounting Software ledger to each GST category. Used as defaults when syncing bills.
              </p>

              {/* Purchase Ledgers */}
              <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Purchase Ledgers</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-5 mb-5">
                <LedgerSelect label="Interstate 18%"       value={mapping.purchase_interstate_18} ledgerOptions={ledgerOptions} onChange={set('purchase_interstate_18')} />
                <LedgerSelect label="Intra-state 18%"      value={mapping.purchase_up_18}         ledgerOptions={ledgerOptions} onChange={set('purchase_up_18')} />
                <LedgerSelect label="Interstate 5%"        value={mapping.purchase_interstate_5}  ledgerOptions={ledgerOptions} onChange={set('purchase_interstate_5')} />
                <LedgerSelect label="Intra-state 5%"       value={mapping.purchase_up_5}          ledgerOptions={ledgerOptions} onChange={set('purchase_up_5')} />
                <LedgerSelect label="Inter-state 40%"      value={mapping.purchase_interstate_40} ledgerOptions={ledgerOptions} onChange={set('purchase_interstate_40')} />
                <LedgerSelect label="Intra-state 40%"      value={mapping.purchase_up_40}         ledgerOptions={ledgerOptions} onChange={set('purchase_up_40')} />
                <LedgerSelect label="Exempt"               value={mapping.purchase_exempt}        ledgerOptions={ledgerOptions} onChange={set('purchase_exempt')} />
              </div>

              {/* CGST / SGST */}
              <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">CGST / SGST</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-5 mb-5">
                <LedgerSelect label="CGST 9% (18% GST)"    value={mapping.input_cgst_9}   ledgerOptions={ledgerOptions} onChange={set('input_cgst_9')} />
                <LedgerSelect label="SGST 9% (18% GST)"    value={mapping.input_sgst_9}   ledgerOptions={ledgerOptions} onChange={set('input_sgst_9')} />
                <LedgerSelect label="CGST 2.5% (5% GST)"   value={mapping.input_cgst_2_5} ledgerOptions={ledgerOptions} onChange={set('input_cgst_2_5')} />
                <LedgerSelect label="SGST 2.5% (5% GST)"   value={mapping.input_sgst_2_5} ledgerOptions={ledgerOptions} onChange={set('input_sgst_2_5')} />
                <LedgerSelect label="CGST 20% (40% GST)"   value={mapping.input_cgst_20}  ledgerOptions={ledgerOptions} onChange={set('input_cgst_20')} />
                <LedgerSelect label="SGST 20% (40% GST)"   value={mapping.input_sgst_20}  ledgerOptions={ledgerOptions} onChange={set('input_sgst_20')} />
              </div>

              {/* IGST */}
              <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">IGST</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-5 mb-5">
                <LedgerSelect label="IGST 5%"  value={mapping.igst_5}  ledgerOptions={ledgerOptions} onChange={set('igst_5')} />
                <LedgerSelect label="IGST 18%" value={mapping.igst_18} ledgerOptions={ledgerOptions} onChange={set('igst_18')} />
                <LedgerSelect label="IGST 40%" value={mapping.igst_40} ledgerOptions={ledgerOptions} onChange={set('igst_40')} />
              </div>

              {/* Round Off */}
              <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Round Off</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-5 mb-5">
                <LedgerSelect label="Round Off Ledger" value={mapping.roundoff_ledger} ledgerOptions={ledgerOptions} onChange={set('roundoff_ledger')} />
              </div>
              <p className="text-xs text-gray-500 -mt-3 mb-5">
                Defaults to <span className="font-mono">Round Off</span> if blank.
              </p>

              <Button variant="teal" loading={savingMap} onClick={handleSaveMapping}>
                Save Default Mapping
              </Button>
            </div>
          )}

          {/* ── Tab: Bank & Cash Default Ledgers ── */}
          {activeTab === 'bank_cash' && (
            <div className="space-y-8">

              {/* ── Bank Section ── */}
              {bankVoucherEnabled && (
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <Landmark className="w-3.5 h-3.5 text-cyan-600" />
                    <p className="text-xs font-bold text-gray-700 uppercase tracking-wide">Bank Default Ledgers</p>
                  </div>
                  <p className="text-xs text-gray-500 mb-4">
                    Map a bank keyword (e.g. <span className="font-mono">HDFC</span>, <span className="font-mono">ICICI</span>) to a Tally ledger.
                    When you upload a bank statement, the bank ledger is auto-filled if the bank name contains the keyword.
                  </p>

                  {/* Add row */}
                  <div className="flex gap-2 mb-3">
                    <div className="flex-1">
                      <label className="block text-[10px] font-semibold text-gray-500 mb-1 uppercase tracking-wide">Bank Keyword</label>
                      <input
                        value={bankKeywordInput}
                        onChange={(e) => setBankKeywordInput(e.target.value)}
                        placeholder="e.g. HDFC, ICICI, SBI…"
                        className="input-base w-full text-sm"
                        onKeyDown={(e) => e.key === 'Enter' && addBankDefault()}
                      />
                    </div>
                    <div className="flex-[2]">
                      <label className="block text-[10px] font-semibold text-gray-500 mb-1 uppercase tracking-wide">Tally Ledger</label>
                      <input
                        list="bank-default-ledger-list"
                        value={bankLedgerInput}
                        onChange={(e) => setBankLedgerInput(e.target.value)}
                        placeholder="Select ledger…"
                        autoComplete="off"
                        className="input-base w-full text-sm"
                        onKeyDown={(e) => e.key === 'Enter' && addBankDefault()}
                      />
                      <datalist id="bank-default-ledger-list">
                        {ledgerOptions.map((n) => <option key={n} value={n} />)}
                      </datalist>
                    </div>
                    <div className="flex items-end">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={addBankDefault}
                        disabled={!bankKeywordInput.trim() || !bankLedgerInput.trim()}
                      >
                        <Plus className="w-3.5 h-3.5" />
                        Add
                      </Button>
                    </div>
                  </div>

                  {/* Saved entries */}
                  {bankDefaults.length === 0 ? (
                    <p className="text-xs text-gray-400 italic py-2">No bank defaults configured yet.</p>
                  ) : (
                    <div className="rounded-lg border border-gray-200 divide-y divide-gray-100">
                      {bankDefaults.map((entry, idx) => (
                        <div key={idx} className="flex items-center gap-3 px-3 py-2.5">
                          <span className="text-xs font-semibold text-cyan-700 bg-cyan-50 border border-cyan-200 rounded px-2 py-0.5 whitespace-nowrap">
                            {entry.keyword}
                          </span>
                          <span className="text-gray-400 text-xs">→</span>
                          <span className="text-xs text-gray-700 flex-1 truncate">{entry.ledger}</span>
                          <button
                            onClick={() => removeBankDefault(idx)}
                            className="p-1 rounded text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors flex-shrink-0"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* ── Cash Book Section ── */}
              {cashBookEnabled && (
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <BookOpen className="w-3.5 h-3.5 text-emerald-600" />
                    <p className="text-xs font-bold text-gray-700 uppercase tracking-wide">Cash Book Default Ledgers</p>
                  </div>
                  <p className="text-xs text-gray-500 mb-4">
                    Add one or more cash/ledger accounts. The <span className="font-semibold">first entry</span> is automatically
                    pre-filled as the cash ledger when you open any cash book record.
                  </p>

                  {/* Add row */}
                  <div className="flex gap-2 mb-3">
                    <div className="flex-1">
                      <input
                        list="cash-default-ledger-list"
                        value={cashLedgerInput}
                        onChange={(e) => setCashLedgerInput(e.target.value)}
                        placeholder="Select ledger…"
                        autoComplete="off"
                        className="input-base w-full text-sm"
                        onKeyDown={(e) => e.key === 'Enter' && addCashDefault()}
                      />
                      <datalist id="cash-default-ledger-list">
                        {ledgerOptions.map((n) => <option key={n} value={n} />)}
                      </datalist>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={addCashDefault}
                      disabled={!cashLedgerInput.trim()}
                    >
                      <Plus className="w-3.5 h-3.5" />
                      Add
                    </Button>
                  </div>

                  {/* Saved entries */}
                  {cashDefaults.length === 0 ? (
                    <p className="text-xs text-gray-400 italic py-2">No cash book defaults configured yet.</p>
                  ) : (
                    <div className="rounded-lg border border-gray-200 divide-y divide-gray-100">
                      {cashDefaults.map((ledger, idx) => (
                        <div key={idx} className="flex items-center gap-3 px-3 py-2.5">
                          {idx === 0 && (
                            <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 rounded px-1.5 py-0.5 whitespace-nowrap">
                              Default
                            </span>
                          )}
                          <span className="text-xs text-gray-700 flex-1 truncate">{ledger}</span>
                          <button
                            onClick={() => removeCashDefault(idx)}
                            className="p-1 rounded text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors flex-shrink-0"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              <Button variant="teal" loading={savingBankCash} onClick={handleSaveBankCash}>
                Save Bank & Cash Defaults
              </Button>
            </div>
          )}

          {/* ── Tab: Subscription ── */}
          {activeTab === 'subscription' && (() => {
            const used    = company?.parseBillsUsed  ?? 0
            const limit   = company?.parseBillsLimit ?? 50
            const pct     = limit > 0 ? Math.min(100, Math.round((used / limit) * 100)) : 0
            const expiresAt = company?.subscriptionExpiresAt ? new Date(company.subscriptionExpiresAt) : null
            const renewedAt = company?.subscriptionRenewedAt ? new Date(company.subscriptionRenewedAt) : null
            const isExpired = expiresAt && expiresAt < new Date()
            const daysLeft  = expiresAt && !isExpired
              ? Math.ceil((expiresAt.getTime() - Date.now()) / 86400000)
              : null
            const blocked   = company?.parseBlocked

            const barColor  = blocked || isExpired ? 'bg-red-500' :
                              pct >= 90 ? 'bg-red-500' :
                              pct >= 70 ? 'bg-amber-400' : 'bg-teal-500'

            return (
              <div className="space-y-5">
                {/* Status banner */}
                {(blocked || isExpired) && (
                  <div className="flex items-start gap-2.5 p-3 rounded-lg bg-red-50 border border-red-200">
                    <AlertTriangle className="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" />
                    <p className="text-xs text-red-700 font-medium">
                      {blocked ? 'Bill parsing has been disabled for your account.' : 'Your subscription has expired.'}
                      {' '}Please contact your administrator.
                    </p>
                  </div>
                )}
                {daysLeft !== null && daysLeft <= 7 && (
                  <div className="flex items-start gap-2.5 p-3 rounded-lg bg-amber-50 border border-amber-200">
                    <AlertTriangle className="w-4 h-4 text-amber-500 flex-shrink-0 mt-0.5" />
                    <p className="text-xs text-amber-700 font-medium">
                      Your subscription expires in {daysLeft} day{daysLeft !== 1 ? 's' : ''}. Contact your administrator to renew.
                    </p>
                  </div>
                )}

                {/* Usage */}
                <div className="rounded-xl border border-gray-200 p-4 space-y-3">
                  <div className="flex items-center gap-2 mb-1">
                    <CreditCard className="w-3.5 h-3.5 text-teal-600" />
                    <p className="text-xs font-bold text-gray-700 uppercase tracking-wide">Parse Usage This Month</p>
                  </div>
                  <div className="flex items-end justify-between">
                    <span className="text-2xl font-bold text-gray-800">{used}</span>
                    <span className="text-xs text-gray-500 mb-1">of {limit} bills</span>
                  </div>
                  <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div className={cn('h-full rounded-full transition-all', barColor)} style={{ width: `${pct}%` }} />
                  </div>
                  <p className="text-[11px] text-gray-500">{pct}% used — {Math.max(0, limit - used)} remaining</p>
                </div>

                {/* Dates */}
                <div className="space-y-1.5 text-xs text-gray-600">
                  {renewedAt && (
                    <div className="flex justify-between">
                      <span className="text-gray-500">Last renewed</span>
                      <span className="font-medium">{renewedAt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}</span>
                    </div>
                  )}
                  {expiresAt && (
                    <div className="flex justify-between">
                      <span className="text-gray-500">{isExpired ? 'Expired on' : 'Expires on'}</span>
                      <span className={cn('font-medium', isExpired ? 'text-red-600' : daysLeft !== null && daysLeft <= 7 ? 'text-amber-600' : 'text-gray-700')}>
                        {expiresAt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
                      </span>
                    </div>
                  )}
                  {!expiresAt && (
                    <div className="flex justify-between">
                      <span className="text-gray-500">Subscription</span>
                      <span className="font-medium text-teal-600">No expiry (free tier)</span>
                    </div>
                  )}
                </div>

                <p className="text-[11px] text-gray-400 pt-1">
                  To increase your limit or renew your subscription, please contact your administrator.
                </p>
              </div>
            )
          })()}
        </div>
      </div>
    </>
  )
}
