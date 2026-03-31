import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import { authRouter } from './routes/auth'
import { companiesRouter } from './routes/companies'
import { billsRouter } from './routes/bills'

export const app = express()

app.use(helmet())
app.use(cors({ origin: 'http://localhost:3000', credentials: true }))
app.use(express.json({ limit: '20mb' })) // bills can include base64 images

app.use('/api/auth', authRouter)
app.use('/api', companiesRouter)
app.use('/api', billsRouter)

app.get('/api/health', (_req, res) => res.json({ ok: true }))
