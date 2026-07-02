import './env' // must be first — loads env vars before any other module reads process.env
import http from 'http'
import { app } from './app'
import { prisma } from './db'
import { initWebSocketServer } from './ws'

const PORT = Number(process.env.PORT) || 3001

const server = http.createServer(app)
initWebSocketServer(server)

server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`)
})

process.on('SIGINT', async () => {
  await prisma.$disconnect()
  process.exit(0)
})

// Safety net: Express 4 doesn't forward async route-handler rejections to
// error middleware on its own, and Node's default behavior for an unhandled
// rejection is to crash the whole process. A single bad request (e.g. one
// malformed record in a batch) shouldn't be able to take the entire server
// down for every other in-flight request. Route handlers should still catch
// and respond to their own errors — this only stops an oversight from being
// fatal.
process.on('unhandledRejection', (reason) => {
  console.error('[FATAL-AVOIDED] Unhandled promise rejection:', reason)
})
