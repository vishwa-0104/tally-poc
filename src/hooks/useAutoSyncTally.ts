import { useEffect, useRef } from 'react'
import { useExtensionStatus } from './useExtension'
import { useCompanyStore } from '@/store'
import {
  fetchTallyLedgers,
  fetchTallyStockItems,
  fetchTallyStockGroups,
  fetchTallyStockUnits,
} from '@/services/tallyService'
import { getTallyUrl } from '@/pages/company/CompanySettings'

const STALE_MS = 1000 // 1 hour

function isStale(iso: string | null | undefined): boolean {
  if (!iso) return true
  return Date.now() - new Date(iso).getTime() > STALE_MS
}

/**
 * Silently auto-refreshes Tally master data (ledgers, stock items, groups, units)
 * when the Chrome extension is connected and the cached data is older than 12 hours.
 *
 * Rules:
 * - Only fires when the extension responds to PING (Tally is reachable).
 * - Each data type is fetched independently — one failure doesn't block others.
 * - The timestamp is only updated on successful save, so failures are retried
 *   on the next session without any extra bookkeeping.
 * - Fires at most once per CompanyLayout mount (guarded by hasFiredRef).
 */
export function useAutoSyncTally(companyId: string) {
  const { connected }  = useExtensionStatus()
  const { getCompany, companiesLoaded, saveLedgersToDb, saveStockItemsToDb, saveStockGroupsToDb, saveStockUnitsToDb } = useCompanyStore()
  const hasFiredRef = useRef(false)

  useEffect(() => {
    if (!connected || !companyId || !companiesLoaded) return
    if (hasFiredRef.current) return
    hasFiredRef.current = true

    const company = getCompany(companyId)
    if (!company) return

    const tallyUrl     = getTallyUrl(companyId, company.port)
    const tallyCompany = company.name ?? undefined
    const ts           = (company.syncTimestamps ?? {}) as Record<string, string | null | undefined>

    console.log("logging timestamps for company", companyId, ts, isStale(ts.ledgers))

    if (isStale(ts.ledgers)) {
      fetchTallyLedgers(tallyUrl, tallyCompany)
        .then((data) => saveLedgersToDb(companyId, data))
        .catch(() => {})
    }

    if (isStale(ts.stockItems)) {
      fetchTallyStockItems(tallyUrl, tallyCompany)
        .then((data) => saveStockItemsToDb(companyId, data))
        .catch(() => {})
    }

    if (isStale(ts.stockGroups)) {
      fetchTallyStockGroups(tallyUrl, tallyCompany)
        .then((data) => saveStockGroupsToDb(companyId, data))
        .catch(() => {})
    }

    if (isStale(ts.stockUnits)) {
      fetchTallyStockUnits(tallyUrl, tallyCompany)
        .then((data) => saveStockUnitsToDb(companyId, data))
        .catch(() => {})
    }
  }, [connected, companiesLoaded]) // eslint-disable-line react-hooks/exhaustive-deps
}
