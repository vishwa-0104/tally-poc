import { useEffect, useRef } from 'react'
import { useExtensionStatus } from './useExtension'
import { useCompanyStore } from '@/store'
import { fetchDaybook } from '@/services/tallyService'
import { getTallyUrl } from '@/pages/company/CompanySettings'
import { api } from '@/lib/api'

const RECONNECT_DELAY_MS = 5000

function todayYYYYMMDD(): string {
  const d = new Date()
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}${m}${day}`
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
 * hands the raw XML to the backend to log.
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

      try {
        const { vouchers, rawXml } = await fetchDaybook(today, today, tallyUrl, tallyCompany)
        console.log('[DaybookNotify] fetched — vouchers:', vouchers.length, '| rawXml length:', rawXml.length, 'chars')
        await api.post(`/companies/${companyId}/daybook-log`, { rawXml })
      } catch (err) {
        console.error('[DaybookNotify] Failed to fetch/log Day Book:', err)
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
