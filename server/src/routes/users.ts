import { Router } from 'express'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { prisma } from '../db'
import { requireAuth, requireAdmin } from '../middleware/auth'

export const usersRouter = Router()

usersRouter.use(requireAuth)

// GET /api/users — list all company-role users (admin only)
usersRouter.get('/users', requireAdmin, async (_req, res) => {
  const users = await prisma.user.findMany({
    where: { role: 'COMPANY' },
    include: {
      linkedCompanies: {
        include: { company: { select: { id: true, name: true } } },
        orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
      },
    },
    orderBy: { createdAt: 'desc' },
  })

  res.json(users.map((u) => ({
    id: u.id,
    name: u.name,
    email: u.email,
    enterpriseName: u.enterpriseName,
    createdAt: u.createdAt,
    companies: u.linkedCompanies.map((lc) => ({ ...lc.company, isDefault: lc.isDefault })),
  })))
})

// POST /api/users — create enterprise user (admin only)
usersRouter.post('/users', requireAdmin, async (req, res) => {
  const schema = z.object({
    name: z.string().min(2),
    email: z.string().email(),
    password: z.string().min(8),
    enterpriseName: z.string().min(1),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input', details: result.error.flatten() }); return }

  const { name, email, password, enterpriseName } = result.data
  const exists = await prisma.user.findUnique({ where: { email } })
  if (exists) { res.status(409).json({ error: 'Email already registered' }); return }

  const passwordHash = await bcrypt.hash(password, 10)
  const user = await prisma.user.create({
    data: { name, email, passwordHash, role: 'COMPANY', enterpriseName },
  })

  res.status(201).json({
    id: user.id,
    name: user.name,
    email: user.email,
    enterpriseName: user.enterpriseName,
    companies: [],
  })
})

// DELETE /api/users/:userId — delete user + cascade (admin only)
usersRouter.delete('/users/:userId', requireAdmin, async (req, res) => {
  await prisma.user.delete({ where: { id: req.params.userId } }).catch(() => {})
  res.json({ ok: true })
})

// PATCH /api/users/default-company — set active company as default for authenticated user
usersRouter.patch('/users/default-company', async (req, res) => {
  const schema = z.object({ companyId: z.string().min(1) })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const { companyId } = result.data
  const userId = req.auth.userId

  // Verify user has access to this company
  const link = await prisma.userCompany.findUnique({
    where: { userId_companyId: { userId, companyId } },
  })
  if (!link && req.auth.role !== 'ADMIN') {
    res.status(403).json({ error: 'Forbidden' }); return
  }

  // Clear existing default, set new one
  await prisma.$transaction([
    prisma.userCompany.updateMany({ where: { userId }, data: { isDefault: false } }),
    prisma.userCompany.update({ where: { userId_companyId: { userId, companyId } }, data: { isDefault: true } }),
  ])

  res.json({ ok: true })
})

// GET /api/users/:userId/companies — list companies linked to a user (admin only)
usersRouter.get('/users/:userId/companies', requireAdmin, async (req, res) => {
  const links = await prisma.userCompany.findMany({
    where: { userId: req.params.userId },
    include: { company: { select: { id: true, name: true, gstin: true, port: true } } },
    orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
  })
  res.json(links.map((l) => ({ ...l.company, isDefault: l.isDefault })))
})

// POST /api/users/:userId/link-company — link a company to a user (admin only)
usersRouter.post('/users/:userId/link-company', requireAdmin, async (req, res) => {
  const schema = z.object({ companyId: z.string().min(1) })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const { companyId } = result.data
  const userId = req.params.userId

  const company = await prisma.company.findUnique({ where: { id: companyId } })
  if (!company) { res.status(404).json({ error: 'Company not found' }); return }

  // Check if this is the user's first company (auto-set as default)
  const existingCount = await prisma.userCompany.count({ where: { userId } })

  try {
    await prisma.userCompany.create({
      data: { userId, companyId, isDefault: existingCount === 0 },
    })
    res.status(201).json({ ok: true })
  } catch {
    res.status(409).json({ error: 'Company already linked to this user' })
  }
})

// PATCH /api/users/:userId/default-company — admin sets default company for a specific user
usersRouter.patch('/users/:userId/default-company', requireAdmin, async (req, res) => {
  const schema = z.object({ companyId: z.string().min(1) })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const { companyId } = result.data
  const { userId } = req.params

  const link = await prisma.userCompany.findUnique({
    where: { userId_companyId: { userId, companyId } },
  })
  if (!link) { res.status(404).json({ error: 'Company not linked to this user' }); return }

  await prisma.$transaction([
    prisma.userCompany.updateMany({ where: { userId }, data: { isDefault: false } }),
    prisma.userCompany.update({ where: { userId_companyId: { userId, companyId } }, data: { isDefault: true } }),
  ])

  res.json({ ok: true })
})

// DELETE /api/users/:userId/link-company/:companyId — unlink company from user (admin only)
usersRouter.delete('/users/:userId/link-company/:companyId', requireAdmin, async (req, res) => {
  const { userId, companyId } = req.params

  await prisma.userCompany.deleteMany({ where: { userId, companyId } })

  // If deleted row was the default, promote next linked company as default
  const remaining = await prisma.userCompany.findMany({
    where: { userId },
    orderBy: { createdAt: 'asc' },
  })
  if (remaining.length > 0 && !remaining.some((r) => r.isDefault)) {
    await prisma.userCompany.update({
      where: { id: remaining[0].id },
      data: { isDefault: true },
    })
  }

  res.json({ ok: true })
})
