# CLAUDE.md — Tally Bill Sync

This file is loaded at the start of every Claude Code session. Read it fully before taking any action.

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
├── src/                    # React frontend
│   ├── components/
│   │   ├── admin/          # Admin-only UI components
│   │   ├── company/        # Company-only UI components
│   │   ├── shared/         # Used by both portals (AppLayout, ProtectedRoute, ExtensionStatus)
│   │   └── ui/             # Design system (Button, Input, Select, Modal, Badge, StatCard)
│   ├── hooks/              # useExtension.ts, useTallyLedgers.ts
│   ├── lib/                # api.ts (axios), utils.ts, validators.ts (Zod), mockData.ts
│   ├── pages/              # admin/, company/, LandingPage, LoginPage
│   ├── services/           # aiService.ts (parse), tallyService.ts (extension messaging)
│   ├── store/              # Zustand: authStore, billStore, companyStore
│   └── types/index.ts      # All TypeScript interfaces
├── server/
│   ├── prisma/
│   │   ├── schema.prisma   # DB schema (User, Company, Bill, LineItem)
│   │   └── seed.ts         # Idempotent seed with upsert
│   └── src/
│       ├── routes/         # auth.ts, bills.ts, companies.ts
│       ├── middleware/auth.ts  # JWT verify, req.auth, requireAdmin
│       ├── app.ts          # Express app, CORS, Helmet, routes
│       ├── db.ts           # Prisma client singleton
│       └── index.ts        # Server entry
├── extension/              # Chrome extension
│   ├── manifest.json       # MV3, externally_connectable for localhost
│   ├── background.js       # Service worker: PING, FETCH_LEDGERS, SYNC_TO_TALLY
│   ├── popup.html/js       # Test connection UI
├── Dockerfile              # Frontend: Node builder → Nginx
├── server/Dockerfile       # Backend: Node builder → Node runtime
├── docker-compose.yml      # 3 services: postgres, backend, frontend
├── nginx.conf              # /api/* → backend:3001, SPA fallback
└── server/entrypoint.sh    # prisma db push → seed → node dist/index.js
```

---

## Environment Variables

### Root `.env` (affects both frontend build and backend)

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Claude API key. Without it, AI parsing returns mock data |
| `JWT_SECRET` | Yes | Token signing secret. Change before production |
| `VITE_CHROME_EXTENSION_ID` | For Tally sync | Chrome extension ID from `chrome://extensions`. Empty = mock mode |

### Dev-only (not needed for Docker)

| Variable | Description |
|----------|-------------|
| `VITE_ALLOW_EXTENSION_MOCK` | `true` to simulate extension connected in UI |
| `VITE_ALLOW_SYNC_MOCK` | `true` to return fake successful sync result |

### Frontend env access
```typescript
import.meta.env.VITE_CHROME_EXTENSION_ID  // baked in at build time
```

### Backend env access
```typescript
process.env.ANTHROPIC_API_KEY  // runtime
```

> **Important**: `VITE_*` variables are baked into the frontend bundle at build time. Changing them requires a rebuild (`docker-compose up --build`).

---

## Database Schema

```
User ──many-to-one──► Company ──one-to-many──► Bill ──one-to-many──► LineItem
```

Bill status lifecycle:
```
parsed → mapped → synced
              ↓
            error
```

Prisma binary targets include `linux-musl-openssl-3.0.x` (required for Alpine Docker). Do not remove this.

Schema is applied via `prisma db push` (not `prisma migrate deploy` — no migration files exist).

---

## API Routes

Base: `/api`

```
POST   /auth/login                          → { token, user }
POST   /auth/register                       → { token, user }

GET    /companies                           → Company[] (admin only)
POST   /companies                           → Create company + user (admin only)
GET    /companies/:id                       → Company
PUT    /companies/:id/mapping               → Update ledger mapping

GET    /companies/:companyId/bills          → Bill[] with lineItems
POST   /companies/:companyId/bills          → Create bill
GET    /bills/:id                           → Bill with lineItems
PUT    /bills/:id                           → Update bill (status, mapping, lineItems)
DELETE /bills/:id                           → Delete
POST   /bills/parse                         → AI parse: { base64, mediaType } → ParsedBillData

GET    /health                              → { ok: true }
```

Auth: all routes except `/auth/*` and `/health` require `Authorization: Bearer <token>`.

Company-role users can only access their own `companyId` data. Admin has no `companyId`.

---

## Chrome Extension Messaging Contract

The frontend calls `chrome.runtime.sendMessage(extensionId, message, callback)`. The extension service worker handles three message types:

| Type | Payload | Response |
|------|---------|----------|
| `PING` | — | `{ version: string }` |
| `FETCH_LEDGERS` | `{ port: number }` | `{ ledgers: { name: string; group: string }[] }` |
| `SYNC_TO_TALLY` | `{ xml: string; port: number }` | `TallySyncResult` |

```typescript
interface TallySyncResult {
  success: boolean
  created: number
  altered: number
  errors: number
  message?: string
}
```

If `VITE_CHROME_EXTENSION_ID` is not set or `chrome.runtime` is unavailable, `tallyService.ts` falls back to `simulateExtensionResponse()` which returns mock data.

Ledger filtering in `MappingForm.tsx`:
- **Vendor**: group matches `sundry creditor/debtor`
- **Purchase**: group matches `purchase`
- **CGST/SGST/IGST**: name contains `cgst`/`sgst`/`igst`
- Falls back to all ledgers if filtered list is empty

---

## State Management (Zustand)

Three stores, all backed by REST API:

```typescript
// authStore — persisted to localStorage key 'tally-auth'
{ user, token, isAuthenticated, login(), logout() }

// companyStore — fetched from /api/companies
{ companies, fetchCompanies(), addCompany(), getCompany(),
  incrementSynced(), decrementPending(), ... }

// billStore — fetched per company
{ bills, fetchBills(), addBill(), getBill(), updateBillStatus() }
```

Axios interceptor (`src/lib/api.ts`) reads JWT from `localStorage.getItem('tally-auth')` → parses Zustand persist wrapper → injects `Authorization` header.

---

## Forms

All forms use **React Hook Form** + **Zod** resolver. Schemas are in `src/lib/validators.ts`:

| Schema | Used in |
|--------|---------|
| `loginSchema` | LoginPage |
| `newCompanySchema` | AddCompanyModal |
| `mappingSchema` | MappingForm |

The `mappingSchema` requires `vendorLedger`, `purchaseLedger`, `cgstLedger`, `sgstLedger` (all `min(1)`). This is intentional — these must be filled before syncing to Tally.

---

## Tally XML

The `buildTallyXml()` function in `src/lib/utils.ts` generates a `TALLYMESSAGE` Purchase voucher XML. The extension POSTs this to `http://localhost:{port}`.

Tally's response is parsed for `<CREATED>`, `<ALTERED>`, `<ERRORS>` tags to determine success.

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
| Async API calls | `fetch*`, `sync*`, `parse*` prefix | `fetchTallyLedgers()` |

---

## Coding Standards

- TypeScript strict mode. Fix type errors, never use `any` unless unavoidable.
- No unused imports or variables (ESLint zero-warning policy).
- Format: No Prettier config — match surrounding code style.
- Tailwind for all styling. Custom classes in `src/index.css` (`.input-base`, `.input-error`, `.card`).
- `cn()` utility from `src/lib/utils.ts` for conditional Tailwind classes.
- Do not add docstrings or comments unless logic is non-obvious.
- Do not add error handling for scenarios that cannot happen.

---

## Docker Notes

- Frontend image: Node 20 builder → Nginx Alpine. Built from root `Dockerfile`.
- Backend image: Node 20 Alpine builder (with `openssl`) → Node 20 Alpine runtime. Built from `server/Dockerfile`.
- Prisma requires `openssl` in Alpine — both builder and runtime stages install it via `apk add --no-cache openssl`.
- Prisma `binaryTargets` must include `linux-musl-openssl-3.0.x` in `schema.prisma`.
- `server/entrypoint.sh` must have LF line endings (enforced by `.gitattributes`).
- Node modules are copied from builder to runtime stage (not reinstalled) to preserve Prisma postinstall artifacts.

---

## Plan Mode

Use plan mode (`EnterPlanMode`) before starting any task that:
- Touches more than 2–3 files
- Changes existing API contracts (routes, message types, Zod schemas)
- Modifies the database schema
- Adds a new page or major feature
- Changes auth or role logic

For small fixes (single file, clear change), skip plan mode and act directly.

Context Management Rule: > "Monitor the session context window. If the context exceeds 60% capacity, automatically execute the /compact command with a summary of the current task and pending items before proceeding with the next command."
