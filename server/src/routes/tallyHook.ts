import { Router, Request, Response, text } from 'express'

export const tallyHookRouter = Router()

// Tally's HTTP JSON data source may POST without an `application/json` content-type,
// which the global express.json() would skip. Capture those bodies as raw text so
// nothing is lost; JSON bodies are still parsed by the global middleware.
const captureRawIfNotJson = text({
  type: (req) => !(req.headers['content-type'] || '').toLowerCase().includes('json'),
  limit: '20mb',
})

tallyHookRouter.post('/tally-hook', captureRawIfNotJson, (req: Request, res: Response) => {
  let body: any = req.body
  if (typeof body === 'string' && body.trim()) {
    try {
      body = JSON.parse(body)
    } catch {
      // leave as raw string — still logged below
    }
  }

  console.log('='.repeat(60))
  console.log('[TallyHook] Received push from Tally')
  console.log('[TallyHook] Content-Type:', req.headers['content-type'] ?? '(none)')
  console.log('[TallyHook] Body:', JSON.stringify(body, null, 2))
  console.log('='.repeat(60))

  // Reply as a one-element JSON array so the Tally collection (Plain JSON) can
  // parse it back into a row exposing $Status and $Message in the Msg Box.
  res.json([{ Status: '1', Message: 'Received by TallyBillSync' }])
})
