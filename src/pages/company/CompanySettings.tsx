import { useState, useEffect, useRef } from 'react'
import { toast } from 'react-hot-toast'
import { RefreshCw, CheckCircle, X, Plus } from 'lucide-react'
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

// ── Multi-ledger tag row ──────────────────────────────────────────────────────

interface LedgerTagRowProps {
  label: string
  required?: boolean
  values: string[]
  ledgerOptions: string[]
  onChange: (values: string[]) => void
}

function LedgerTagRow({ label, required, values, ledgerOptions, onChange }: LedgerTagRowProps) {
  const [input, setInput] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)
  const listId = `ledger-list-${label.replace(/\s+/g, '-').toLowerCase()}`

  const add = () => {
    const v = input.trim()
    if (!v || values.includes(v)) { setInput(''); return }
    onChange([...values, v])
    setInput('')
    inputRef.current?.focus()
  }

  const remove = (name: string) => onChange(values.filter((v) => v !== name))

  return (
    <div className="mb-5">
      <label className="block text-xs font-semibold text-gray-700 mb-2 tracking-wide uppercase">
        {label}{required && <span className="text-red-500 ml-0.5">*</span>}
      </label>

      {/* Tags */}
      {values.length > 0 && (
        <div className="flex flex-wrap gap-2 mb-2">
          {values.map((name) => (
            <span
              key={name}
              className="inline-flex items-center gap-1.5 px-3 py-1 bg-teal-50 text-teal-800 border border-teal-200 rounded-full text-xs font-medium"
            >
              {name}
              <button
                type="button"
                onClick={() => remove(name)}
                className="hover:text-red-500 transition-colors"
                aria-label={`Remove ${name}`}
              >
                <X className="w-3 h-3" />
              </button>
            </span>
          ))}
        </div>
      )}

      {/* Input + Add */}
      <div className="flex gap-2">
        <input
          ref={inputRef}
          list={listId}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); add() } }}
          placeholder={`Type or select ${label.toLowerCase()}…`}
          autoComplete="off"
          className="input-base flex-1 text-sm"
        />
        <datalist id={listId}>
          {ledgerOptions.filter((o) => !values.includes(o)).map((name) => (
            <option key={name} value={name} />
          ))}
        </datalist>
        <Button type="button" variant="outline" size="sm" onClick={add}>
          <Plus className="w-3.5 h-3.5" />
          Add
        </Button>
      </div>
    </div>
  )
}

// ── Main settings page ────────────────────────────────────────────────────────

export default function CompanySettings() {
  const { user }    = useAuthStore()
  const { getCompany, getLedgers, fetchLedgersFromDb, saveLedgersToDb, updateMapping, getStockItems, setStockItems } = useCompanyStore()
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
      setStockItems(companyId, items)
      toast.success(`${items.length} stock items synced`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch stock items. Is Tally running?')
    } finally {
      setSyncingItems(false)
    }
  }

  const handleSaveMapping = async () => {
    if (!companyId) return
    if (mapping.purchaseLedgers.length === 0) {
      toast.error('At least one purchase ledger is required')
      return
    }
    if (mapping.cgstLedgers.length === 0 || mapping.sgstLedgers.length === 0) {
      toast.error('At least one CGST and one SGST ledger are required')
      return
    }
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

        {/* Default ledger mapping — multi-tag UI */}
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
            Add multiple ledgers for each type — the first one is used as the default when syncing. You can still override per bill.
          </p>

          <LedgerTagRow
            label="Purchase Ledger"
            required
            values={mapping.purchaseLedgers}
            ledgerOptions={ledgerOptions}
            onChange={(v) => setMapping((m) => ({ ...m, purchaseLedgers: v }))}
          />
          <LedgerTagRow
            label="CGST Ledger"
            required
            values={mapping.cgstLedgers}
            ledgerOptions={ledgerOptions}
            onChange={(v) => setMapping((m) => ({ ...m, cgstLedgers: v }))}
          />
          <LedgerTagRow
            label="SGST Ledger"
            required
            values={mapping.sgstLedgers}
            ledgerOptions={ledgerOptions}
            onChange={(v) => setMapping((m) => ({ ...m, sgstLedgers: v }))}
          />
          <LedgerTagRow
            label="IGST Ledger"
            values={mapping.igstLedgers}
            ledgerOptions={ledgerOptions}
            onChange={(v) => setMapping((m) => ({ ...m, igstLedgers: v }))}
          />

          <Button variant="teal" loading={savingMap} onClick={handleSaveMapping}>
            Save Default Mapping
          </Button>
        </div>
      </div>
    </>
  )
}
