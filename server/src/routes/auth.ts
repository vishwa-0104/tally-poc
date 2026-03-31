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

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(8),
  companyId: z.string().optional(),
})

authRouter.post('/login', async (req, res) => {
  const result = loginSchema.safeParse(req.body)
  if (!result.success) {
    res.status(400).json({ error: 'Invalid input', details: result.error.flatten() })
    return
  }

  const { email, password } = result.data
  const user = await prisma.user.findUnique({ where: { email }, include: { company: true } })
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    res.status(401).json({ error: 'Invalid email or password' })
    return
  }

  const token = jwt.sign(
    { userId: user.id, role: user.role, companyId: user.companyId ?? undefined },
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
      companyId: user.companyId ?? undefined,
    },
  })
})

authRouter.post('/register', async (req, res) => {
  const result = registerSchema.safeParse(req.body)
  if (!result.success) {
    res.status(400).json({ error: 'Invalid input', details: result.error.flatten() })
    return
  }

  const { name, email, password, companyId } = result.data

  const exists = await prisma.user.findUnique({ where: { email } })
  if (exists) {
    res.status(409).json({ error: 'Email already registered' })
    return
  }

  const passwordHash = await bcrypt.hash(password, 10)
  const user = await prisma.user.create({
    data: { name, email, passwordHash, companyId },
  })

  const token = jwt.sign(
    { userId: user.id, role: user.role, companyId: user.companyId ?? undefined },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' },
  )

  res.status(201).json({
    token,
    user: { id: user.id, name: user.name, email: user.email, role: user.role.toLowerCase(), companyId: user.companyId ?? undefined },
  })
})
