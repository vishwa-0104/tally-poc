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
 * TDL notify hook via WebSocket) and, on receiving it, pulls today's Day Book
 * through the already-working FETCH_DAYBOOK extension message — never
 * through Tally directly, since only the client machine can reach it — then
 * persists the parsed vouchers (append-only, by identityKey/alterId) and
 * refreshes the one cached dashboard snapshot row for this company.
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
        let msg: { type?: string }
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
        void handleTrigger()
      }

      ws.onclose = () => {
        if (closedByCleanup) return
        reconnectTimer = setTimeout(connect, RECONNECT_DELAY_MS)
      }
    }

    async function handleTrigger() {
      const company = getCompany(companyId)
      if (!company) return

      const tallyUrl     = getTallyUrl(companyId, company.port)
      const tallyCompany = company.name ?? undefined
      const today        = todayYYYYMMDD()
      const todayIso      = new Date().toISOString().slice(0, 10)

      try {
        // Tally's own Day Book export doesn't scope tightly to the date range
        // (can run into tens of MB) — the parsed voucher list (with ledger and
        // inventory entries) is what gets persisted, not the raw XML.
        const { vouchers } = await fetchDaybook(today, today, tallyUrl, tallyCompany)
        console.log('[DaybookNotify] fetched', vouchers.length, 'voucher(s) for', today)
        await api.post(`/companies/${companyId}/vouchers`, { from: todayIso, to: todayIso, vouchers })
      } catch (err) {
        console.error('[DaybookNotify] Failed to fetch/persist Day Book:', err)
      }

      // Refresh the "current snapshot" data too — closing balances/receivables/
      // payables/slow-stock/stock-value can't be scoped to a past date in Tally,
      // so a save anywhere should refresh the one cached row for this company.
      try {
        const { from: ytdFrom, to: ytdTo } = ytdRange()
        const settings = await fetchDashboardSettings(companyId)

        const [balancesRes, groupRes, slowStockRes, ytdStockValueRes, ytdDirectExpRes] = await Promise.allSettled([
          fetchLedgerBalances(tallyUrl, tallyCompany, today),
          fetchGroupBalances(tallyUrl, tallyCompany),
          fetchSlowMovingStock(tallyUrl, tallyCompany),
          fetchStockValue(ytdFrom.replace(/-/g, ''), ytdTo.replace(/-/g, ''), tallyUrl, tallyCompany),
          fetchLedgerAmounts(ytdFrom.replace(/-/g, ''), ytdTo.replace(/-/g, ''), tallyUrl, tallyCompany, settings.ytd?.directExpenseLedgers),
        ])

        const rawLedgers = balancesRes.status === 'fulfilled' ? balancesRes.value.rawLedgers : []
        const cashInHand = rawLedgers.length
          ? -rawLedgers.filter((l) => l.group.toLowerCase().includes('cash')).reduce((s, l) => s + l.balance, 0)
          : null
        const bankBalance = rawLedgers.length
          ? -rawLedgers.filter((l) => l.group.toLowerCase().includes('bank')).reduce((s, l) => s + l.balance, 0)
          : null

        await api.put(`/companies/${companyId}/dashboard-snapshot`, {
          cashInHand,
          bankBalance,
          receivables:        groupRes.status === 'fulfilled' ? groupRes.value.receivables : null,
          payables:           groupRes.status === 'fulfilled' ? groupRes.value.payables    : null,
          openingStock:       ytdStockValueRes.status === 'fulfilled' ? ytdStockValueRes.value.openingStock : null,
          closingStock:       ytdStockValueRes.status === 'fulfilled' ? ytdStockValueRes.value.closingStock : null,
          directExpenseTotal: ytdDirectExpRes.status === 'fulfilled' ? ytdDirectExpRes.value : null,
          slowStockItems:     slowStockRes.status === 'fulfilled' ? slowStockRes.value.items : [],
        })
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
