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
