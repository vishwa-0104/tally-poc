import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { RefreshCw, CheckCircle } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { Button } from '@/components/ui/Button'
import { useAuthStore, useCompanyStore } from '@/store'
import { fetchTallyLedgers, fetchTallyStockItems } from '@/services/tallyService'
import { normalizeLedgerMapping } from '@/types'
import type { LedgerMapping } from '@/types'

export const TALLY_URL_KEY         = 'tally-server-url'
export const DEFAULT_TALLY_URL     = 'http://localhost:9000'
export const TALLY_COMPANY_KEY     = 'tally-company-name'
export const TALLY_VOUCHER_TYPE_KEY = 'tally-voucher-type'
export const DEFAULT_VOUCHER_TYPE  = 'GST PURCHASE'

export function getTallyUrl():         string { return localStorage.getItem(TALLY_URL_KEY)          || DEFAULT_TALLY_URL }
export function getTallyCompanyName(): string { return localStorage.getItem(TALLY_COMPANY_KEY)      ?? '' }
export function getTallyVoucherType(): string { return localStorage.getItem(TALLY_VOUCHER_TYPE_KEY) || DEFAULT_VOUCHER_TYPE }

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
    <div className="flex items-center gap-3 mb-3">
      <label htmlFor={id} className="text-xs font-medium text-gray-600 w-44 shrink-0">{label}</label>
      <input
        id={id}
        list={`${id}-list`}
        value={value ?? ''}
        onChange={(e) => onChange(e.target.value)}
        autoComplete="off"
        placeholder="Type or select…"
        className="input-base flex-1 text-sm"
      />
      <datalist id={`${id}-list`}>
        {ledgerOptions.map((name) => <option key={name} value={name} />)}
      </datalist>
    </div>
  )
}

// ── Main settings page ────────────────────────────────────────────────────────

export default function CompanySettings() {
  const { user }    = useAuthStore()
  const { getCompany, getLedgers, fetchLedgersFromDb, saveLedgersToDb, updateMapping, getStockItems, fetchStockItemsFromDb, saveStockItemsToDb } = useCompanyStore()
  const company     = user?.companyId ? getCompany(user.companyId) : null
  const companyId   = user?.companyId ?? ''

  const [syncing,      setSyncing]      = useState(false)
  const [syncingItems, setSyncingItems] = useState(false)
  const [savingMap,    setSavingMap]    = useState(false)
  const [tallyUrl,     setTallyUrl]     = useState(getTallyUrl)
  const [voucherType,  setVoucherType]  = useState(getTallyVoucherType)

  const storedLedgers    = companyId ? getLedgers(companyId)    : []
  const storedStockItems = companyId ? getStockItems(companyId) : []
  const ledgerOptions    = storedLedgers.map((l) => l.name)

  const [mapping, setMapping] = useState<LedgerMapping>(() => normalizeLedgerMapping(company?.mapping))

  // Refresh mapping when company data loads
  useEffect(() => {
    setMapping(normalizeLedgerMapping(company?.mapping))
  }, [company?.mapping]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (companyId && storedLedgers.length === 0) {
      fetchLedgersFromDb(companyId).catch(() => {})
    }
    if (companyId && storedStockItems.length === 0) {
      fetchStockItemsFromDb(companyId).catch(() => {})
    }
  }, [companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleSaveTallyUrl = () => {
    localStorage.setItem(TALLY_URL_KEY, tallyUrl.trim() || DEFAULT_TALLY_URL)
    toast.success('Tally server URL saved')
  }

  const handleSaveVoucherType = () => {
    localStorage.setItem(TALLY_VOUCHER_TYPE_KEY, voucherType.trim() || DEFAULT_VOUCHER_TYPE)
    toast.success('Voucher type saved')
  }

  const handleSyncLedgers = async () => {
    if (!companyId) return
    setSyncing(true)
    try {
      const ledgers = await fetchTallyLedgers(getTallyUrl())
      await saveLedgersToDb(companyId, ledgers)
      toast.success(`${ledgers.length} ledgers synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch ledgers. Is Tally running?')
    } finally {
      setSyncing(false)
    }
  }

  const handleSyncStockItems = async () => {
    if (!companyId) return
    setSyncingItems(true)
    try {
      const items = await fetchTallyStockItems(getTallyUrl())
      await saveStockItemsToDb(companyId, items)
      toast.success(`${items.length} stock items synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch stock items. Is Tally running?')
    } finally {
      setSyncingItems(false)
    }
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
    } finally {
      setSavingMap(false)
    }
  }

  return (
    <>
      <PageHeader title="Settings" subtitle="Tally connection and AI configuration" />

      <div className="p-7 max-w-lg space-y-5">
        {/* Tally connection */}
        <div className="card p-6">
          <h2 className="text-sm font-bold text-gray-800 mb-4">Tally Connection</h2>
          <div className="mb-4">
            <ExtensionStatus />
          </div>

          {/* Tally server URL */}
          <div className="mb-4">
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
              <Button variant="outline" size="sm" onClick={handleSaveTallyUrl}>
                Save
              </Button>
            </div>
            <p className="text-xs text-gray-400 mt-1">
              Use <span className="font-mono">http://localhost:9000</span> for local Tally, or your ngrok URL e.g. <span className="font-mono">https://baz.ngrok.dev</span>
            </p>
          </div>

          {/* Purchase voucher type */}
          <div className="mb-4">
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
              <Button variant="outline" size="sm" onClick={handleSaveVoucherType}>
                Save
              </Button>
            </div>
            <p className="text-xs text-gray-400 mt-1">
              Must match exactly as it appears in Tally (e.g. <span className="font-mono">GST PURCHASE</span> or <span className="font-mono">Purchase</span>).
            </p>
          </div>

          {/* Ledger sync */}
          <div className="mt-2">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-gray-700">Tally Ledgers</span>
              {storedLedgers.length > 0 && (
                <span className="flex items-center gap-1 text-xs text-teal-600 font-medium">
                  <CheckCircle className="w-3.5 h-3.5" />
                  {storedLedgers.length} ledgers synced
                </span>
              )}
            </div>
            <Button variant="outline" size="sm" loading={syncing} onClick={handleSyncLedgers} className="w-full">
              <RefreshCw className="w-3.5 h-3.5" />
              {storedLedgers.length > 0 ? 'Refresh Ledgers from Tally' : 'Sync Ledgers from Tally'}
            </Button>
            {storedLedgers.length === 0 && (
              <p className="text-xs text-gray-400 mt-1.5">
                Sync ledgers once — they'll be saved to the database and available without Tally open.
              </p>
            )}
          </div>

          {/* Stock item sync */}
          <div className="mt-4 pt-4 border-t border-gray-100">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-gray-700">Tally Stock Items</span>
              {storedStockItems.length > 0 && (
                <span className="flex items-center gap-1 text-xs text-teal-600 font-medium">
                  <CheckCircle className="w-3.5 h-3.5" />
                  {storedStockItems.length} items synced
                </span>
              )}
            </div>
            <Button variant="outline" size="sm" loading={syncingItems} onClick={handleSyncStockItems} className="w-full">
              <RefreshCw className="w-3.5 h-3.5" />
              {storedStockItems.length > 0 ? 'Refresh Stock Items from Tally' : 'Sync Stock Items from Tally'}
            </Button>
            {storedStockItems.length === 0 && (
              <p className="text-xs text-gray-400 mt-1.5">
                Sync stock items to enable per-line-item mapping in purchase bills.
              </p>
            )}
          </div>
        </div>

        {/* Default ledger mapping — 1:1 static dropdowns */}
        <div className="card p-6">
          <div className="flex items-center justify-between mb-1">
            <h2 className="text-sm font-bold text-gray-800">Default Ledger Mapping</h2>
            {company?.mapping && (
              <span className="flex items-center gap-1 text-xs text-teal-600 font-medium">
                <CheckCircle className="w-3.5 h-3.5" /> Configured
              </span>
            )}
          </div>
          <p className="text-xs text-gray-400 mb-5">
            Assign one Tally ledger to each GST category. These are used as defaults when syncing bills.
          </p>

          {/* Purchase Ledgers */}
          <div className="mb-5">
            <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Purchase Ledgers</p>
            <LedgerSelect label="Interstate 18%"        value={mapping.purchase_interstate_18} ledgerOptions={ledgerOptions} onChange={set('purchase_interstate_18')} />
            <LedgerSelect label="Interstate 5%"         value={mapping.purchase_interstate_5}  ledgerOptions={ledgerOptions} onChange={set('purchase_interstate_5')} />
            <LedgerSelect label="UP (Intra-state) 18%"  value={mapping.purchase_up_18}         ledgerOptions={ledgerOptions} onChange={set('purchase_up_18')} />
            <LedgerSelect label="UP (Intra-state) 5%"   value={mapping.purchase_up_5}          ledgerOptions={ledgerOptions} onChange={set('purchase_up_5')} />
            <LedgerSelect label="Exempt"                value={mapping.purchase_exempt}        ledgerOptions={ledgerOptions} onChange={set('purchase_exempt')} />
          </div>

          {/* CGST / SGST */}
          <div className="mb-5">
            <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">CGST / SGST</p>

            <p className="text-xs text-gray-500 mb-2 font-medium">@ 9% each (18% GST)</p>
            <LedgerSelect label="CGST 9%"   value={mapping.input_cgst_9}   ledgerOptions={ledgerOptions} onChange={set('input_cgst_9')} />
            <LedgerSelect label="SGST 9%"   value={mapping.input_sgst_9}   ledgerOptions={ledgerOptions} onChange={set('input_sgst_9')} />

            <p className="text-xs text-gray-500 mt-3 mb-2 font-medium">@ 2.5% each (5% GST)</p>
            <LedgerSelect label="CGST 2.5%" value={mapping.input_cgst_2_5} ledgerOptions={ledgerOptions} onChange={set('input_cgst_2_5')} />
            <LedgerSelect label="SGST 2.5%" value={mapping.input_sgst_2_5} ledgerOptions={ledgerOptions} onChange={set('input_sgst_2_5')} />
          </div>

          {/* IGST */}
          <div className="mb-5">
            <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">IGST</p>
            <LedgerSelect label="IGST 5%"  value={mapping.igst_5}  ledgerOptions={ledgerOptions} onChange={set('igst_5')} />
            <LedgerSelect label="IGST 18%" value={mapping.igst_18} ledgerOptions={ledgerOptions} onChange={set('igst_18')} />
          </div>

          {/* Round Off */}
          <div className="mb-5">
            <p className="text-xs font-bold text-gray-700 uppercase tracking-wide mb-3">Round Off</p>
            <LedgerSelect label="Round Off Ledger" value={mapping.roundoff_ledger} ledgerOptions={ledgerOptions} onChange={set('roundoff_ledger')} />
            <p className="text-xs text-gray-400 -mt-1">
              Used as the ledger name in Tally for round-off entries. Defaults to <span className="font-mono">Round Off</span> if blank.
            </p>
          </div>

          <Button variant="teal" loading={savingMap} onClick={handleSaveMapping}>
            Save Default Mapping
          </Button>
        </div>
      </div>
    </>
  )
}
