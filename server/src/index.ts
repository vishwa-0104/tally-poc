import dotenv from 'dotenv'
import path from 'path'

// Mirror Vite's cascade: .env.[mode].local > .env.local > .env.[mode] > .env
// All paths resolve to the monorepo root (two levels up from server/src or server/dist)
const root = path.resolve(__dirname, '../../')
const mode = process.env.NODE_ENV || 'development'
dotenv.config({ path: path.join(root, `.env.${mode}.local`) })
dotenv.config({ path: path.join(root, '.env.local') })
dotenv.config({ path: path.join(root, `.env.${mode}`) })
dotenv.config({ path: path.join(root, '.env') })

import { app } from './app'
import { prisma } from './db'

const PORT = Number(process.env.PORT) || 3001

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`)
})

process.on('SIGINT', async () => {
  await prisma.$disconnect()
  process.exit(0)
})
