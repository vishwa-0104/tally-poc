/**
 * Local listener for Tally's own voucher-save webhook — this is the fix for
 * the "push doesn't reach the live server" gap: extension/TallySyncBridge.tdl
 * hardcodes its FormAccept POST target to http://127.0.0.1/api/tally-hook
 * (Tally's own machine's loopback). On the real deployment (one shared cloud
 * backend, many customers each running their own local Tally), that request
 * never left the customer's machine before — nothing was listening there.
 * Electron already runs on that same machine, at that same address, so this
 * server just needs to exist; zero TDL/Tally-side changes required.
 *
 * Query-string parsing ported from server/src/routes/tallyHook.ts (Tally's
 * Action:HTTP Post on a Form has no Repeat context, so the TDL carries every
 * field as a URL query param rather than XML body fields — see that file's
 * and the TDL's own comments for why). The settle-delay + Day Book refetch +
 * dashboard-snapshot refresh sequencing is ported from
 * src/hooks/useDaybookNotifications.ts's handleTrigger(), but calls
 * tally-bridge.cjs's handlers directly (same process, no IPC/extension hop)
 * instead of sendToExtension, and POSTs results to the real cloud backend
 * over HTTPS instead of relying on the browser's own axios instance.
 */

const http = require('http')
const { URL } = require('url')
const { handlers } = require('./tally-bridge.cjs')

// Port 80 needs elevated privileges on every OS tested (confirmed: macOS
// EACCES for a normal user process) — Windows (Tally's primary platform)
// is no more permissive for a non-admin app. Using a high port avoids
// asking users to run the whole app elevated just for this listener.
// extension/TallySyncBridge.tdl's two Action:HTTP Post URLs are set to
// match this exact port — keep both in sync if either changes.
const HOOK_PORT = parseInt(process.env.TALLY_HOOK_PORT || '8765', 10)
const API_BASE_URL = process.env.ELECTRON_API_BASE_URL || 'http://localhost:3001/api'

const POST_SAVE_SETTLE_DELAY_MS = 15 * 1000
const HEAVY_REFRESH_COOLDOWN_MS = 15 * 60 * 1000
const DEDUP_WINDOW_MS = 10 * 1000

const lastNotified = new Map()
const lastHeavyRefreshAt = new Map()

let mainWindow = null

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function todayYYYYMMDD() {
  const d = new Date()
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}${m}${day}`
}

function fmt(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

// Same FY-start rule as Dashboard.tsx's 'ytd' preset / useDaybookNotifications.ts's ytdRange().
function ytdRange() {
  const today = new Date()
  const fyStart = today.getMonth() >= 3
    ? new Date(today.getFullYear(), 3, 1)
    : new Date(today.getFullYear() - 1, 3, 1)
  return { from: fmt(fyStart), to: fmt(today) }
}

const MONTH_ABBR = {
  jan: '01', feb: '02', mar: '03', apr: '04', may: '05', jun: '06',
  jul: '07', aug: '08', sep: '09', oct: '10', nov: '11', dec: '12',
}

// Tally's $$String:$Date (from the TDL's ?d= query param) renders as e.g.
// "1-Jul-26" — day (no leading zero), 3-letter month, 2-digit year — ported
// verbatim from server/src/routes/tallyHook.ts's parseTallyDisplayDate.
function parseTallyDisplayDate(raw) {
  if (!raw) return null
  const m = raw.trim().match(/^(\d{1,2})-([A-Za-z]{3})-(\d{2})$/)
  if (!m) return null
  const [, day, monAbbr, yy] = m
  const mon = MONTH_ABBR[monAbbr.toLowerCase()]
  if (!mon) return null
  return `20${yy}${mon}${day.padStart(2, '0')}`
}

// The renderer already holds the logged-in session (token + which company is
// active) in the same localStorage shape useAuthStore persists to ('tally-auth').
// Reading it fresh on demand avoids caching a token that can go stale, and
// needs zero changes to the React app — same trick preload.cjs and main.cjs
// intentionally avoid needing: no new IPC contract, just reading state the
// app already keeps.
async function getSession() {
  if (!mainWindow || mainWindow.isDestroyed()) return null
  const raw = await mainWindow.webContents.executeJavaScript(
    "window.localStorage.getItem('tally-auth')",
  )
  if (!raw) return null
  try {
    const { state } = JSON.parse(raw)
    if (!state?.token || !state?.activeCompanyId) return null
    return { token: state.token, companyId: state.activeCompanyId }
  } catch {
    return null
  }
}

async function apiRequest(method, path, token, body) {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })
  if (!res.ok) throw new Error(`${method} ${path} -> HTTP ${res.status}`)
  const text = await res.text()
  return text ? JSON.parse(text) : null
}

async function handleTrigger(voucherDateRaw, identity) {
  const session = await getSession()
  if (!session) {
    console.log('[HookServer] No active session in the app window — skipping (log in first)')
    return
  }
  const { token, companyId } = session

  const parsedDate = parseTallyDisplayDate(voucherDateRaw)
  const today = todayYYYYMMDD()
  const date = parsedDate ?? today

  const dedupKey = identity.guid || `${identity.voucherNo ?? ''}::${identity.type ?? ''}::${date}::${identity.alterId ?? ''}`
  const now = Date.now()
  const last = lastNotified.get(companyId)
  if (last && last.key === dedupKey && now - last.at < DEDUP_WINDOW_MS) {
    console.log('[HookServer] Duplicate notify within', DEDUP_WINDOW_MS / 1000, 's — skipping. key:', dedupKey)
    return
  }
  lastNotified.set(companyId, { key: dedupKey, at: now })

  // Give Tally time to finish writing/indexing the voucher internally before
  // re-querying it (FormAccept firing isn't the same instant as the save
  // being fully committed — see useDaybookNotifications.ts for the same note).
  await sleep(POST_SAVE_SETTLE_DELAY_MS)

  let tallyUrl = 'http://localhost:9000'
  try {
    const company = await apiRequest('GET', `/companies/${companyId}`, token)
    if (company?.port) tallyUrl = `http://localhost:${company.port}`
  } catch (err) {
    console.error('[HookServer] Failed to look up company Tally port, using default 9000:', err.message)
  }
  const tallyCompany = undefined // resolved server-side from companyId; Tally itself only has one open company anyway

  const daybookDate    = /^\d{8}$/.test(date) ? date : today
  const daybookDateIso = `${daybookDate.slice(0, 4)}-${daybookDate.slice(4, 6)}-${daybookDate.slice(6, 8)}`

  let settings
  try {
    settings = await apiRequest('GET', `/companies/${companyId}/dashboard-settings`, token)
  } catch (err) {
    console.error('[HookServer] Failed to fetch dashboard settings:', err.message)
    settings = {}
  }
  const salesSettings = settings.today ?? {}

  try {
    const { vouchers } = await handlers.FETCH_DAYBOOK({
      tallyUrl, tallyCompany, fromDate: daybookDate, toDate: daybookDate,
      salesAccounts:           salesSettings.salesAccounts,
      salesIncludeVouchers:    salesSettings.salesIncludeVouchers,
      salesExcludeVouchers:    salesSettings.salesExcludeVouchers,
      cashInflowLedgers:       settings.today?.cashInflowLedgers,
      bankLedgers:             settings.today?.bankLedgers,
      purchaseAccounts:        settings.ytd?.purchaseAccounts,
      indirectExpenseLedgers:         settings.ytd?.indirectExpenseLedgers,
      indirectExpenseIncludeVouchers: settings.ytd?.indirectExpenseIncludeVouchers,
      indirectExpenseExcludeVouchers: settings.ytd?.indirectExpenseExcludeVouchers,
      indirectIncomeLedgers:          settings.ytd?.indirectIncomeLedgers,
      indirectIncomeIncludeVouchers:  settings.ytd?.indirectIncomeIncludeVouchers,
      indirectIncomeExcludeVouchers:  settings.ytd?.indirectIncomeExcludeVouchers,
      ebitdaLedgers:                  settings.ytd?.ebitdaLedgers,
      ebitdaIncludeVouchers:          settings.ytd?.ebitdaIncludeVouchers,
      ebitdaExcludeVouchers:          settings.ytd?.ebitdaExcludeVouchers,
    })
    console.log('[HookServer] Fetched', vouchers.length, 'voucher(s) for', daybookDate)
    await apiRequest('POST', `/companies/${companyId}/vouchers`, token, {
      from: daybookDateIso, to: daybookDateIso, vouchers,
    })
  } catch (err) {
    console.error('[HookServer] Failed to fetch/persist Day Book:', err.message)
  }

  // Refresh the "current snapshot" too — same cooldown-gated heavy-query
  // skip as useDaybookNotifications.ts, so a burst of saves doesn't re-run
  // the heaviest queries (stock value, slow stock) on every single one.
  try {
    const { from: ytdFrom, to: ytdTo } = ytdRange()
    const lastHeavy = lastHeavyRefreshAt.get(companyId) ?? 0
    const refreshHeavy = Date.now() - lastHeavy >= HEAVY_REFRESH_COOLDOWN_MS

    const [balancesRes, groupRes, slowStockRes, stockValueRes, directExpRes] = await Promise.allSettled([
      handlers.FETCH_LEDGER_BALANCES({ tallyUrl, tallyCompany, asOfDate: today }),
      handlers.FETCH_GROUP_BALANCES({ tallyUrl, tallyCompany }),
      refreshHeavy ? handlers.FETCH_SLOW_STOCK({ tallyUrl, tallyCompany }) : Promise.resolve(null),
      refreshHeavy ? handlers.FETCH_STOCK_VALUE({ tallyUrl, tallyCompany, fromDate: ytdFrom.replace(/-/g, ''), toDate: ytdTo.replace(/-/g, '') }) : Promise.resolve(null),
      handlers.FETCH_LEDGER_AMOUNTS({ tallyUrl, tallyCompany, fromDate: ytdFrom.replace(/-/g, ''), toDate: ytdTo.replace(/-/g, ''), ledgerNames: settings.ytd?.directExpenseLedgers }),
    ])
    if (refreshHeavy) lastHeavyRefreshAt.set(companyId, Date.now())

    const rawLedgers = balancesRes.status === 'fulfilled' ? balancesRes.value.rawLedgers : []
    const cashInHand = rawLedgers.length
      ? -rawLedgers.filter((l) => l.group.toLowerCase().includes('cash')).reduce((s, l) => s + l.balance, 0)
      : null
    const bankBalance = rawLedgers.length
      ? -rawLedgers.filter((l) => l.group.toLowerCase().includes('bank')).reduce((s, l) => s + l.balance, 0)
      : null

    const patch = {
      cashInHand,
      bankBalance,
      receivables:        groupRes.status === 'fulfilled' ? groupRes.value.receivables : null,
      payables:           groupRes.status === 'fulfilled' ? groupRes.value.payables    : null,
      directExpenseTotal: directExpRes.status === 'fulfilled' ? directExpRes.value?.total ?? null : null,
    }
    if (refreshHeavy) {
      patch.openingStock   = stockValueRes.status === 'fulfilled' ? stockValueRes.value?.openingStock ?? null : null
      patch.closingStock   = stockValueRes.status === 'fulfilled' ? stockValueRes.value?.closingStock ?? null : null
      patch.slowStockItems = slowStockRes.status === 'fulfilled' ? slowStockRes.value?.items ?? [] : []
    }

    await apiRequest('PUT', `/companies/${companyId}/dashboard-snapshot`, token, patch)
  } catch (err) {
    console.error('[HookServer] Failed to refresh dashboard snapshot:', err.message)
  }
}

function sendXmlAck(res) {
  res.writeHead(200, { 'Content-Type': 'text/xml' })
  res.end('<RESPONSE><STATUS>1</STATUS><MESSAGE>Received by TallyBillSync</MESSAGE></RESPONSE>')
}

function sendJsonAck(res) {
  res.writeHead(200, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify([{ Status: '1', Message: 'Received by TallyBillSync' }]))
}

function start(win) {
  mainWindow = win

  const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://127.0.0.1:${HOOK_PORT}`)
    if (req.method !== 'POST' || url.pathname !== '/api/tally-hook') {
      res.writeHead(404)
      res.end()
      return
    }

    const q = Object.fromEntries(url.searchParams)
    console.log('[HookServer] tally-hook hit — company:', q.company ?? '(empty)', 'date:', q.d ?? '(empty)')

    const contentType = req.headers['content-type'] ?? ''
    if (contentType.includes('json')) sendJsonAck(res)
    else sendXmlAck(res)

    // Fire-and-forget — Tally already has its answer above.
    void handleTrigger(q.d, { guid: q.g, voucherNo: q.n, type: q.t, alterId: q.ai }).catch((err) => {
      console.error('[HookServer] handleTrigger failed:', err)
    })
  })

  server.on('error', (err) => {
    if (err.code === 'EACCES') {
      console.error(
        `[HookServer] Permission denied binding port ${HOOK_PORT} (ports <1024 need elevated privileges on ` +
        `some OSes). Either run the app elevated, or add ":<port>" to the two Action:HTTP Post URLs in ` +
        `extension/TallySyncBridge.tdl and set TALLY_HOOK_PORT to match.`,
      )
    } else if (err.code === 'EADDRINUSE') {
      console.error(`[HookServer] Port ${HOOK_PORT} is already in use — another process (or another instance of this app) is bound to it.`)
    } else {
      console.error('[HookServer] Server error:', err)
    }
  })

  server.listen(HOOK_PORT, '127.0.0.1', () => {
    console.log(`[HookServer] Listening on http://127.0.0.1:${HOOK_PORT}/api/tally-hook`)
  })

  return server
}

module.exports = { start }
