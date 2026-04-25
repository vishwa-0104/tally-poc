import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { RefreshCw, CheckCircle } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { Button } from '@/components/ui/Button'
import { useAuthStore, useCompanyStore } from '@/store'
import { fetchTallyGodowns, fetchTallyLedgers, fetchTallyStockItems, fetchTallyStockGroups, fetchTallyStockUnits } from '@/services/tallyService'
import { COMPANY_FEATURES, normalizeLedgerMapping } from '@/types'
import type { LedgerMapping } from '@/types'

export const TALLY_URL_KEY         = 'tally-server-url'
export const DEFAULT_TALLY_URL     = 'http://localhost:9000'
export const TALLY_VOUCHER_TYPE_KEY = 'tally-voucher-type'
export const DEFAULT_VOUCHER_TYPE  = 'GST PURCHASE'


/** Returns the effective Tally URL.
 *  Priority: localStorage manual override → company port from DB → localhost:9000 */
export function getTallyUrl(companyId: string, companyPort?: number): string {
  const override = localStorage.getItem(`${TALLY_URL_KEY}-${companyId}`)
  if (override) return override
  if (companyPort) return `http://localhost:${companyPort}`
  return DEFAULT_TALLY_URL
}
export function getTallyVoucherType(companyId: string): string { return localStorage.getItem(`${TALLY_VOUCHER_TYPE_KEY}-${companyId}`) || DEFAULT_VOUCHER_TYPE }

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

type Tab = 'connection' | 'ledgers'

interface TabBarProps {
  active: Tab
  onChange: (t: Tab) => void
}

function TabBar({ active, onChange }: TabBarProps) {
  const tabs: { id: Tab; label: string }[] = [
    { id: 'connection', label: 'Tally Connection' },
    { id: 'ledgers',    label: 'Default Ledgers' },
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
  const { getCompany, getLedgers, fetchLedgersFromDb, saveLedgersToDb, updateMapping, getStockItems, fetchStockItemsFromDb, saveStockItemsToDb, getStockGroups, fetchStockGroupsFromDb, saveStockGroupsToDb, getStockUnits, fetchStockUnitsFromDb, saveStockUnitsToDb, getGodowns, fetchGodownsFromDb, saveGodownsToDb } = useCompanyStore()
  const company     = activeCompanyId ? getCompany(activeCompanyId) : null
  const companyId   = activeCompanyId ?? ''
  const companyName = company?.name ?? authCompanies.find((c) => c.id === activeCompanyId)?.name ?? ''

  const godownEnabled = company?.features?.some((f) => f.feature === COMPANY_FEATURES.GODOWN && f.enabled) ?? false

  const [activeTab,      setActiveTab]      = useState<Tab>('connection')
  const [syncing,        setSyncing]        = useState(false)
  const [syncingItems,   setSyncingItems]   = useState(false)
  const [syncingGroups,  setSyncingGroups]  = useState(false)
  const [syncingUnits,   setSyncingUnits]   = useState(false)
  const [syncingGodowns, setSyncingGodowns] = useState(false)
  const [savingMap,      setSavingMap]      = useState(false)
  const [tallyUrl,    setTallyUrl]    = useState(() => getTallyUrl(companyId, company?.port))
  const [voucherType, setVoucherType] = useState(() => getTallyVoucherType(companyId))

  const storedLedgers     = companyId ? getLedgers(companyId)     : []
  const storedStockItems  = companyId ? getStockItems(companyId)  : []
  const storedStockGroups = companyId ? getStockGroups(companyId) : []
  const storedStockUnits  = companyId ? getStockUnits(companyId)  : []
  const storedGodowns     = companyId ? getGodowns(companyId)     : []
  const ledgerOptions     = storedLedgers.map((l) => l.name)

  const [mapping, setMapping] = useState<LedgerMapping>(() => normalizeLedgerMapping(company?.mapping))

  useEffect(() => {
    setMapping(normalizeLedgerMapping(company?.mapping))
  }, [company?.mapping]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (companyId && storedLedgers.length === 0)     fetchLedgersFromDb(companyId).catch(() => {})
    if (companyId && storedStockItems.length === 0)  fetchStockItemsFromDb(companyId).catch(() => {})
    if (companyId && storedStockGroups.length === 0) fetchStockGroupsFromDb(companyId).catch(() => {})
    if (companyId && storedStockUnits.length === 0)  fetchStockUnitsFromDb(companyId).catch(() => {})
    if (companyId && godownEnabled && storedGodowns.length === 0) fetchGodownsFromDb(companyId).catch(() => {})
  }, [companyId, godownEnabled]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleSaveTallyUrl = () => {
    localStorage.setItem(`${TALLY_URL_KEY}-${companyId}`, tallyUrl.trim() || DEFAULT_TALLY_URL)
    toast.success('Tally server URL saved')
  }

  const handleSaveVoucherType = () => {
    localStorage.setItem(`${TALLY_VOUCHER_TYPE_KEY}-${companyId}`, voucherType.trim() || DEFAULT_VOUCHER_TYPE)
    toast.success('Voucher type saved')
  }

  const handleSyncLedgers = async () => {
    if (!companyId) return
    setSyncing(true)
    try {
      const ledgers = await fetchTallyLedgers(getTallyUrl(companyId, company?.port), companyName || undefined)
      await saveLedgersToDb(companyId, ledgers)
      toast.success(`${ledgers.length} ledgers synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch ledgers. Is Tally running?')
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
      toast.error(err instanceof Error ? err.message : 'Failed to fetch stock items. Is Tally running?')
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
      toast.error(err instanceof Error ? err.message : 'Failed to fetch stock groups. Is Tally running?')
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
      toast.error(err instanceof Error ? err.message : 'Failed to fetch stock units. Is Tally running?')
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
      toast.error(err instanceof Error ? err.message : 'Failed to fetch godowns. Is Tally running?')
    } finally { setSyncingGodowns(false) }
  }

  const set = (key: keyof LedgerMapping) => (v: string) =>
    setMapping((m) => ({ ...m, [key]: v || undefined }))

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
      <PageHeader title="Settings" subtitle="Tally connection and ledger defaults" />

      <div className="p-4 md:p-7 max-w-3xl">
        <div className="card p-6">
          <TabBar active={activeTab} onChange={setActiveTab} />

          {/* ── Tab: Tally Connection ── */}
          {activeTab === 'connection' && (
            <div className="space-y-5">
              <div>
                <ExtensionStatus />
              </div>

              {/* Server URL */}
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
                  Tally Server URL
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
                  Leave blank to use company port <span className="font-mono">(localhost:{company?.port ?? 9000})</span>. Set only for ngrok or remote Tally.
                </p>
              </div>

              {/* Tally Company Name */}
              <div>
                <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide">
                  Tally Company Name
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
                    value={voucherType}
                    onChange={(e) => setVoucherType(e.target.value)}
                    placeholder="GST PURCHASE"
                    className="input-base flex-1"
                  />
                  <Button variant="outline" size="sm" onClick={handleSaveVoucherType}>Save</Button>
                </div>
                <p className="text-xs text-gray-500 mt-1">
                  Must match exactly as it appears in Tally (e.g. <span className="font-mono">GST PURCHASE</span>).
                </p>
              </div>

              {/* Tally data sync */}
              <div>
                <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">Tally Data Sync</p>
                <p className="text-xs text-gray-500 mb-3">Sync once — data is saved to DB and available without Tally open.</p>
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
                Assign one Tally ledger to each GST category. Used as defaults when syncing bills.
              </p>

              {/* Purchase Ledgers */}
              <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Purchase Ledgers</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-5 mb-5">
                <LedgerSelect label="Interstate 18%"       value={mapping.purchase_interstate_18} ledgerOptions={ledgerOptions} onChange={set('purchase_interstate_18')} />
                <LedgerSelect label="Interstate 5%"        value={mapping.purchase_interstate_5}  ledgerOptions={ledgerOptions} onChange={set('purchase_interstate_5')} />
                <LedgerSelect label="Intra-state 18%"      value={mapping.purchase_up_18}         ledgerOptions={ledgerOptions} onChange={set('purchase_up_18')} />
                <LedgerSelect label="Intra-state 5%"       value={mapping.purchase_up_5}          ledgerOptions={ledgerOptions} onChange={set('purchase_up_5')} />
                <LedgerSelect label="Exempt"               value={mapping.purchase_exempt}        ledgerOptions={ledgerOptions} onChange={set('purchase_exempt')} />
              </div>

              {/* CGST / SGST */}
              <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">CGST / SGST</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-5 mb-5">
                <LedgerSelect label="CGST 9% (18% GST)"   value={mapping.input_cgst_9}   ledgerOptions={ledgerOptions} onChange={set('input_cgst_9')} />
                <LedgerSelect label="SGST 9% (18% GST)"   value={mapping.input_sgst_9}   ledgerOptions={ledgerOptions} onChange={set('input_sgst_9')} />
                <LedgerSelect label="CGST 2.5% (5% GST)"  value={mapping.input_cgst_2_5} ledgerOptions={ledgerOptions} onChange={set('input_cgst_2_5')} />
                <LedgerSelect label="SGST 2.5% (5% GST)"  value={mapping.input_sgst_2_5} ledgerOptions={ledgerOptions} onChange={set('input_sgst_2_5')} />
              </div>

              {/* IGST */}
              <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">IGST</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-5 mb-5">
                <LedgerSelect label="IGST 5%"  value={mapping.igst_5}  ledgerOptions={ledgerOptions} onChange={set('igst_5')} />
                <LedgerSelect label="IGST 18%" value={mapping.igst_18} ledgerOptions={ledgerOptions} onChange={set('igst_18')} />
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
        </div>
      </div>
    </>
  )
}
