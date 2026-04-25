import type { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'
import { prisma } from '../db'

export interface AuthPayload {
  userId: string
  role: 'ADMIN' | 'COMPANY'
}

declare global {
  namespace Express {
    interface Request {
      auth: AuthPayload
    }
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' })
    return
  }
  try {
    const token = header.slice(7)
    const payload = jwt.verify(token, process.env.JWT_SECRET!) as AuthPayload
    req.auth = payload
    next()
  } catch {
    res.status(401).json({ error: 'Invalid token' })
  }
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  if (req.auth?.role !== 'ADMIN') {
    res.status(403).json({ error: 'Forbidden' })
    return
  }
  next()
}

/** Returns true if the authenticated user can access the given companyId. */
export async function canAccessCompany(auth: AuthPayload, companyId: string): Promise<boolean> {
  if (auth.role === 'ADMIN') return true
  const link = await prisma.userCompany.findUnique({
    where: { userId_companyId: { userId: auth.userId, companyId } },
  })
  return !!link
}
