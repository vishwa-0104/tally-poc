import { Router, Request, Response, text } from 'express'

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

tallyHookRouter.post('/tally-hook', captureRaw, (req: Request, res: Response) => {
  console.log('='.repeat(60))
  console.log('[TallyHook] Content-Type :', req.headers['content-type'] ?? '(none)')
  console.log('[TallyHook] RAW BODY     :', req.body)

  // Primary path: data in URL query string (TDL URL expression approach)
  const q = req.query as Record<string, string>
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
    // Fallback: try to parse body (XML or JSON)
    const body = parseBody(req)
    console.log('[TallyHook] BODY DATA >>>', body, '<<<')
  }
  console.log('='.repeat(60))

  // Walk Collection (Data Source:HTTP JSON) needs JSON back to parse rows.
  res.json([{ Status: '1', Message: 'Received by TallyBillSync' }])
})
