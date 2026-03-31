import { useState, useEffect } from 'react'
import { toast } from 'react-hot-toast'
import { RefreshCw, CheckCircle } from 'lucide-react'
import { PageHeader } from '@/components/shared'
import { ExtensionStatus } from '@/components/shared/ExtensionStatus'
import { Button } from '@/components/ui/Button'
import { useAuthStore, useCompanyStore } from '@/store'
import { fetchTallyLedgers } from '@/services/tallyService'

export const TALLY_URL_KEY = 'tally-server-url'
export const DEFAULT_TALLY_URL = 'http://localhost:9000'

export function getTallyUrl(): string {
  return localStorage.getItem(TALLY_URL_KEY) || DEFAULT_TALLY_URL
}

export default function CompanySettings() {
  const { user }     = useAuthStore()
  const { getCompany, getLedgers, fetchLedgersFromDb, saveLedgersToDb, updateMapping } = useCompanyStore()
  const company      = user?.companyId ? getCompany(user.companyId) : null
  const companyId    = user?.companyId ?? ''

  const [syncing, setSyncing]     = useState(false)
  const [savingMap, setSavingMap] = useState(false)
  const [tallyUrl, setTallyUrl]   = useState(getTallyUrl)

  const storedLedgers = companyId ? getLedgers(companyId) : []
  const ledgerOptions = storedLedgers.map((l) => l.name)

  const [mapping, setMapping] = useState({
    purchase: company?.mapping?.purchase ?? '',
    cgst:     company?.mapping?.cgst     ?? '',
    sgst:     company?.mapping?.sgst     ?? '',
    igst:     company?.mapping?.igst     ?? '',
  })

  // Load ledgers from DB on mount if not already in memory
  useEffect(() => {
    if (companyId && storedLedgers.length === 0) {
      fetchLedgersFromDb(companyId).catch(() => {})
    }
  }, [companyId]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleSaveTallyUrl = () => {
    localStorage.setItem(TALLY_URL_KEY, tallyUrl.trim() || DEFAULT_TALLY_URL)
    toast.success('Tally server URL saved')
  }

  const handleSyncLedgers = async () => {
    if (!companyId) return
    setSyncing(true)
    try {
      const ledgers = await fetchTallyLedgers(getTallyUrl())
      console.log(">>>>>>. fetching ledgerssss ", ledgers, companyId)
      await saveLedgersToDb(companyId, ledgers)
      toast.success(`${ledgers.length} ledgers synced and saved`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to fetch ledgers. Is Tally running?')
    } finally {
      setSyncing(false)
    }
  }

  const handleSaveMapping = async () => {
    if (!companyId) return
    if (!mapping.purchase || !mapping.cgst || !mapping.sgst) {
      toast.error('Purchase, CGST and SGST ledgers are required')
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
        </div>

        {/* Default ledger mapping */}
        <div className="card p-6">
          <div className="flex items-center justify-between mb-1">
            <h2 className="text-sm font-bold text-gray-800">Default Ledger Mapping</h2>
            {company?.mapping && (
              <span className="flex items-center gap-1 text-xs text-teal-600 font-medium">
                <CheckCircle className="w-3.5 h-3.5" /> Configured
              </span>
            )}
          </div>
          <p className="text-xs text-gray-400 mb-4">
            These will pre-fill the ledger dropdowns on every bill. You can still change them per bill.
          </p>

          {(['purchase', 'cgst', 'sgst', 'igst'] as const).map((key) => (
            <div key={key} className="mb-4">
              <label className="block text-xs font-semibold text-gray-700 mb-1.5 tracking-wide uppercase">
                {key} Ledger{key !== 'igst' && ' *'}
              </label>
              <input
                list={`${key}-list`}
                value={mapping[key]}
                onChange={(e) => setMapping((m) => ({ ...m, [key]: e.target.value }))}
                placeholder={`Type or select ${key.toUpperCase()} ledger…`}
                autoComplete="off"
                className="input-base"
              />
              <datalist id={`${key}-list`}>
                {ledgerOptions.map((name) => <option key={name} value={name} />)}
              </datalist>
            </div>
          ))}

          <Button variant="teal" loading={savingMap} onClick={handleSaveMapping}>
            Save Default Mapping
          </Button>
        </div>
      </div>
    </>
  )
}
