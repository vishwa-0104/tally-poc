import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import { authRouter } from './routes/auth'
import { companiesRouter } from './routes/companies'
import { billsRouter } from './routes/bills'
import { usersRouter } from './routes/users'
import { leadsRouter } from './routes/leads'

export const app = express()

app.use(helmet())
app.use(cors({ origin: 'http://localhost:3000', credentials: true }))
app.use(express.json({ limit: '20mb' })) // bills can include base64 images

app.get('/api/health', (_req, res) => res.json({ ok: true }))

app.use('/api/auth', authRouter)
app.use('/api', leadsRouter)
app.use('/api', companiesRouter)
app.use('/api', billsRouter)
app.use('/api', usersRouter)
