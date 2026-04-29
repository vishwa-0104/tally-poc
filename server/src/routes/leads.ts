import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { requireAuth, requireAdmin } from '../middleware/auth'

export const leadsRouter = Router()

const ALLOWED_STATUSES = ['NEW_LEAD', 'ONBOARDED', 'NOT_ONBOARDED', 'REJECTED'] as const

// POST /api/leads — public, no auth required
leadsRouter.post('/leads', async (req, res) => {
  const schema = z.object({
    companyName: z.string().min(2, 'Company name required'),
    phone:       z.string().min(10, 'Valid phone number required'),
    email:       z.string().email('Valid email required'),
    description: z.string().optional(),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input', details: result.error.flatten() }); return }
  try {
    const lead = await prisma.lead.create({ data: result.data })
    res.status(201).json(normalizeLead(lead))
  } catch (err) {
    console.error('[POST /leads]', err)
    res.status(500).json({ error: 'Failed to save lead' })
  }
})

// GET /api/leads — admin only
leadsRouter.get('/leads', requireAuth, requireAdmin, async (_req, res) => {
  try {
    const leads = await prisma.lead.findMany({ orderBy: { createdAt: 'desc' } })
    res.json(leads.map(normalizeLead))
  } catch (err) {
    console.error('[GET /leads]', err)
    res.status(500).json({ error: 'Failed to fetch leads' })
  }
})

// PATCH /api/leads/:id — admin only
leadsRouter.patch('/leads/:id', requireAuth, requireAdmin, async (req, res) => {
  const schema = z.object({
    status:  z.enum(ALLOWED_STATUSES).optional(),
    remarks: z.string().optional(),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input', details: result.error.flatten() }); return }
  try {
    const lead = await prisma.lead.findUnique({ where: { id: req.params.id } })
    if (!lead) { res.status(404).json({ error: 'Lead not found' }); return }
    const updated = await prisma.lead.update({ where: { id: req.params.id }, data: result.data })
    res.json(normalizeLead(updated))
  } catch (err) {
    console.error('[PATCH /leads/:id]', err)
    res.status(500).json({ error: 'Failed to update lead' })
  }
})

function normalizeLead(lead: { status: string; [key: string]: unknown }) {
  return { ...lead, status: lead.status.toLowerCase() }
}
