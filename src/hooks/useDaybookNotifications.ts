import { useEffect, useRef } from 'react'
import { useExtensionStatus } from './useExtension'
import { useCompanyStore } from '@/store'
import {
  fetchDaybook, fetchLedgerBalances, fetchGroupBalances,
  fetchSlowMovingStock, fetchStockValue, fetchLedgerAmounts,
} from '@/services/tallyService'
import { getTallyUrl } from '@/pages/company/CompanySettings'
import { api, fetchDashboardSettings } from '@/lib/api'

const RECONNECT_DELAY_MS = 5000

// Stock value and slow-stock are the heaviest of the "current snapshot"
// queries (O(items × transactions)-style, same class of query background.js
// already documents as able to hang Tally under load) and don't need
// per-edit freshness the way cash/bank/receivables arguably do right after a
// payment/receipt voucher. Module-level (not component state) so the cooldown
// survives the hook remounting, e.g. on a companyId change and back.
const HEAVY_REFRESH_COOLDOWN_MS = 15 * 60 * 1000
const lastHeavyRefreshAt = new Map<string, number>()

function todayYYYYMMDD(): string {
  const d = new Date()
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}${m}${day}`
}

function fmt(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

// Same FY-start rule as Dashboard.tsx's 'ytd' preset (Apr 1 of the current or
// previous calendar year, whichever FY we're currently in).
function ytdRange(): { from: string; to: string } {
  const today = new Date()
  const fyStart = today.getMonth() >= 3
    ? new Date(today.getFullYear(), 3, 1)
    : new Date(today.getFullYear() - 1, 3, 1)
  return { from: fmt(fyStart), to: fmt(today) }
}

function getToken(): string | null {
  const raw = localStorage.getItem('tally-auth')
  if (!raw) return null
  try {
    return JSON.parse(raw)?.state?.token ?? null
  } catch {
    return null
  }
}

/**
 * Listens for a "voucher saved" push from the backend (relayed from Tally's
 * TDL notify hook via WebSocket) and, on receiving it, pulls the Day Book for
 * the day the saved voucher actually belongs to (falls back to today if the
 * server couldn't resolve a date) through the already-working FETCH_DAYBOOK
 * extension message — never through Tally directly, since only the client
 * machine can reach it — then persists the parsed vouchers (append-only, by
 * identityKey/alterId) and refreshes the one cached dashboard snapshot row
 * for this company.
 */
export function useDaybookNotifications(companyId: string) {
  const { connected }                        = useExtensionStatus()
  const { getCompany, companiesLoaded }      = useCompanyStore()
  const connectedRef = useRef(connected)
  connectedRef.current = connected

  useEffect(() => {
    if (!companyId || !companiesLoaded) return

    let ws: WebSocket | null = null
    let reconnectTimer: ReturnType<typeof setTimeout> | null = null
    let closedByCleanup = false

    function connect() {
      const token = getToken()
      if (!token) return

      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
      const url = `${protocol}//${window.location.host}/api/ws?token=${encodeURIComponent(token)}&companyId=${encodeURIComponent(companyId)}`
      ws = new WebSocket(url)

      ws.onmessage = (event) => {
        let msg: { type?: string; date?: string }
        try {
          msg = JSON.parse(event.data)
        } catch {
          return
        }
        if (msg.type !== 'DAYBOOK_TRIGGER') return
        if (!connectedRef.current) {
          console.log('[DaybookNotify] Trigger received but extension not connected — skipping')
          return
        }
        void handleTrigger(msg.date)
      }

      ws.onclose = () => {
        if (closedByCleanup) return
        reconnectTimer = setTimeout(connect, RECONNECT_DELAY_MS)
      }
    }

    // voucherDateYYYYMMDD comes from the server, resolved from the TDL's own
    // ?d= query param on the voucher that was actually saved — so a backdated
    // edit re-fetches the day it belongs to, not always today. Falls back to
    // today if the server couldn't resolve a date (e.g. an un-reloaded TDL, or
    // a malformed date string) — same behavior as before this was wired up.
    async function handleTrigger(voucherDateYYYYMMDD?: string) {
      const company = getCompany(companyId)
      if (!company) return

      const tallyUrl     = getTallyUrl(companyId, company.port)
      const tallyCompany = company.name ?? undefined
      const today        = todayYYYYMMDD()
      const daybookDate    = voucherDateYYYYMMDD && /^\d{8}$/.test(voucherDateYYYYMMDD) ? voucherDateYYYYMMDD : today
      const daybookDateIso = `${daybookDate.slice(0, 4)}-${daybookDate.slice(4, 6)}-${daybookDate.slice(6, 8)}`

      try {
        // Tally's own Day Book export doesn't scope tightly to the date range
        // (can run into tens of MB) — the parsed voucher list (with ledger and
        // inventory entries) is what gets persisted, not the raw XML.
        const { vouchers } = await fetchDaybook(daybookDate, daybookDate, tallyUrl, tallyCompany)
        console.log('[DaybookNotify] fetched', vouchers.length, 'voucher(s) for', daybookDate)
        await api.post(`/companies/${companyId}/vouchers`, { from: daybookDateIso, to: daybookDateIso, vouchers })
      } catch (err) {
        console.error('[DaybookNotify] Failed to fetch/persist Day Book:', err)
      }

      // Refresh the "current snapshot" data too — closing balances/receivables/
      // payables can't be scoped to a past date in Tally, so a save anywhere
      // should refresh the one cached row for this company. Stock value and
      // slow-stock are skipped here if refreshed recently (see
      // HEAVY_REFRESH_COOLDOWN_MS above) — a burst of several voucher saves
      // in a row would otherwise re-run the heaviest queries on every single
      // one, on top of the equally heavy YTD daybook fetch above.
      try {
        const { from: ytdFrom, to: ytdTo } = ytdRange()
        const settings = await fetchDashboardSettings(companyId)

        const lastHeavy = lastHeavyRefreshAt.get(companyId) ?? 0
        const refreshHeavy = Date.now() - lastHeavy >= HEAVY_REFRESH_COOLDOWN_MS
        if (!refreshHeavy) {
          console.log('[DaybookNotify] Skipping stock-value/slow-stock refresh — refreshed within the last', HEAVY_REFRESH_COOLDOWN_MS / 60000, 'min')
        }

        const [balancesRes, groupRes, slowStockRes, ytdStockValueRes, ytdDirectExpRes] = await Promise.allSettled([
          fetchLedgerBalances(tallyUrl, tallyCompany, today),
          fetchGroupBalances(tallyUrl, tallyCompany),
          refreshHeavy ? fetchSlowMovingStock(tallyUrl, tallyCompany) : Promise.resolve(null),
          refreshHeavy ? fetchStockValue(ytdFrom.replace(/-/g, ''), ytdTo.replace(/-/g, ''), tallyUrl, tallyCompany) : Promise.resolve(null),
          fetchLedgerAmounts(ytdFrom.replace(/-/g, ''), ytdTo.replace(/-/g, ''), tallyUrl, tallyCompany, settings.ytd?.directExpenseLedgers),
        ])
        if (refreshHeavy) lastHeavyRefreshAt.set(companyId, Date.now())

        const rawLedgers = balancesRes.status === 'fulfilled' ? balancesRes.value.rawLedgers : []
        const cashInHand = rawLedgers.length
          ? -rawLedgers.filter((l) => l.group.toLowerCase().includes('cash')).reduce((s, l) => s + l.balance, 0)
          : null
        const bankBalance = rawLedgers.length
          ? -rawLedgers.filter((l) => l.group.toLowerCase().includes('bank')).reduce((s, l) => s + l.balance, 0)
          : null

        // Only include the heavy fields when actually refreshed this cycle —
        // sending them as null on a skipped cycle would clobber the last good
        // cached values instead of just leaving them alone.
        const patch: Record<string, unknown> = {
          cashInHand,
          bankBalance,
          receivables:        groupRes.status === 'fulfilled' ? groupRes.value.receivables : null,
          payables:           groupRes.status === 'fulfilled' ? groupRes.value.payables    : null,
          directExpenseTotal: ytdDirectExpRes.status === 'fulfilled' ? ytdDirectExpRes.value : null,
        }
        if (refreshHeavy) {
          patch.openingStock   = ytdStockValueRes.status === 'fulfilled' ? ytdStockValueRes.value?.openingStock ?? null : null
          patch.closingStock   = ytdStockValueRes.status === 'fulfilled' ? ytdStockValueRes.value?.closingStock ?? null : null
          patch.slowStockItems = slowStockRes.status === 'fulfilled' ? slowStockRes.value?.items ?? [] : []
        }

        await api.put(`/companies/${companyId}/dashboard-snapshot`, patch)
      } catch (err) {
        console.error('[DaybookNotify] Failed to refresh dashboard snapshot:', err)
      }
    }

    connect()

    return () => {
      closedByCleanup = true
      if (reconnectTimer) clearTimeout(reconnectTimer)
      ws?.close()
    }
  }, [companyId, companiesLoaded]) // eslint-disable-line react-hooks/exhaustive-deps
}
