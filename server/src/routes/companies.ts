import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { requireAuth, requireAdmin, canAccessCompany } from '../middleware/auth'

export const companiesRouter = Router()

companiesRouter.use(requireAuth)

// GET /api/companies — admin sees all, company user sees linked companies only
companiesRouter.get('/companies', async (req, res) => {
  const include = { features: { select: { feature: true, enabled: true } } }
  const companies = req.auth.role === 'ADMIN'
    ? await prisma.company.findMany({ orderBy: { createdAt: 'desc' }, include })
    : await prisma.company.findMany({
        where: { linkedUsers: { some: { userId: req.auth.userId } } },
        include,
      })

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
companiesRouter.get('/companies/:id', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const company = await prisma.company.findUnique({ where: { id: req.params.id } })
  if (!company) { res.status(404).json({ error: 'Not found' }); return }
  res.json(company)
})

// POST /api/companies — admin only
companiesRouter.post('/companies', requireAdmin, async (req, res) => {
  const schema = z.object({
    name: z.string().min(3),
    gstin: z.string().optional(),
    email: z.string().email().optional(),
    port: z.number().min(1).max(65535).default(9000),
    userId: z.string().optional(), // enterprise user to link at creation time
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input', details: result.error.flatten() }); return }

  const { name, gstin, email, port, userId } = result.data

  const company = await prisma.company.create({ data: { name, gstin, email: email ?? undefined, port } })

  // Optionally link to an enterprise user
  if (userId) {
    const existingCount = await prisma.userCompany.count({ where: { userId } })
    await prisma.userCompany.create({
      data: { userId, companyId: company.id, isDefault: existingCount === 0 },
    }).catch(() => {}) // ignore if already linked
  }

  res.status(201).json(company)
})

// PATCH /api/companies/:id — update name, gstin, port (admin only)
companiesRouter.patch('/companies/:id', requireAdmin, async (req, res) => {
  const schema = z.object({
    name:  z.string().min(3).optional(),
    gstin: z.string().optional().nullable(),
    port:  z.number().min(1).max(65535).optional(),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const company = await prisma.company.update({
    where: { id: req.params.id },
    data:  result.data,
  })
  res.json(company)
})

// GET /api/companies/:id/ledgers
companiesRouter.get('/companies/:id/ledgers', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const ledgers = await prisma.ledgerCache.findMany({
    where: { companyId: req.params.id },
    orderBy: { name: 'asc' },
  })
  res.json(ledgers)
})

// PUT /api/companies/:id/ledgers — replace all cached ledgers
companiesRouter.put('/companies/:id/ledgers', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.array(z.object({
    name:                z.string(),
    group:               z.string().default(''),
    gstin:               z.string().optional(),
    state:               z.string().optional(),
    openingBalance:      z.string().optional(),
    gstRegistrationType: z.string().optional(),
  }))
  const result = schema.safeParse(req.body)
  if (!result.success) {
    console.error('[Ledgers] Invalid payload:', result.error.flatten())
    res.status(400).json({ error: 'Invalid input' }); return
  }

  const companyId = req.params.id
  const incoming  = result.data
  console.log(`[Ledgers] PUT /${companyId}/ledgers — received ${incoming.length} ledgers`)

  const CHUNK = 200
  await prisma.$transaction(async (tx) => {
    for (let i = 0; i < incoming.length; i += CHUNK) {
      const chunk = incoming.slice(i, i + CHUNK)
      await tx.$executeRaw`
        INSERT INTO "LedgerCache" (id, "companyId", name, "group", gstin, state, "openingBalance", "gstRegistrationType")
        SELECT gen_random_uuid(), ${companyId}, l.name, l."group", l.gstin, l.state, l."openingBalance", l."gstRegistrationType"
        FROM json_to_recordset(${JSON.stringify(chunk)}::json) AS l(
          name text, "group" text, gstin text, state text, "openingBalance" text, "gstRegistrationType" text
        )
        ON CONFLICT ("companyId", name) DO UPDATE SET
          "group"               = EXCLUDED."group",
          gstin                 = EXCLUDED.gstin,
          state                 = EXCLUDED.state,
          "openingBalance"      = EXCLUDED."openingBalance",
          "gstRegistrationType" = EXCLUDED."gstRegistrationType"
      `
    }
    await tx.ledgerCache.deleteMany({
      where: { companyId, name: { notIn: incoming.map((l) => l.name) } },
    })
  }, { timeout: 60000 })

  console.log(`[Ledgers] Upserted ${incoming.length} ledgers for company ${companyId}`)
  const now = new Date().toISOString()
  await prisma.$executeRaw`
    UPDATE "Company"
    SET "syncTimestamps" = COALESCE("syncTimestamps", '{}'::jsonb) || jsonb_build_object('ledgers', ${now}::text)
    WHERE id = ${companyId}
  `
  res.json({ saved: incoming.length, syncedAt: now })
})

// GET /api/companies/:id/stock-items
companiesRouter.get('/companies/:id/stock-items', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const items = await prisma.stockItemCache.findMany({
    where: { companyId: req.params.id },
    orderBy: { name: 'asc' },
  })
  res.json(items)
})

// PUT /api/companies/:id/stock-items — upsert by name (preserves IDs so aliases survive)
companiesRouter.put('/companies/:id/stock-items', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.array(z.object({
    name:  z.string(),
    group: z.string().default(''),
    unit:  z.string().default(''),
  }))
  const result = schema.safeParse(req.body)
  if (!result.success) {
    res.status(400).json({ error: 'Invalid input' }); return
  }

  const companyId = req.params.id
  const incoming  = result.data
  console.log(`[StockItems] PUT /${companyId}/stock-items — received ${incoming.length} items`)

  const CHUNK = 200
  await prisma.$transaction(async (tx) => {
    for (let i = 0; i < incoming.length; i += CHUNK) {
      const chunk = incoming.slice(i, i + CHUNK)
      await tx.$executeRaw`
        INSERT INTO "StockItemCache" (id, "companyId", name, "group", unit)
        SELECT gen_random_uuid(), ${companyId}, s.name, s."group", s.unit
        FROM json_to_recordset(${JSON.stringify(chunk)}::json) AS s(
          name text, "group" text, unit text
        )
        ON CONFLICT ("companyId", name) DO UPDATE SET
          "group" = EXCLUDED."group",
          unit    = EXCLUDED.unit
      `
    }
    await tx.stockItemCache.deleteMany({
      where: { companyId, name: { notIn: incoming.map((i) => i.name) } },
    })
  }, { timeout: 60000 })

  console.log(`[StockItems] Upserted ${incoming.length} items for company ${companyId}`)
  const now = new Date().toISOString()
  await prisma.$executeRaw`
    UPDATE "Company"
    SET "syncTimestamps" = COALESCE("syncTimestamps", '{}'::jsonb) || jsonb_build_object('stockItems', ${now}::text)
    WHERE id = ${companyId}
  `
  res.json({ saved: incoming.length, syncedAt: now })
})

// GET /api/companies/:id/stock-groups
companiesRouter.get('/companies/:id/stock-groups', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const groups = await prisma.stockGroupCache.findMany({
    where: { companyId: req.params.id },
    orderBy: { name: 'asc' },
  })
  res.json(groups)
})

// PUT /api/companies/:id/stock-groups — replace all cached stock groups
companiesRouter.put('/companies/:id/stock-groups', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.array(z.object({
    name:   z.string(),
    parent: z.string().default(''),
  }))
  const result = schema.safeParse(req.body)
  if (!result.success) {
    res.status(400).json({ error: 'Invalid input' }); return
  }

  const companyId = req.params.id
  const incoming  = result.data

  await prisma.$transaction(async (tx) => {
    for (const g of incoming) {
      await tx.stockGroupCache.upsert({
        where:  { companyId_name: { companyId, name: g.name } },
        update: { parent: g.parent },
        create: { companyId, name: g.name, parent: g.parent },
      })
    }
    await tx.stockGroupCache.deleteMany({
      where: { companyId, name: { notIn: incoming.map((g) => g.name) } },
    })
  })

  const now = new Date().toISOString()
  await prisma.$executeRaw`
    UPDATE "Company"
    SET "syncTimestamps" = COALESCE("syncTimestamps", '{}'::jsonb) || jsonb_build_object('stockGroups', ${now}::text)
    WHERE id = ${companyId}
  `
  res.json({ saved: incoming.length, syncedAt: now })
})

// GET /api/companies/:id/stock-units
companiesRouter.get('/companies/:id/stock-units', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const units = await prisma.stockUnitCache.findMany({
    where: { companyId: req.params.id },
    orderBy: { name: 'asc' },
  })
  res.json(units)
})

// PUT /api/companies/:id/stock-units — replace all cached stock units
companiesRouter.put('/companies/:id/stock-units', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.array(z.object({
    name:   z.string(),
    symbol: z.string().default(''),
  }))
  const result = schema.safeParse(req.body)
  if (!result.success) {
    res.status(400).json({ error: 'Invalid input' }); return
  }

  const companyId = req.params.id
  const incoming  = result.data
  console.log(`[StockUnits] PUT /${companyId}/stock-units — received ${incoming.length} units`)

  const CHUNK = 200
  await prisma.$transaction(async (tx) => {
    for (let i = 0; i < incoming.length; i += CHUNK) {
      const chunk = incoming.slice(i, i + CHUNK)
      await tx.$executeRaw`
        INSERT INTO "StockUnitCache" (id, "companyId", name, symbol)
        SELECT gen_random_uuid(), ${companyId}, u.name, u.symbol
        FROM json_to_recordset(${JSON.stringify(chunk)}::json) AS u(
          name text, symbol text
        )
        ON CONFLICT ("companyId", name) DO UPDATE SET
          symbol = EXCLUDED.symbol
      `
    }
    await tx.stockUnitCache.deleteMany({
      where: { companyId, name: { notIn: incoming.map((u) => u.name) } },
    })
  }, { timeout: 60000 })

  console.log(`[StockUnits] Upserted ${incoming.length} units for company ${companyId}`)
  const now = new Date().toISOString()
  await prisma.$executeRaw`
    UPDATE "Company"
    SET "syncTimestamps" = COALESCE("syncTimestamps", '{}'::jsonb) || jsonb_build_object('stockUnits', ${now}::text)
    WHERE id = ${companyId}
  `
  res.json({ saved: incoming.length, syncedAt: now })
})

// GET /api/companies/:id/stock-item-aliases
companiesRouter.get('/companies/:id/stock-item-aliases', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const aliases = await prisma.stockItemAlias.findMany({
    where: { companyId: req.params.id },
    select: { billItemName: true, stockItem: { select: { name: true } } },
  })
  res.json(aliases.map((a) => ({ billItemName: a.billItemName, tallyStockItemName: a.stockItem.name })))
})

// POST /api/companies/:id/stock-item-aliases — bulk upsert
companiesRouter.post('/companies/:id/stock-item-aliases', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.array(z.object({
    billItemName:      z.string().min(1),
    tallyStockItemName: z.string().min(1),
  }))
  const result = schema.safeParse(req.body)
  if (!result.success) {
    res.status(400).json({ error: 'Invalid input' }); return
  }

  const companyId = req.params.id
  const incoming  = result.data

  // Resolve each tallyStockItemName to a StockItemCache id for this company
  for (const entry of incoming) {
    const stockItem = await prisma.stockItemCache.findUnique({
      where: { companyId_name: { companyId, name: entry.tallyStockItemName } },
    })
    if (!stockItem) continue // skip if item not in cache (shouldn't happen normally)

    await prisma.stockItemAlias.upsert({
      where:  { companyId_billItemName: { companyId, billItemName: entry.billItemName.toLowerCase() } },
      update: { stockItemCacheId: stockItem.id },
      create: { companyId, stockItemCacheId: stockItem.id, billItemName: entry.billItemName.toLowerCase() },
    })
  }

  res.json({ saved: incoming.length })
})

// POST /api/companies/:id/voucher-counter/next — atomically increment and return next counter
companiesRouter.post('/companies/:id/voucher-counter/next', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const company = await prisma.company.update({
    where: { id: req.params.id },
    data:  { voucherCounter: { increment: 1 } },
    select: { voucherCounter: true },
  })
  res.json({ counter: company.voucherCounter })
})

// PUT /api/companies/:id/mapping
companiesRouter.put('/companies/:id/mapping', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const company = await prisma.company.update({
    where: { id: req.params.id },
    data: { mapping: req.body },
  })
  res.json(company)
})

// GET /api/companies/:id/features
companiesRouter.get('/companies/:id/features', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const features = await prisma.companyFeature.findMany({
    where: { companyId: req.params.id },
    select: { feature: true, enabled: true },
  })
  res.json(features)
})

// PUT /api/companies/:id/features — admin only, upserts a single feature flag
companiesRouter.put('/companies/:id/features', requireAdmin, async (req, res) => {
  const schema = z.object({
    feature: z.string().min(1),
    enabled: z.boolean(),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const { feature, enabled } = result.data
  await prisma.companyFeature.upsert({
    where:  { companyId_feature: { companyId: req.params.id, feature } },
    update: { enabled },
    create: { companyId: req.params.id, feature, enabled },
  })
  res.json({ feature, enabled })
})

// GET /api/companies/:id/godowns
companiesRouter.get('/companies/:id/godowns', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const godowns = await prisma.godownCache.findMany({
    where: { companyId: req.params.id },
    orderBy: { name: 'asc' },
    select: { name: true },
  })
  res.json(godowns)
})

// PUT /api/companies/:id/godowns — replace all cached godowns
companiesRouter.put('/companies/:id/godowns', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.array(z.object({ name: z.string() }))
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const companyId = req.params.id
  const incoming  = result.data
  console.log(`[Godowns] PUT /${companyId}/godowns — received ${incoming.length} godowns`)

  await prisma.$transaction(async (tx) => {
    for (const g of incoming) {
      await tx.godownCache.upsert({
        where:  { companyId_name: { companyId, name: g.name } },
        update: {},
        create: { companyId, name: g.name },
      })
    }
    await tx.godownCache.deleteMany({
      where: { companyId, name: { notIn: incoming.map((g) => g.name) } },
    })
  })

  const now = new Date().toISOString()
  await prisma.$executeRaw`
    UPDATE "Company"
    SET "syncTimestamps" = COALESCE("syncTimestamps", '{}'::jsonb) || jsonb_build_object('godowns', ${now}::text)
    WHERE id = ${companyId}
  `
  res.json({ saved: incoming.length, syncedAt: now })
})

