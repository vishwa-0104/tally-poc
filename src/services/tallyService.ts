import type { TallyLedger, TallySyncResult } from '@/types'

const EXTENSION_MSG_TIMEOUT = 10_000

/**
 * Send a message to the extension via the content script bridge.
 * Uses window.postMessage so we never call chrome.runtime directly from
 * the page — this avoids the MV3 service-worker-sleep issue.
 */
async function sendToExtension<T>(type: string, payload: Record<string, unknown>): Promise<T> {
  return new Promise((resolve, reject) => {
    const msgId = Math.random().toString(36).slice(2)

    const timer = setTimeout(() => {
      window.removeEventListener('message', handler)
      const err = new Error(`[TallySync] Timeout: no response from extension for "${type}". Is the extension installed and enabled?`)
      console.error(err.message)
      reject(err)
    }, EXTENSION_MSG_TIMEOUT)

    function handler(event: MessageEvent) {
      if (!event.data?.__tallyReply || event.data.__msgId !== msgId) return
      clearTimeout(timer)
      window.removeEventListener('message', handler)
      if (event.data.error) {
        const err = new Error(`[TallySync] Extension error for "${type}": ${event.data.error}`)
        console.error(err.message)
        reject(err)
      } else {
        console.log(`[TallySync] "${type}" response:`, event.data)
        resolve(event.data as T)
      }
    }

    console.log(`[TallySync] Sending "${type}"`, payload)
    window.addEventListener('message', handler)
    window.postMessage({ __tallyMsg: true, __msgId: msgId, type, ...payload }, '*')
  })
}

// ── Public API ─────────────────────────────────────────────

export async function fetchTallyLedgers(tallyUrl: string): Promise<TallyLedger[]> {
  console.log('[Step 1] Fetching ledgers from Tally:', tallyUrl)
  const result = await sendToExtension<{ ledgers: TallyLedger[] }>('FETCH_LEDGERS', { tallyUrl })
  console.log('[Step 2] Ledgers received from Tally extension. Count:', result.ledgers.length, '| Sample:', result.ledgers.slice(0, 3))
  return result.ledgers
}

export async function syncToTally(xml: string, tallyUrl: string): Promise<TallySyncResult> {
  console.log('[Sync] Posting XML to Tally at:', tallyUrl)
  console.log('[Sync] XML payload:\n', xml)
  const result = await sendToExtension<TallySyncResult>('SYNC_TO_TALLY', { xml, tallyUrl })
  console.log('[Sync] Tally response:', result)
  return result
}
