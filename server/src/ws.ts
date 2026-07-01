import type { Server as HttpServer } from 'http'
import jwt from 'jsonwebtoken'
import { WebSocketServer, WebSocket } from 'ws'
import { canAccessCompany, type AuthPayload } from './middleware/auth'

const WS_PATH = '/api/ws'

const companySockets = new Map<string, Set<WebSocket>>()

function addSocket(companyId: string, ws: WebSocket) {
  if (!companySockets.has(companyId)) companySockets.set(companyId, new Set())
  companySockets.get(companyId)!.add(ws)
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
    console.log('[WS] No connected clients for company', companyId, '— nothing to notify')
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
