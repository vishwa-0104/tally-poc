import 'dotenv/config'
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
