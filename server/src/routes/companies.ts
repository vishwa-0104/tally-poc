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

// PATCH /api/companies/:id/quota — update parse quota and subscription (admin only)
companiesRouter.patch('/companies/:id/quota', requireAdmin, async (req, res) => {
  const ALLOWED_SERVICES = ['gemini', 'anthropic']
  const ALLOWED_MODELS   = [
    'gemini-flash-latest', 'gemini-flash-lite-latest', 'gemini-3.1-flash', 'gemini-2.0-flash',
    'claude-haiku-4-5-20251001', 'claude-sonnet-4-6', 'claude-opus-4-7',
  ]
  const schema = z.object({
    parseBillsLimit:       z.number().int().min(0).optional(),
    parseBlocked:          z.boolean().optional(),
    parseService:          z.string().refine((s) => ALLOWED_SERVICES.includes(s)).optional(),
    parseModel:            z.string().refine((m) => ALLOWED_MODELS.includes(m)).optional(),
    subscriptionExpiresAt: z.string().datetime().nullable().optional(),
    renew:                 z.boolean().optional(), // if true: reset parseBillsUsed to 0 + stamp renewedAt
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input', details: result.error.flatten() }); return }

  const { parseBillsLimit, parseBlocked, parseService, parseModel, subscriptionExpiresAt, renew } = result.data
  const data: Record<string, unknown> = {}
  if (parseBillsLimit       !== undefined) data.parseBillsLimit = parseBillsLimit
  if (parseBlocked          !== undefined) data.parseBlocked    = parseBlocked
  if (parseService          !== undefined) data.parseService    = parseService
  if (parseModel            !== undefined) data.parseModel      = parseModel
  if (subscriptionExpiresAt !== undefined) data.subscriptionExpiresAt = subscriptionExpiresAt ? new Date(subscriptionExpiresAt) : null
  if (renew) {
    data.parseBillsUsed        = 0
    data.subscriptionRenewedAt = new Date()
  }

  const company = await prisma.company.update({ where: { id: req.params.id }, data })
  res.json(company)
})

// GET /api/companies/:id/parse-usage — per-company token & request stats (admin only)
companiesRouter.get('/companies/:id/parse-usage', requireAdmin, async (req, res) => {
  const companyId = req.params.id

  const [totals, byModel, daily] = await Promise.all([
    prisma.parseUsageLog.aggregate({
      where: { companyId },
      _count: { id: true },
      _sum:   { inputTokens: true, outputTokens: true, cacheRead: true, cacheWrite: true },
    }),
    prisma.parseUsageLog.groupBy({
      by: ['model', 'success'],
      where: { companyId },
      _count: { id: true },
      _sum:   { inputTokens: true, outputTokens: true },
    }),
    prisma.$queryRaw<{ date: string; requests: bigint; input: bigint; output: bigint }[]>`
      SELECT
        TO_CHAR("createdAt" AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS date,
        COUNT(*)::bigint                                        AS requests,
        COALESCE(SUM("inputTokens"), 0)::bigint                AS input,
        COALESCE(SUM("outputTokens"), 0)::bigint               AS output
      FROM "ParseUsageLog"
      WHERE "companyId" = ${companyId}
        AND "createdAt" >= NOW() - INTERVAL '30 days'
      GROUP BY 1
      ORDER BY 1
    `,
  ])

  res.json({
    total: {
      requests:     totals._count.id,
      inputTokens:  totals._sum.inputTokens  ?? 0,
      outputTokens: totals._sum.outputTokens ?? 0,
      cacheRead:    totals._sum.cacheRead    ?? 0,
      cacheWrite:   totals._sum.cacheWrite   ?? 0,
    },
    byModel: byModel.map((r: typeof byModel[number]) => ({
      model:        r.model,
      success:      r.success,
      requests:     r._count.id,
      inputTokens:  r._sum.inputTokens  ?? 0,
      outputTokens: r._sum.outputTokens ?? 0,
    })),
    daily: daily.map((r: { date: string; requests: bigint; input: bigint; output: bigint }) => ({
      date:     r.date,
      requests: Number(r.requests),
      input:    Number(r.input),
      output:   Number(r.output),
    })),
  })
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
    await tx.$executeRaw`
      DELETE FROM "LedgerCache"
      WHERE "companyId" = ${companyId}
      AND name NOT IN (
        SELECT name FROM json_to_recordset(${JSON.stringify(incoming.map((l) => ({ name: l.name })))}::json) AS s(name text)
      )
    `
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
    await tx.$executeRaw`
      DELETE FROM "StockItemCache"
      WHERE "companyId" = ${companyId}
      AND name NOT IN (
        SELECT name FROM json_to_recordset(${JSON.stringify(incoming.map((i) => ({ name: i.name })))}::json) AS s(name text)
      )
    `
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
    await tx.stockGroupCache.deleteMany({ where: { companyId } })
    await tx.stockGroupCache.createMany({
      data: incoming.map((g) => ({ companyId, name: g.name, parent: g.parent })),
      skipDuplicates: true,
    })
  }, { timeout: 30000 })

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
    await tx.$executeRaw`
      DELETE FROM "StockUnitCache"
      WHERE "companyId" = ${companyId}
      AND name NOT IN (
        SELECT name FROM json_to_recordset(${JSON.stringify(incoming.map((u) => ({ name: u.name })))}::json) AS s(name text)
      )
    `
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

// GET /api/companies/:id/targets?fyYear=2025
companiesRouter.get('/companies/:id/targets', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const today = new Date()
  const defaultFy = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1
  const fyYear = parseInt(req.query.fyYear as string) || defaultFy
  const targets = await prisma.salesTarget.findMany({
    where: { companyId: req.params.id, fyYear },
    select: { month: true, target: true },
  })
  res.json(targets)
})

// PUT /api/companies/:id/targets
companiesRouter.put('/companies/:id/targets', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.object({
    fyYear:  z.number().int(),
    targets: z.array(z.object({
      month:  z.number().int().min(1).max(12),
      target: z.number().min(0),
    })),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const { fyYear, targets } = result.data
  const companyId = req.params.id
  await prisma.$transaction(
    targets.map(({ month, target }) =>
      prisma.salesTarget.upsert({
        where:  { companyId_fyYear_month: { companyId, fyYear, month } },
        update: { target },
        create: { companyId, fyYear, month, target },
      })
    )
  )
  res.json({ ok: true })
})

// GET /api/companies/:id/dashboard-settings
companiesRouter.get('/companies/:id/dashboard-settings', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const company = await prisma.company.findUnique({
    where:  { id: req.params.id },
    select: { dashboardSettings: true },
  })
  res.json(company?.dashboardSettings ?? {})
})

// PUT /api/companies/:id/dashboard-settings
companiesRouter.put('/companies/:id/dashboard-settings', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.object({
    today: z.object({
      salesAccounts:        z.array(z.string()).optional(),
      salesIncludeVouchers: z.array(z.string()).optional(),
      salesExcludeVouchers: z.array(z.string()).optional(),
      cashInflowLedgers:    z.array(z.string()).optional(),
      bankLedgers:          z.array(z.string()).optional(),
    }).optional(),
    ytd: z.object({
      purchaseAccounts:        z.array(z.string()).optional(),
      purchaseIncludeVouchers: z.array(z.string()).optional(),
      purchaseExcludeVouchers: z.array(z.string()).optional(),
      directExpenseLedgers:    z.array(z.string()).optional(),
      indirectExpenseLedgers:         z.array(z.string()).optional(),
      indirectExpenseIncludeVouchers: z.array(z.string()).optional(),
      indirectExpenseExcludeVouchers: z.array(z.string()).optional(),
      indirectIncomeLedgers:          z.array(z.string()).optional(),
      indirectIncomeIncludeVouchers:  z.array(z.string()).optional(),
      indirectIncomeExcludeVouchers:  z.array(z.string()).optional(),
      ebitdaLedgers:                  z.array(z.string()).optional(),
      ebitdaIncludeVouchers:          z.array(z.string()).optional(),
      ebitdaExcludeVouchers:          z.array(z.string()).optional(),
      grossMarginTarget:              z.number().optional(),
      interestExpenseLedgers:         z.array(z.string()).optional(),
      taxPaymentLedgers:              z.array(z.string()).optional(),
      nonOperatingIncomeLedgers:      z.array(z.string()).optional(),
      nonOperatingInvestmentLedgers:  z.array(z.string()).optional(),
      directorLoanLedgers:            z.array(z.string()).optional(),
      analysisSalesAccounts:          z.array(z.string()).optional(),
      analysisSalesIncludeVouchers:   z.array(z.string()).optional(),
      analysisSalesExcludeVouchers:   z.array(z.string()).optional(),
    }).optional(),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  await prisma.company.update({
    where: { id: req.params.id },
    data:  { dashboardSettings: result.data },
  })
  res.json({ ok: true })
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


// GET /api/companies/:id/voucher-types
companiesRouter.get('/companies/:id/voucher-types', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const types = await prisma.voucherTypeCache.findMany({
    where: { companyId: req.params.id },
    orderBy: { name: 'asc' },
    select: { name: true },
  })
  res.json(types.map((t) => t.name))
})

// PUT /api/companies/:id/voucher-types — replace cached list
companiesRouter.put('/companies/:id/voucher-types', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const result = z.array(z.string().min(1)).safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const companyId = req.params.id
  const incoming  = result.data

  await prisma.$transaction(async (tx) => {
    for (const name of incoming) {
      await tx.voucherTypeCache.upsert({
        where:  { companyId_name: { companyId, name } },
        update: {},
        create: { companyId, name },
      })
    }
    await tx.voucherTypeCache.deleteMany({
      where: { companyId, name: { notIn: incoming } },
    })
  })

  res.json({ saved: incoming.length })
})

// GET /api/admin/usage-dashboard?period=1d|7d|mtd&companyId=xxx — cross-company token & cost stats
companiesRouter.get('/admin/usage-dashboard', requireAdmin, async (req, res) => {
  const period    = (req.query.period    as string) ?? '7d'
  const companyId = (req.query.companyId as string) || null

  const now = new Date()
  let since: Date | null = null
  if (period === '1d') {
    since = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  } else if (period === 'mtd') {
    since = new Date(now.getFullYear(), now.getMonth(), 1)
  } else if (period === 'ytd') {
    since = new Date(now.getFullYear(), 0, 1)
  } else if (period === 'all') {
    since = null
  } else {
    since = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
  }

  // USD per 1M tokens — confirmed from provider billing pages
  const PRICING: Record<string, { input: number; output: number }> = {
    'gemini-flash-latest':        { input: 0.25,  output: 1.50  },
    'gemini-2.0-flash':           { input: 0.25,  output: 1.50  },
    'gemini-2.0-flash-latest':    { input: 0.25,  output: 1.50  },
    'gemini-1.5-flash':           { input: 0.25,  output: 1.50  },
    'gemini-1.5-flash-latest':    { input: 0.25,  output: 1.50  },
    'gemini-1.5-pro':             { input: 1.25,  output: 5.00  },
    'gemini-1.5-pro-latest':      { input: 1.25,  output: 5.00  },
    'claude-haiku-4-5':           { input: 0.25,  output: 1.25  },
    'claude-haiku-4-5-20251001':  { input: 0.25,  output: 1.25  },
    'claude-sonnet-4-6':          { input: 3.00,  output: 15.00 },
    'claude-opus-4-7':            { input: 15.00, output: 75.00 },
  }
  const FALLBACK_PRICING = { input: 0.25, output: 1.50 }
  const USD_TO_INR = 94.5

  type RawRow = { model: string; requests: bigint; successRequests: bigint; inputTokens: bigint; outputTokens: bigint }
  const rows: RawRow[] = await prisma.$queryRaw`
    SELECT
      model,
      COUNT(*)                              AS requests,
      COUNT(*) FILTER (WHERE success = true) AS "successRequests",
      COALESCE(SUM("inputTokens"),  0)       AS "inputTokens",
      COALESCE(SUM("outputTokens"), 0)       AS "outputTokens"
    FROM "ParseUsageLog"
    WHERE (${since}::timestamptz IS NULL OR "createdAt" >= ${since})
      AND (${companyId}::text    IS NULL OR "companyId" = ${companyId})
    GROUP BY model
    ORDER BY "inputTokens" DESC
  `

  const modelMap: Record<string, {
    requests: number; successRequests: number
    inputTokens: number; outputTokens: number
  }> = {}

  for (const r of rows) {
    modelMap[r.model] = {
      requests:        Number(r.requests),
      successRequests: Number(r.successRequests),
      inputTokens:     Number(r.inputTokens),
      outputTokens:    Number(r.outputTokens),
    }
  }

  const byModel = Object.entries(modelMap).map(([model, s]) => {
    const p           = PRICING[model] ?? FALLBACK_PRICING
    const costUsd     = (s.inputTokens * p.input + s.outputTokens * p.output) / 1_000_000
    const costInr     = parseFloat((costUsd * USD_TO_INR).toFixed(2))
    const costPerBill = s.requests > 0 ? parseFloat((costInr / s.requests).toFixed(4)) : 0
    return { model, ...s, costInr, costPerBill }
  })

  const total = byModel.reduce(
    (acc, m) => ({
      requests:        acc.requests        + m.requests,
      successRequests: acc.successRequests + m.successRequests,
      inputTokens:     acc.inputTokens     + m.inputTokens,
      outputTokens:    acc.outputTokens    + m.outputTokens,
      costInr:         parseFloat((acc.costInr + m.costInr).toFixed(2)),
      costPerBill:     0,
    }),
    { requests: 0, successRequests: 0, inputTokens: 0, outputTokens: 0, costInr: 0, costPerBill: 0 },
  )
  total.costPerBill = total.requests > 0
    ? parseFloat((total.costInr / total.requests).toFixed(4))
    : 0

  res.json({ period, byModel, total })
})

// PUT /api/companies/:id/voucher-type — save selected voucher type
companiesRouter.put('/companies/:id/voucher-type', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const result = z.object({ voucherType: z.string().min(1) }).safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const updated = await prisma.company.update({
    where: { id: req.params.id },
    data:  { voucherType: result.data.voucherType },
  })
  res.json({ voucherType: updated.voucherType })
})

// PUT /api/companies/:id/debit-voucher-type — save selected debit note voucher type
companiesRouter.put('/companies/:id/debit-voucher-type', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const result = z.object({ debitVoucherType: z.string() }).safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const company = await prisma.company.findUnique({ where: { id: req.params.id } })
  if (!company) { res.status(404).json({ error: 'Not found' }); return }

  const existingMapping = (company.mapping as Record<string, unknown>) ?? {}
  const updated = await prisma.company.update({
    where: { id: req.params.id },
    data:  { mapping: { ...existingMapping, debit_voucher_type: result.data.debitVoucherType } },
  })
  const mapping = (updated.mapping as Record<string, string>) ?? {}
  res.json({ debitVoucherType: mapping.debit_voucher_type ?? '' })
})

// PUT /api/companies/:id/credit-voucher-type — save selected credit note voucher type
companiesRouter.put('/companies/:id/credit-voucher-type', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const result = z.object({ creditVoucherType: z.string() }).safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const company = await prisma.company.findUnique({ where: { id: req.params.id } })
  if (!company) { res.status(404).json({ error: 'Not found' }); return }

  const existingMapping = (company.mapping as Record<string, unknown>) ?? {}
  const updated = await prisma.company.update({
    where: { id: req.params.id },
    data:  { mapping: { ...existingMapping, credit_voucher_type: result.data.creditVoucherType } },
  })
  const mapping = (updated.mapping as Record<string, string>) ?? {}
  res.json({ creditVoucherType: mapping.credit_voucher_type ?? '' })
})

// GET /api/companies/:id/bank-fingerprints — fetch all synced fingerprints for dedup
companiesRouter.get('/companies/:id/bank-fingerprints', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const logs = await prisma.bankSyncLog.findMany({
    where:  { companyId: req.params.id },
    select: { fingerprint: true },
  })
  res.json(logs.map((l) => l.fingerprint))
})

// POST /api/companies/:id/bank-fingerprints — bulk upsert after a successful sync
companiesRouter.post('/companies/:id/bank-fingerprints', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const result = z.object({ fingerprints: z.array(z.string()).min(1) }).safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const companyId = req.params.id
  await prisma.$transaction(
    result.data.fingerprints.map((fp) =>
      prisma.bankSyncLog.upsert({
        where:  { companyId_fingerprint: { companyId, fingerprint: fp } },
        update: {},
        create: { companyId, fingerprint: fp },
      }),
    ),
  )
  res.json({ saved: result.data.fingerprints.length })
})

// GET /api/companies/:id/cash-book-fingerprints — fetch all synced fingerprints for dedup
companiesRouter.get('/companies/:id/cash-book-fingerprints', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const logs = await prisma.cashBookSyncLog.findMany({
    where:  { companyId: req.params.id },
    select: { fingerprint: true },
  })
  res.json(logs.map((l) => l.fingerprint))
})

// POST /api/companies/:id/cash-book-fingerprints — bulk upsert after a successful sync
companiesRouter.post('/companies/:id/cash-book-fingerprints', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const result = z.object({ fingerprints: z.array(z.string()).min(1) }).safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const companyId = req.params.id
  await prisma.$transaction(
    result.data.fingerprints.map((fp) =>
      prisma.cashBookSyncLog.upsert({
        where:  { companyId_fingerprint: { companyId, fingerprint: fp } },
        update: {},
        create: { companyId, fingerprint: fp },
      }),
    ),
  )
  res.json({ saved: result.data.fingerprints.length })
})

// GET /api/companies/:id/vouchers?from=YYYY-MM-DD&to=YYYY-MM-DD — serves the
// DB cache. Never touches Tally. `fetchedDates` lets the UI tell "genuinely
// no vouchers that day" apart from "never fetched" for empty-state messaging.
companiesRouter.get('/companies/:id/vouchers', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const from = String(req.query.from ?? '')
  const to   = String(req.query.to ?? '')
  if (!from || !to) { res.status(400).json({ error: 'from and to are required' }); return }

  const companyId = req.params.id

  const [vouchers, fetchLogs] = await Promise.all([
    prisma.voucher.findMany({
      where:   { companyId, isLatest: true, date: { gte: from, lte: to } },
      include: { ledgerEntries: true, inventoryEntries: true },
      orderBy: { date: 'asc' },
    }),
    prisma.voucherFetchLog.findMany({
      where:  { companyId, date: { gte: from, lte: to } },
      select: { date: true },
    }),
  ])

  res.json({ vouchers, fetchedDates: fetchLogs.map((f) => f.date) })
})

const voucherLedgerEntrySchema = z.object({
  ledgerName:    z.string(),
  amount:        z.number(),
  isPartyLedger: z.boolean(),
})

const voucherInventoryEntrySchema = z.object({
  itemName: z.string(),
  qty:      z.number(),
  unit:     z.string(),
  amount:   z.number(),
})

const voucherInputSchema = z.object({
  date:             z.string(),
  type:             z.string(),
  party:            z.string(),
  voucherNo:        z.string(),
  amount:           z.number(),
  taxableAmount:    z.number(),
  alterId:          z.string().optional(),
  guid:             z.string().optional(),
  hasSalesLedger:   z.boolean().optional(),
  salesLedger:      z.string().optional(),
  purchaseLedger:   z.string().optional(),
  ledgerEntries:    z.array(voucherLedgerEntrySchema).optional(),
  inventoryEntries: z.array(voucherInventoryEntrySchema).optional(),
})

function datesBetween(from: string, to: string): string[] {
  const dates: string[] = []
  const cursor = new Date(`${from}T00:00:00Z`)
  const end    = new Date(`${to}T00:00:00Z`)
  while (cursor <= end) {
    dates.push(cursor.toISOString().slice(0, 10))
    cursor.setUTCDate(cursor.getUTCDate() + 1)
  }
  return dates
}

// POST /api/companies/:id/vouchers — persists a live Tally fetch (from Apply
// or the voucher-saved notify). Append-only: a voucher whose alterId changed
// gets a new row (old row's isLatest flips to false); unchanged vouchers are
// skipped (idempotent — notify may refetch data unchanged since last time).
companiesRouter.post('/companies/:id/vouchers', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const result = z.object({
    from:     z.string(),
    to:       z.string(),
    vouchers: z.array(voucherInputSchema),
  }).safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const companyId = req.params.id
  const { from, to, vouchers } = result.data
  let inserted = 0
  let skipped  = 0
  const failures: { voucherNo: string; type: string; date: string; party: string; identityKey: string; alterId: string; error: string }[] = []

  // Vouchers are persisted in chunks, each chunk in its own transaction, with a
  // SAVEPOINT around each individual voucher inside that transaction. This
  // balances two things that were previously in tension:
  //  - One giant transaction for the whole batch: a single bad voucher (e.g. a
  //    unique-constraint collision) threw inside an all-or-nothing transaction;
  //    since that rejection was never caught, it crashed the whole Node process
  //    (Express 4 doesn't auto-catch async errors, Node 20 kills the process on
  //    an unhandled rejection by default) — Docker restarted mid-request, client
  //    saw a 502, and NOTHING persisted, not just the one bad voucher.
  //  - One transaction per voucher (the fix that replaced the above): safe, but
  //    for a large batch it commits one row at a time over several seconds,
  //    leaving a wide window where a concurrent read (e.g. a tab switch)
  //    observes a partial, still-in-progress batch — confirmed happening (DB
  //    view briefly showed 200 of 4899 vouchers mid-persist).
  // Chunking (SAVEPOINT per voucher, COMMIT per chunk) keeps the same
  // per-voucher failure isolation as the one-per-voucher approach — a bad
  // voucher rolls back only to its savepoint, not the whole chunk — while
  // cutting both the number of round trips and the partial-visibility window
  // by ~CHUNK_SIZE.
  const CHUNK_SIZE = 200
  for (let i = 0; i < vouchers.length; i += CHUNK_SIZE) {
    const chunk = vouchers.slice(i, i + CHUNK_SIZE)
    await prisma.$transaction(async (tx) => {
      for (let j = 0; j < chunk.length; j++) {
        const v = chunk[j]
        const alterId = v.alterId ?? ''
        // The guid-less fallback MUST include the date. Tally frequently reuses/resets
        // voucher numbers (e.g. across months or numbering series), so voucherNo::type
        // alone can collide between two genuinely different vouchers. When that happened,
        // this code (correctly, for the *edited voucher* case) treated the second one as
        // "voucher N was edited" and flipped the first one's isLatest to false — silently
        // discarding a real, unrelated voucher with no error at all. Confirmed happening:
        // a Journal #572 DEPRECIATION entry the extension parsed correctly and the server
        // accepted (0 reported failures) was invisible in every DB read afterward.
        const identityKey = v.guid || `${v.voucherNo}::${v.type}::${v.date}`
        const savepoint = `sp_${i + j}`

        await tx.$executeRawUnsafe(`SAVEPOINT "${savepoint}"`)
        try {
          const existing = await tx.voucher.findFirst({
            where: { companyId, identityKey, isLatest: true },
          })

          if (existing && existing.alterId === alterId) {
            skipped++
          } else {
            if (existing) {
              await tx.voucher.update({ where: { id: existing.id }, data: { isLatest: false } })
            }
            await tx.voucher.create({
              data: {
                companyId,
                identityKey,
                date:           v.date,
                type:           v.type,
                party:          v.party,
                voucherNo:      v.voucherNo,
                amount:         v.amount,
                taxableAmount:  v.taxableAmount,
                alterId,
                guid:           v.guid,
                hasSalesLedger: v.hasSalesLedger ?? false,
                salesLedger:    v.salesLedger,
                purchaseLedger: v.purchaseLedger,
                isLatest:       true,
                ledgerEntries:    { create: v.ledgerEntries ?? [] },
                inventoryEntries: { create: v.inventoryEntries ?? [] },
              },
            })
            inserted++
          }
          await tx.$executeRawUnsafe(`RELEASE SAVEPOINT "${savepoint}"`)
        } catch (err) {
          await tx.$executeRawUnsafe(`ROLLBACK TO SAVEPOINT "${savepoint}"`)
          const message = err instanceof Error ? err.message : String(err)
          failures.push({ voucherNo: v.voucherNo, type: v.type, date: v.date, party: v.party, identityKey, alterId, error: message })
          console.error(
            `[Vouchers] Failed to persist voucher — companyId=${companyId} date=${v.date} type="${v.type}" voucherNo="${v.voucherNo}" party="${v.party}" identityKey="${identityKey}" alterId="${alterId}":`,
            err,
          )
        }
      }
    }, { timeout: 60000 })
  }

  try {
    for (const date of datesBetween(from, to)) {
      await prisma.voucherFetchLog.upsert({
        where:  { companyId_date: { companyId, date } },
        update: { fetchedAt: new Date() },
        create: { companyId, date },
      })
    }
  } catch (err) {
    console.error(`[Vouchers] Failed to write VoucherFetchLog — companyId=${companyId} from=${from} to=${to}:`, err)
  }

  if (failures.length > 0) {
    console.error(`[Vouchers] ${failures.length}/${vouchers.length} voucher(s) failed to persist for companyId=${companyId}, from=${from}, to=${to}`)
  }

  res.json({ inserted, skipped, failed: failures.length, failures })
})

// GET/PUT /api/companies/:id/dashboard-snapshot — "current value" cache for
// Tally queries that can't be scoped to a past date (closing balances,
// receivables/payables, stock value, slow-stock). One row per company.
companiesRouter.get('/companies/:id/dashboard-snapshot', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const snapshot = await prisma.dashboardSnapshot.findUnique({ where: { companyId: req.params.id } })
  res.json(snapshot ?? null)
})

companiesRouter.put('/companies/:id/dashboard-snapshot', async (req, res) => {
  if (!(await canAccessCompany(req.auth, req.params.id))) {
    res.status(403).json({ error: 'Forbidden' }); return
  }
  const schema = z.object({
    cashInHand:         z.number().nullable().optional(),
    bankBalance:        z.number().nullable().optional(),
    receivables:        z.number().nullable().optional(),
    payables:           z.number().nullable().optional(),
    openingStock:       z.number().nullable().optional(),
    closingStock:       z.number().nullable().optional(),
    directExpenseTotal: z.number().nullable().optional(),
    slowStockItems:     z.array(z.record(z.any())).optional(),
    equity:             z.number().nullable().optional(),
    investments:        z.number().nullable().optional(),
    currentLiabilities: z.number().nullable().optional(),
    fixedAssets:        z.number().nullable().optional(),
    totalLoans:         z.number().nullable().optional(),
    bankOD:             z.number().nullable().optional(),
    receivables90d:     z.number().nullable().optional(),
    interestExpenseTotal:        z.number().nullable().optional(),
    taxPaymentTotal:             z.number().nullable().optional(),
    nonOperatingIncomeTotal:     z.number().nullable().optional(),
    nonOperatingInvestmentTotal: z.number().nullable().optional(),
    directorLoansTotal:          z.number().nullable().optional(),
  })
  const result = schema.safeParse(req.body)
  if (!result.success) { res.status(400).json({ error: 'Invalid input' }); return }

  const companyId = req.params.id
  const data = { ...result.data, fetchedAt: new Date() }
  const snapshot = await prisma.dashboardSnapshot.upsert({
    where:  { companyId },
    update: data,
    create: { companyId, ...data },
  })
  res.json(snapshot)
})
