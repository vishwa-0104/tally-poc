import { Router } from 'express'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { prisma } from '../db'
import { requireAuth, requireAdmin } from '../middleware/auth'

export const companiesRouter = Router()

companiesRouter.use(requireAuth)

// GET /api/companies — admin sees all, company user sees own
companiesRouter.get('/', async (req, res) => {
  const companies = req.auth.role === 'ADMIN'
    ? await prisma.company.findMany({ orderBy: { createdAt: 'desc' } })
    : await prisma.company.findMany({ where: { id: req.auth.companyId! } })

  // Attach bill counts
  const withCounts = await Promise.all(
    companies.map(async (c) => {
      const [total, synced, pending, error] = await Promise.all([
        prisma.bill.count({ where: { companyId: c.id } }),
        prisma.bill.count({ where: { companyId: c.id, status: 'SYNCED' } }),
        prisma.bill.count({ where: { companyId: c.id, status: { in: ['PENDING', 'PARSED', 'MAPPED'] } } }),
        prisma.bill.count({ where: { companyId: c.id, status: 'ERROR' } }),
      ])
      return { ...c, totalBills: total, syncedBills: synced, pendingBills: pending, errorBills: error }
    }),
  )

  res.json(withCounts)
})

// GET /api/companies/:id
companiesRouter.get('/:id', async (req, res) => {
  if (req.auth.role !== 'ADMIN' && req.auth.companyId !== req.params.id) {
    res.status(403).json({ error: 'Forbidden' })
    return
  }
  const company = await prisma.company.findUnique({ where: { id: req.params.id } })
  if (!company) { res.status(404).json({ error: 'Not found' }); return }
  res.json(company)
})

// POST /api/companies — admin only
companiesRouter.post('/', requireAdmin, async (req, res) => {
  const schema = z.object({
    name: z.string().min(3),
    gstin: z.string().optional(),
    email: z.string().email(),
    password: z.string().min(8),
    port: z.number().min(1).max(65535).default(9000),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input', details: result.error.flatten() }); return }

  const { name, gstin, email, password, port } = result.data

  const exists = await prisma.company.findUnique({ where: { email } })
  if (exists) { res.status(409).json({ error: 'Company email already registered' }); return }

  const company = await prisma.company.create({ data: { name, gstin, email, port } })

  // Create company user account
  const passwordHash = await bcrypt.hash(password, 10)
  await prisma.user.create({ data: { name, email, passwordHash, role: 'COMPANY', companyId: company.id } })

  res.status(201).json(company)
})

// PUT /api/companies/:id/mapping
companiesRouter.put('/:id/mapping', async (req, res) => {
  if (req.auth.role !== 'ADMIN' && req.auth.companyId !== req.params.id) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const company = await prisma.company.update({
    where: { id: req.params.id },
    data: { mapping: req.body },
  })
  res.json(company)
})
