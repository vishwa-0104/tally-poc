import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import { useExtensionStatus } from './useExtension'
import { useCompanyStore } from '@/store'
import {
  fetchTallyLedgers,
  fetchTallyStockItems,
  fetchTallyStockGroups,
  fetchTallyStockUnits,
} from '@/services/tallyService'
import { getTallyUrl } from '@/pages/company/CompanySettings'

const STALE_MS = 1 * 60 * 60 * 1000 // ms — set to e.g. 43_200_000 (12 h) for production

function isStale(iso: string | null | undefined): boolean {
  if (!iso) return true
  return Date.now() - new Date(iso).getTime() > STALE_MS
}

/**
 * Silently auto-refreshes Tally master data (ledgers, stock items, groups, units)
 * when the Chrome extension is connected and the cached data is stale.
 *
 * Fires on every page navigation (location change) so new data is pulled
 * whenever the user moves between pages — isStale guards against redundant calls.
 */
export function useAutoSyncTally(companyId: string) {
  const { connected }    = useExtensionStatus()
  const { pathname }     = useLocation()
  const { getCompany, companiesLoaded, saveLedgersToDb, saveStockItemsToDb, saveStockGroupsToDb, saveStockUnitsToDb } = useCompanyStore()

  useEffect(() => {
    if (!connected || !companyId || !companiesLoaded) return

    const company = getCompany(companyId)
    if (!company) return

    const tallyUrl     = getTallyUrl(companyId, company.port)
    const tallyCompany = company.name ?? undefined
    const ts           = (company.syncTimestamps ?? {}) as Record<string, string | null | undefined>

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
  }, [connected, companiesLoaded, pathname]) // eslint-disable-line react-hooks/exhaustive-deps
}
