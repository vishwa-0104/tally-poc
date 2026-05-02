import dotenv from 'dotenv'
import path from 'path'

// Resolve to monorepo root (two levels up from server/src or server/dist)
const root = path.resolve(__dirname, '../../')
const mode = process.env.NODE_ENV || 'development'

// Mirror Vite's cascade: .env.[mode].local > .env.local > .env.[mode] > .env
dotenv.config({ path: path.join(root, `.env.${mode}.local`) })
dotenv.config({ path: path.join(root, '.env.local') })
dotenv.config({ path: path.join(root, `.env.${mode}`) })
dotenv.config({ path: path.join(root, '.env') })
