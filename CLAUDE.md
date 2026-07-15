# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## What This App Does

AI-powered purchase bill parser + Tally ERP sync tool. Users upload a bill photo or PDF → Claude extracts structured data → user maps to Tally ledger names → Chrome extension POSTs XML to local Tally ERP.

Three portals: **Admin** (manage companies), **Company** (upload + sync bills), **Public** (landing + login).

---

## Architecture Overview

```
Browser (React/Vite)
  ↕ /api/* (Nginx proxy in Docker, Vite dev proxy in local)
Express + Prisma (Node 20)
  ↕ PostgreSQL (Prisma ORM)

Browser ↔ Chrome Extension ↔ Tally ERP (localhost:9000)
```

### Key layers

| Layer | Location | Tech |
|-------|----------|------|
| Frontend | `src/` | React 18, TypeScript, Vite, Zustand, React Hook Form, Zod, Tailwind |
| Backend | `server/src/` | Express, TypeScript, Prisma, JWT, bcrypt |
| Database | Docker service | PostgreSQL 16 |
| Extension | `extension/` | Chrome MV3, service worker |
| Container | root | Docker Compose (3 services: postgres, backend, frontend) |

---

## Running the App

```bash
# Production (Docker)
docker-compose up --build

# Reset DB and rebuild
docker-compose down -v && docker-compose up --build

# Local dev (two terminals)
npm run dev              # frontend on :3000
cd server && npm run dev # backend on :3001
```

App URL: `http://localhost` (Docker) or `http://localhost:3000` (dev)

Default accounts (seeded):
- Admin: `admin@tallysync.com` / `admin123`
- Company: `groceries@sharma.com` / `company123`

---

## Project Structure

```
tally-bill-sync/
├── src/
│   ├── components/
│   │   ├── admin/          # Admin-only UI components
│   │   ├── company/        # Company-only UI components
│   │   ├── shared/         # AppLayout, ProtectedRoute, ExtensionStatus
│   │   └── ui/             # Design system (Button, Input, Select, Modal, Badge, StatCard)
│   ├── hooks/              # useExtension.ts, useTallyLedgers.ts
│   ├── lib/                # api.ts (axios), utils.ts, validators.ts (Zod), mockData.ts
│   ├── pages/
│   │   ├── admin/          # AdminDashboard, AdminCompanies, AdminUsers, AdminLeads, AdminAnalytics
│   │   └── company/        # Dashboard, CompanyBills, BankStatement, BankReconciliation,
│   │                       # CashBook, VendorReconciliation, CompanySettings, CompanySyncLog
│   ├── services/           # aiService.ts (Claude parse), tallyService.ts (extension messaging)
│   ├── store/              # Zustand: authStore, billStore, companyStore
│   └── types/index.ts      # All TypeScript interfaces
├── server/
│   ├── prisma/
│   │   ├── schema.prisma   # DB schema
│   │   └── seed.ts         # Idempotent seed with upsert
│   └── src/
│       ├── routes/         # auth.ts, bills.ts, companies.ts, users.ts, leads.ts
│       ├── middleware/auth.ts  # JWT verify, req.auth, requireAdmin
│       ├── app.ts          # Express app, routes mounted at /api
│       ├── db.ts           # Prisma client singleton
│       └── index.ts        # Server entry
├── extension/
│   ├── background.js       # Service worker — all Tally communication lives here
│   └── popup.html/js       # Test connection UI
└── server/entrypoint.sh    # prisma db push → seed → node dist/index.js
```

---

## Environment Variables

### Root `.env`

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Without it, AI parsing returns mock data |
| `JWT_SECRET` | Yes | Token signing secret |
| `VITE_CHROME_EXTENSION_ID` | For Tally sync | From `chrome://extensions`. Empty = mock mode |
| `VITE_ALLOW_EXTENSION_MOCK` | Dev only | `true` to simulate extension connected |
| `VITE_ALLOW_SYNC_MOCK` | Dev only | `true` to return fake sync result |

`VITE_*` variables are baked into the frontend bundle at build time — changing them requires a rebuild.

---

## Database Schema

```
User ──many-to-one──► Company ──one-to-many──► Bill ──one-to-many──► LineItem
                              └──one-to-many──► SalesTarget
```

Bill status lifecycle: `parsed → mapped → synced` (or `error`)

Key schema notes:
- Schema is applied via `prisma db push` — no migration files exist.
- Prisma `binaryTargets` must include `linux-musl-openssl-3.0.x` (Alpine Docker). Do not remove.
- `SalesTarget`: stores monthly sales targets per company per financial year (`fyYear` = year April starts, e.g. 2025 for FY2025-26; `month` = calendar month 1–12).

---

## API Routes

Base: `/api`. All routes except `/auth/*` and `/health` require `Authorization: Bearer <token>`.
Company-role users can only access their own `companyId`. Admin has no `companyId`.

```
POST   /auth/login
POST   /auth/register

GET    /companies                              → admin only
POST   /companies                             → admin only
GET    /companies/:id
PATCH  /companies/:id                         → admin only
PATCH  /companies/:id/quota                   → admin only
GET    /companies/:id/parse-usage             → admin only
GET    /companies/:id/features
PUT    /companies/:id/mapping
GET    /companies/:id/ledgers
PUT    /companies/:id/ledgers
GET    /companies/:id/stock-items
PUT    /companies/:id/stock-items
GET    /companies/:id/stock-groups
PUT    /companies/:id/stock-groups
GET    /companies/:id/stock-units
PUT    /companies/:id/stock-units
GET    /companies/:id/stock-item-aliases
POST   /companies/:id/stock-item-aliases
POST   /companies/:id/voucher-counter/next
GET    /companies/:id/targets                 → monthly sales targets for current FY
PUT    /companies/:id/targets                 → upsert { fyYear, targets: [{month, target}] }

GET    /companies/:companyId/bills
POST   /companies/:companyId/bills
GET    /bills/:id
PUT    /bills/:id
DELETE /bills/:id
POST   /bills/parse                           → AI parse: { base64, mediaType }
POST   /bank/parse                            → parse bank statement
POST   /reconcile/analyze                     → reconciliation analysis

GET    /health
```

---

## Chrome Extension Messaging Contract

`tallyService.ts` calls `chrome.runtime.sendMessage(extensionId, { type, ...payload }, callback)`. All Tally HTTP calls are made by the extension (not the browser) to bypass CORS. If the extension ID is not set, `sendToExtension()` falls back to mock data.

| Type | Purpose |
|------|---------|
| `PING` | Check extension alive → `{ version }` |
| `FETCH_LEDGERS` | All ledgers with group + GSTIN → `{ ledgers }` |
| `FETCH_STOCK_ITEMS` | Stock items → `{ items }` |
| `FETCH_STOCK_GROUPS` | Stock groups → `{ groups }` |
| `FETCH_STOCK_UNITS` | Units of measure → `{ units }` |
| `FETCH_GODOWNS` | Godowns/warehouses → `{ godowns }` |
| `FETCH_VOUCHER_TYPES` | Voucher type names → `{ voucherTypes }` |
| `FETCH_VOUCHERS` | Vouchers in date range by type → `{ vouchers: TallyVoucher[] }` |
| `FETCH_SALES_PARTY` | Sales totals by party → `{ parties }` |
| `FETCH_DAYBOOK` | All vouchers in date range → `{ vouchers: TallyVoucher[] }` |
| `FETCH_SLOW_STOCK` | Items with no recent sales → `{ items: SlowStockItem[] }` |
| `FETCH_AGENT` | TallySyncAgent proxy (top-debtors, health) → varies |
| `SYNC_TO_TALLY` | POST purchase voucher XML → `TallySyncResult` |
| `SYNC_BANK_TO_TALLY` | POST bank entries as vouchers → `TallySyncResult` |
| `CREATE_LEDGER` | Create new ledger in Tally |
| `CREATE_STOCK_ITEM` | Create new stock item |
| `CREATE_STOCK_GROUP` | Create new stock group |

### TallyVoucher fields

```typescript
interface TallyVoucher {
  date:          string  // YYYY-MM-DD
  type:          string  // voucher type name e.g. "Sales"
  party:         string
  amount:        number  // total including GST (party ledger value)
  taxableAmount: number  // amount minus CGST/SGST/IGST/Cess entries
  voucherNo:     string
}
```

Always use `taxableAmount` for sales reporting/KPIs. `amount` includes GST.

### Ledger filtering in `MappingForm.tsx`
- **Vendor**: group matches `sundry creditor/debtor`
- **Purchase**: group matches `purchase`
- **CGST/SGST/IGST**: name contains `cgst`/`sgst`/`igst`
- Falls back to all ledgers if filtered list is empty

### Known Tally export quirk — VOUCHERRETAINKEY ghost vouchers

The `TBSVouchers` TDL collection (queried by `FETCH_DAYBOOK`) can return "ghost" vouchers that Tally's own native reports (Day Book, Sales Register) no longer show — e.g. a leftover duplicate from a manually-edited voucher, still exported as a live record even though Tally's UI has already superseded it. Neither `<ISDELETED>` nor a `<CANCELLED>`/`<ISOPTIONAL>` tag flags this (confirmed absent/always "No" in a full raw export). The reliable signal is **`<VOUCHERRETAINKEY>` — a real, currently-visible-in-Tally voucher always has a non-zero value; a ghost voucher has `0`**. `parseVouchers()` in `extension/background.js` skips any voucher block with `VOUCHERRETAINKEY=0` (logged as `[GhostVoucher] Skipped ...` in the extension's service worker console).

Diagnosed 2026-07-16: a manually-created test voucher (duplicated from a real one to test push-from-Tally sync) left a ghost duplicate that inflated Total Sales/Gross Margin/EBITDA/Net Profit for New Ruchi Paints. The ghost voucher's `<REFERENCE>` tag pointed back to the original voucher's number — a byproduct of how it was created, not a reliable general-purpose signal on its own. If numbers mismatch Tally again, check for `VOUCHERRETAINKEY=0` in a raw XML export before assuming a caching/classification bug (`extension/background.js`'s `handleFetchDaybook` can be temporarily instrumented to log/extract specific `<VOUCHER>` blocks by GUID for this kind of investigation — see git history around this note for the pattern used).

---

## Company Dashboard

`src/pages/company/Dashboard.tsx` — three-tab layout:

| Tab | Content |
|-----|---------|
| **Performance** | Date filter + KPI row (Sales, EBITDA, Slow Moving Stock) + Sales Trend chart + Top Debtors table. Auto-fetches today on mount. |
| **Analysis** | Static dummy charts (sales by category, YoY comparison). Placeholder for future. |
| **CFO Suggestions** | Static AI-style insight cards. Placeholder for future. |

**Date filters**: Today · This Quarter (FY quarter) · This Year (full FY Apr–Mar) · Custom.
- Granularity auto-selects: Today→daily, Quarter→weekly, Year→monthly.
- Target achievement comparison shown on Sales KPI only for Quarter / Year / Custom-that-aligns-to-a-valid-FY-quarter. Hidden for Today and arbitrary custom ranges.

**Sales targets**: Fetched from `/companies/:id/targets`. Monthly values (Apr–Mar). Configured via a modal opened from a gear icon in the dashboard header.

---

## State Management (Zustand)

```typescript
// authStore — persisted to localStorage key 'tally-auth'
{ user, token, isAuthenticated, login(), logout() }

// companyStore
{ companies, fetchCompanies(), addCompany(), getCompany(), incrementSynced(), ... }

// billStore — fetched per company
{ bills, fetchBills(), addBill(), getBill(), updateBillStatus() }
```

Axios interceptor (`src/lib/api.ts`) reads JWT from localStorage → parses Zustand persist wrapper → injects `Authorization` header.

---

## Forms

All forms use **React Hook Form** + **Zod** resolver. Schemas in `src/lib/validators.ts`.

---

## Tally XML

`buildTallyXml()` in `src/lib/utils.ts` generates a `TALLYMESSAGE` Purchase voucher XML posted via the extension to `http://localhost:{port}`. Tally response is parsed for `<CREATED>`, `<ALTERED>`, `<ERRORS>` tags.

---

## Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Page files | PascalCase, domain prefix | `AdminDashboard.tsx`, `CompanyBills.tsx` |
| Component files | PascalCase | `BillsTable.tsx`, `AddCompanyModal.tsx` |
| Hook files | `use` prefix | `useTallyLedgers.ts` |
| Store files | `*Store.ts` | `billStore.ts` |
| Service files | `*Service.ts` | `aiService.ts` |
| Types | All in `src/types/index.ts` | |
| Async API calls | `fetch*`, `sync*`, `parse*` prefix | |

---

## Coding Standards

- TypeScript strict mode. Fix type errors, never use `any` unless unavoidable.
- No unused imports or variables (ESLint zero-warning policy).
- No Prettier config — match surrounding code style.
- Tailwind for all styling. Custom classes in `src/index.css` (`.input-base`, `.input-error`, `.card`).
- `cn()` from `src/lib/utils.ts` for conditional Tailwind classes.
- No docstrings or comments unless logic is non-obvious.

---

## Docker Notes

- Frontend image: Node 20 builder → Nginx Alpine (`Dockerfile` at root).
- Backend image: Node 20 Alpine builder → Node 20 Alpine runtime (`server/Dockerfile`). Both stages need `apk add --no-cache openssl`.
- Node modules copied from builder to runtime (not reinstalled) to preserve Prisma postinstall artifacts.
- `server/entrypoint.sh` must have LF line endings (enforced by `.gitattributes`).

---

## Plan Mode

Use `EnterPlanMode` before starting any task that:
- Touches more than 2–3 files
- Changes existing API contracts (routes, message types, Zod schemas)
- Modifies the database schema
- Adds a new page or major feature
- Changes auth or role logic

For small fixes (single file, clear change), skip plan mode and act directly.

> Context Management: if the session context exceeds 60% capacity, run `/compact` with a summary of current task and pending items before continuing.
