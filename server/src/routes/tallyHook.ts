import { Router, Request, Response } from 'express'

export const tallyHookRouter = Router()

tallyHookRouter.post('/tally-hook', (req: Request, res: Response) => {
  const body = req.body

  console.log('='.repeat(60))
  console.log('[TallyHook] Received push from Tally')
  console.log('[TallyHook] Raw body:', JSON.stringify(body, null, 2))
  console.log('[TallyHook] guid       :', body?.guid)
  console.log('[TallyHook] alterId    :', body?.alterId)
  console.log('[TallyHook] date       :', body?.date)
  console.log('[TallyHook] type       :', body?.type)
  console.log('[TallyHook] party      :', body?.party)
  console.log('[TallyHook] voucherNo  :', body?.voucherNo)
  console.log('[TallyHook] amount     :', body?.amount)
  console.log('[TallyHook] deleted    :', body?.deleted ?? false)
  console.log('='.repeat(60))

  res.json({ ok: true, received: body?.guid ?? null })
})
