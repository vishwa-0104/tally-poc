/**
 * Tally Bill Sync — Chrome Extension Service Worker
 *
 * Handles messages from the web app and proxies requests to the
 * local Tally ERP server (bypassing browser CORS restrictions).
 *
 * Message types:
 *   PING              → { version: string }
 *   FETCH_LEDGERS     → { port: number }  ← returns { ledgers: string[] }
 *   SYNC_TO_TALLY     → { xml: string, port: number }  ← returns TallySyncResult
 */

const VERSION = '1.0.0'

// Keep service worker alive — MV3 workers shut down after ~30s of inactivity
chrome.runtime.onInstalled.addListener(() => {})
chrome.runtime.onStartup.addListener(() => {})

// ── Message entry point ──────────────────────────────────────────────────────

// Internal messages from content script (content script → background bypasses CORS)
chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  const { type, ...payload } = message ?? {}

  switch (type) {
    case 'FETCH_LEDGERS':
      handleFetchLedgers(payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ ledgers: [], error: err.message }))
      return true // keep channel open for async

    case 'SYNC_TO_TALLY':
      handleSyncToTally(payload.xml, payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ success: false, created: 0, altered: 0, errors: 1, message: err.message }))
      return true

    default:
      sendResponse({ error: `Unknown message type: ${type}` })
  }
})

// ── Fetch ledger names from Tally ────────────────────────────────────────────

async function handleFetchLedgers(tallyUrl) {
  const xml = `<COLLECTION NAME="List of Ledgers" ISMODIFY="No">
  <TYPE>Ledger</TYPE>
  <NATIVEMETHOD>Name</NATIVEMETHOD>
  <NATIVEMETHOD>Parent</NATIVEMETHOD>
  <!-- add any of these: -->
  <NATIVEMETHOD>PartyGSTIN</NATIVEMETHOD>
  <NATIVEMETHOD>LedgerAddress</NATIVEMETHOD>
  <NATIVEMETHOD>StateName</NATIVEMETHOD>
  <NATIVEMETHOD>OpeningBalance</NATIVEMETHOD>
  <NATIVEMETHOD>GSTRegistrationType</NATIVEMETHOD>
  <NATIVEMETHOD>LedgerPhone</NATIVEMETHOD>
  <NATIVEMETHOD>LedgerMobile</NATIVEMETHOD>
  <NATIVEMETHOD>LedgerEmail</NATIVEMETHOD>
</COLLECTION>`

  const responseText = await postToTally(xml, tallyUrl)
  const ledgers = parseLedgers(responseText)
  return { ledgers }
}

/**
 * Parse ledger name + parent group from Tally's XML response.
 * Returns [{ name, group }]
 *
 * TallyPrime uses <LEDGER NAME="..."> attribute format.
 * Older Tally uses <NAME>...</NAME> <PARENT>...</PARENT> inside <LEDGER> blocks.
 */
function parseLedgers(xml) {
  const seen = new Set()
  const ledgers = []

  // TallyPrime: <LEDGER NAME="Cash"><PARENT.LIST ...><PARENT>Capital Account</PARENT>...
  const ledgerBlocks = [...xml.matchAll(/<LEDGER\b[^>]*>([\s\S]*?)<\/LEDGER>/gi)]

  for (const match of ledgerBlocks) {
    const block = match[0]

    // Name: try attribute first, then inner tag
    let name = block.match(/<LEDGER\s+NAME="([^"]+)"/i)?.[1]?.trim()
    if (!name) name = block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1]?.trim()
    if (!name || seen.has(name)) continue
    seen.add(name)

    // Parent group
    let group = block.match(/<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]?.trim() ?? ''
    // Decode common XML entities
    group = group.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    const gstin = block.match(/<PARTYGSTIN[^>]*>([^<]*)<\/PARTYGSTIN>/i)?.[1]?.trim() || undefined
    const address = block.match(/<LEDGERADDRESS[^>]*>([^<]+)<\/LEDGERADDRESS>/i)?.[1]?.trim() || undefined
    const state = block.match(/<STATENAME[^>]*>([^<]+)<\/STATENAME>/i)?.[1]?.trim() || undefined

    ledgers.push({ name, group, gstin, address, state })

  }

  return ledgers
}

// ── Sync voucher XML to Tally ────────────────────────────────────────────────

async function handleSyncToTally(xml, tallyUrl) {
  const responseText = await postToTally(xml, tallyUrl)
  console.log('[Tally raw]', responseText.slice(0, 3000))  // first 3000 chars
  const ledgers = parseLedgers(responseText)
}

/**
 * Parse Tally's import response.
 * Tally returns something like:
 *   <RESPONSE><CREATED>1</CREATED><ALTERED>0</ALTERED><ERRORS>0</ERRORS></RESPONSE>
 */
function parseSyncResponse(xml) {
  const get = (tag) => {
    const m = xml.match(new RegExp(`<${tag}>(\\d+)</${tag}>`, 'i'))
    return m ? parseInt(m[1], 10) : 0
  }

  const created = get('CREATED')
  const altered = get('ALTERED')
  const errors  = get('ERRORS')

  // Tally sometimes returns an error description
  const errDesc = xml.match(/<LINEERROR>([^<]+)<\/LINEERROR>/i)?.[1]
    ?? xml.match(/<ERROR>([^<]+)<\/ERROR>/i)?.[1]
    ?? null

  if (errors > 0 || created === 0) {
    return {
      success: false,
      created,
      altered,
      errors,
      message: errDesc ?? 'Tally returned 0 created vouchers. Check ledger names and try again.',
    }
  }

  return { success: true, created, altered, errors }
}

// ── HTTP helper ──────────────────────────────────────────────────────────────

async function postToTally(xml, tallyUrl) {
  const url = tallyUrl || 'http://localhost:9000'

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'text/xml;charset=UTF-8',
      'ngrok-skip-browser-warning': '1',
    },
    body: xml,
  })

  if (!response.ok) {
    throw new Error(`Tally server responded with HTTP ${response.status}. Is Tally running?`)
  }

  return response.text()
}
