import { Router } from 'express'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { z } from 'zod'
import { prisma } from '../db'

export const authRouter = Router()

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

authRouter.post('/login', async (req, res) => {
  const result = loginSchema.safeParse(req.body)
  if (!result.success) {
    res.status(400).json({ error: 'Invalid input', details: result.error.flatten() })
    return
  }

  const { email, password } = result.data
  const user = await prisma.user.findUnique({ where: { email } })
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    res.status(401).json({ error: 'Invalid email or password' })
    return
  }

  // Block company-role users with no linked companies
  if (user.role === 'COMPANY') {
    const links = await prisma.userCompany.findMany({
      where: { userId: user.id },
      include: { company: true },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
    })

    if (links.length === 0) {
      res.status(403).json({ error: 'No company associated with this account. Contact your administrator.' })
      return
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' },
    )

    const companies = links.map((l) => l.company)
    const defaultCompanyId = links.find((l) => l.isDefault)?.companyId ?? companies[0].id

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role.toLowerCase(),
        enterpriseName: user.enterpriseName ?? undefined,
      },
      companies,
      defaultCompanyId,
    })
    return
  }

  // Admin login — no company list needed
  const token = jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' },
  )

  res.json({
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role.toLowerCase(),
    },
    companies: [],
    defaultCompanyId: null,
  })
})
