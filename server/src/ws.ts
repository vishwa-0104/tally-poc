import type { Server as HttpServer } from 'http'
import jwt from 'jsonwebtoken'
import { WebSocketServer, WebSocket } from 'ws'
import { canAccessCompany, type AuthPayload } from './middleware/auth'

const WS_PATH = '/api/ws'

const companySockets = new Map<string, Set<WebSocket>>()

// A Tally save can happen while nobody's browser tab is connected (dashboard
// closed, tab not open, or mid-reconnect) — notifyCompany used to just log
// "nothing to notify" and drop the trigger entirely in that case, silently
// losing that voucher's correction forever. Pending dates are now remembered
// per company and flushed to the next client that connects, so a save that
// happened while offline still gets picked up once the dashboard reopens.
const pendingDaybookDates = new Map<string, Set<string>>()

function addSocket(companyId: string, ws: WebSocket) {
  if (!companySockets.has(companyId)) companySockets.set(companyId, new Set())
  companySockets.get(companyId)!.add(ws)

  const pending = pendingDaybookDates.get(companyId)
  if (pending && pending.size > 0) {
    console.log('[WS] Flushing', pending.size, 'pending DAYBOOK_TRIGGER date(s) for company', companyId, '— missed while disconnected')
    for (const date of pending) {
      if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ type: 'DAYBOOK_TRIGGER', date }))
    }
    pendingDaybookDates.delete(companyId)
  }
}

function removeSocket(companyId: string, ws: WebSocket) {
  const set = companySockets.get(companyId)
  if (!set) return
  set.delete(ws)
  if (set.size === 0) companySockets.delete(companyId)
}

export function notifyCompany(companyId: string, payload: Record<string, unknown>): void {
  const set = companySockets.get(companyId)
  if (!set || set.size === 0) {
    if (payload.type === 'DAYBOOK_TRIGGER' && typeof payload.date === 'string') {
      if (!pendingDaybookDates.has(companyId)) pendingDaybookDates.set(companyId, new Set())
      pendingDaybookDates.get(companyId)!.add(payload.date)
      console.log('[WS] No connected clients for company', companyId, '— queued date', payload.date, 'for next connect')
    } else {
      console.log('[WS] No connected clients for company', companyId, '— nothing to notify')
    }
    return
  }
  const message = JSON.stringify(payload)
  for (const ws of set) {
    if (ws.readyState === WebSocket.OPEN) ws.send(message)
  }
}

export function initWebSocketServer(server: HttpServer): void {
  const wss = new WebSocketServer({ noServer: true })

  server.on('upgrade', (req, socket, head) => {
    const url = new URL(req.url ?? '', 'http://localhost')
    if (url.pathname !== WS_PATH) {
      socket.destroy()
      return
    }

    const token = url.searchParams.get('token')
    const companyId = url.searchParams.get('companyId')

    if (!token || !companyId) {
      socket.destroy()
      return
    }

    let auth: AuthPayload
    try {
      auth = jwt.verify(token, process.env.JWT_SECRET!) as AuthPayload
    } catch {
      socket.destroy()
      return
    }

    canAccessCompany(auth, companyId)
      .then((allowed) => {
        if (!allowed) {
          socket.destroy()
          return
        }
        wss.handleUpgrade(req, socket, head, (ws) => {
          addSocket(companyId, ws)
          console.log('[WS] Client connected for company', companyId)
          ws.on('close', () => {
            removeSocket(companyId, ws)
            console.log('[WS] Client disconnected for company', companyId)
          })
        })
      })
      .catch(() => socket.destroy())
  })
}
