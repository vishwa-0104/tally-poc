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

// Tally itself has no LAN route to a server, so it can never fetch the Day
// Book back from us — only the client's own machine (browser + extension)
// can reach Tally's localhost:9000. This just resolves which company's
// browser tab to nudge, then fires a WS event; the actual fetch happens
// client-side via the extension's existing FETCH_DAYBOOK handler.
async function triggerDaybookFetch(companyName: string | null): Promise<void> {
  if (!companyName) {
    console.log('[TallyHook] No COMPANY tag in notify payload — cannot resolve which company to notify')
    return
  }
  const company = await prisma.company.findFirst({ where: { name: companyName } })
  if (!company) {
    console.log('[TallyHook] No company found matching Tally company name:', companyName)
    return
  }
  console.log('[TallyHook] Company matched:', company.name, '(', company.id, ') — notifying via WS')
  notifyCompany(company.id, { type: 'DAYBOOK_TRIGGER', date: todayYYYYMMDD() })
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
  void triggerDaybookFetch(companyName)
})
