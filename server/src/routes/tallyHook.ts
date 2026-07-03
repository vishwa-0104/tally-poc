import { Router, Request, Response, text } from 'express'
import { prisma } from '../db'
import { notifyCompany } from '../ws'

export const tallyHookRouter = Router()

// Accept any content-type — Tally sends XML (text/xml) without Plain JSON:Yes,
// or JSON (application/json) with Plain JSON:Yes. The global express.json()
// middleware already handles JSON; this catches everything else as raw text.
const captureRaw = text({
  type: () => true,
  limit: '20mb',
})

function extractXml(xml: string, tag: string): string {
  const m = xml.match(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'i'))
  return m ? m[1].trim() : ''
}

function parseBody(req: Request): Record<string, any> {
  const raw: any = req.body
  if (raw && typeof raw === 'object') return raw   // already parsed as JSON

  const str = typeof raw === 'string' ? raw : ''
  if (!str) return {}

  // Try JSON first (fallback)
  try { return JSON.parse(str) } catch {}

  // Tally XML — pull the fields we care about
  return {
    guid:      extractXml(str, 'GUID')      || null,
    alterId:   extractXml(str, 'ALTERID')   || null,
    date:      extractXml(str, 'DATE')      || null,
    type:      extractXml(str, 'TYPE')      || null,
    party:     extractXml(str, 'PARTY')     || null,
    voucherNo: extractXml(str, 'VOUCHERNO') || null,
    amount:    extractXml(str, 'AMOUNT')    || null,
    test:      extractXml(str, 'TEST')      || null,
    company:   extractXml(str, 'COMPANY')   || null,
    rawXml:    str,
  }
}

function todayYYYYMMDD(): string {
  const d = new Date()
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}${m}${day}`
}

const MONTH_ABBR: Record<string, string> = {
  jan: '01', feb: '02', mar: '03', apr: '04', may: '05', jun: '06',
  jul: '07', aug: '08', sep: '09', oct: '10', nov: '11', dec: '12',
}

// Tally's $$String:$Date (from the TDL's ?d= query param) renders as e.g.
// "1-Jul-26" or "19-Jun-26" — day (no leading zero), 3-letter month, 2-digit
// year — not the YYYYMMDD format the rest of the app uses. Returns null if
// the string doesn't match (missing param, older un-reloaded TDL, or an
// unexpected Tally date format) so the caller can fall back to today.
function parseTallyDisplayDate(raw: string | undefined): string | null {
  if (!raw) return null
  const m = raw.trim().match(/^(\d{1,2})-([A-Za-z]{3})-(\d{2})$/)
  if (!m) return null
  const [, day, monAbbr, yy] = m
  const mon = MONTH_ABBR[monAbbr.toLowerCase()]
  if (!mon) return null
  return `20${yy}${mon}${day.padStart(2, '0')}`
}

interface VoucherIdentity {
  guid?:      string
  voucherNo?: string
  type?:      string
  alterId?:   string
}

// Tally can fire FormAccept twice for a single voucher edit — confirmed: two
// notify POSTs with the identical guid/alterId arriving back to back, no
// Alt+B button involved (that was removed separately). This is Tally's own
// internal event firing, not something the TDL can reliably prevent, so
// duplicates are collapsed here instead: a second notify for the same
// voucher within DEDUP_WINDOW_MS is logged but doesn't fire a second WS
// trigger. Keyed per company since two different companies' voucher notifies
// arriving close together are NOT duplicates of each other.
const DEDUP_WINDOW_MS = 10 * 1000
const lastNotified = new Map<string, { key: string; at: number }>()

// Tally itself has no LAN route to a server, so it can never fetch the Day
// Book back from us — only the client's own machine (browser + extension)
// can reach Tally's localhost:9000. This just resolves which company's
// browser tab to nudge, then fires a WS event; the actual fetch happens
// client-side via the extension's existing FETCH_DAYBOOK handler.
async function triggerDaybookFetch(companyName: string | null, voucherDateRaw: string | undefined, identity: VoucherIdentity): Promise<void> {
  if (!companyName) {
    console.log('[TallyHook] No COMPANY tag in notify payload — cannot resolve which company to notify')
    return
  }
  const company = await prisma.company.findFirst({ where: { name: companyName } })
  if (!company) {
    console.log('[TallyHook] No company found matching Tally company name:', companyName)
    return
  }
  // Prefer the edited voucher's own date (so a backdated edit refetches the
  // right day, not always today) — falls back to today if the TDL hasn't
  // been reloaded yet or the date didn't parse.
  const parsedDate = parseTallyDisplayDate(voucherDateRaw)
  const date = parsedDate ?? todayYYYYMMDD()
  if (!parsedDate) {
    console.log('[TallyHook] Could not resolve voucher date from', JSON.stringify(voucherDateRaw), '— falling back to today:', date)
  }

  const dedupKey = identity.guid || `${identity.voucherNo ?? ''}::${identity.type ?? ''}::${date}::${identity.alterId ?? ''}`
  const now = Date.now()
  const last = lastNotified.get(company.id)
  if (last && last.key === dedupKey && now - last.at < DEDUP_WINDOW_MS) {
    console.log('[TallyHook] Duplicate notify for the same voucher within', DEDUP_WINDOW_MS / 1000, 's — skipping second WS trigger. key:', dedupKey)
    return
  }
  lastNotified.set(company.id, { key: dedupKey, at: now })

  console.log('[TallyHook] Company matched:', company.name, '(', company.id, ') — notifying via WS for date', date)
  notifyCompany(company.id, { type: 'DAYBOOK_TRIGGER', date })
}

tallyHookRouter.post('/tally-hook', captureRaw, (req: Request, res: Response) => {
  console.log('='.repeat(60))
  console.log('[TallyHook] Content-Type :', req.headers['content-type'] ?? '(none)')
  console.log('[TallyHook] RAW BODY     :', req.body)

  // Company name travels in the URL query string — expressions there evaluate
  // in the live Form context, unlike XML body fields which need a Repeat
  // context that Action:HTTP Post never provides (see comment in the TDL file).
  const q = req.query as Record<string, string>
  console.log('[TallyHook] QUERY company:', q.company ?? '(empty)')
  let companyName: string | null = q.company ?? null
  const voucherDateRaw: string | undefined = q.d

  if (q.g || q.d || q.t) {
    console.log('[TallyHook] QUERY DATA >>>')
    console.log('  guid      :', q.g  ?? '(empty)')
    console.log('  date      :', q.d  ?? '(empty)')
    console.log('  type      :', q.t  ?? '(empty)')
    console.log('  party     :', q.p  ?? '(empty)')
    console.log('  voucherNo :', q.n  ?? '(empty)')
    console.log('  amount    :', q.a  ?? '(empty)')
    console.log('  alterId   :', q.ai ?? '(empty)')
    console.log('<<<')
  } else {
    // Fallback: try to parse body (XML or JSON) — kept for older/other callers
    // that still send company as a body field.
    const body = parseBody(req)
    console.log('[TallyHook] BODY DATA >>>', body, '<<<')
    companyName = companyName ?? body.company ?? null
  }
  console.log('='.repeat(60))

  const contentType = req.headers['content-type'] ?? ''
  if (contentType.includes('json')) {
    // Walk Collection (Data Source:HTTP JSON, Plain JSON:Yes) needs JSON back to parse rows.
    res.json([{ Status: '1', Message: 'Received by TallyBillSync' }])
  } else {
    // Plain HTTP Post action (ASCII/XML) — Tally expects a valid XML body back,
    // otherwise it shows "Invalid data. Could not process XML format".
    res.type('text/xml').send('<RESPONSE><STATUS>1</STATUS><MESSAGE>Received by TallyBillSync</MESSAGE></RESPONSE>')
  }

  // Fire-and-forget: doesn't block the response above — Tally already has its answer.
  void triggerDaybookFetch(companyName, voucherDateRaw, { guid: q.g, voucherNo: q.n, type: q.t, alterId: q.ai })
})
