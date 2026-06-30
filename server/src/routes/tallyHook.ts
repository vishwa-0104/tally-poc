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
  console.log('[TallyHook] body type    :', typeof req.body)
  console.log('[TallyHook] RAW BODY >>>\n', req.body, '\n<<<')
  console.log('='.repeat(60))

  const body = parseBody(req)

  // Return XML — Tally's HTTP Post action expects XML back, not JSON.
  // JSON causes "Invalid data. Could not process XML format" in Tally.
  res.set('Content-Type', 'text/xml')
  res.send('<?xml version="1.0"?><RESPONSE><STATUS>1</STATUS><MESSAGE>Received</MESSAGE></RESPONSE>')
})
