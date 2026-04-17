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

    case 'FETCH_STOCK_ITEMS':
      handleFetchStockItems(payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ stockItems: [], error: err.message }))
      return true

    case 'FETCH_STOCK_GROUPS':
      handleFetchStockGroups(payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ stockGroups: [], error: err.message }))
      return true

    case 'FETCH_STOCK_UNITS':
      handleFetchStockUnits(payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ stockUnits: [], error: err.message }))
      return true

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
  // IMPORTANT: the collection name in <ID> and <COLLECTION NAME> must be the same
  // custom name — if it matches a Tally built-in (e.g. "List of Ledgers"), Tally
  // uses its own definition and ignores our NATIVEMETHODs.
  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSLedgers</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSLedgers" ISMODIFY="No">
            <TYPE>Ledger</TYPE>
            <NATIVEMETHOD>Name</NATIVEMETHOD>
            <NATIVEMETHOD>Parent</NATIVEMETHOD>
            <NATIVEMETHOD>PartyGSTIN</NATIVEMETHOD>
            <NATIVEMETHOD>LedgerAddress</NATIVEMETHOD>
            <NATIVEMETHOD>StateName</NATIVEMETHOD>
            <NATIVEMETHOD>OpeningBalance</NATIVEMETHOD>
            <NATIVEMETHOD>GSTRegistrationType</NATIVEMETHOD>
          </COLLECTION>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  console.log('[Tally ledgers raw]', responseText.slice(0, 5000))
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

    const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim()

    // Parent group — TallyPrime wraps in PARENT.LIST, older Tally uses bare <PARENT>
    const group = decode(
      block.match(/<PARENT\.LIST[^>]*>[\s\S]*?<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]
      ?? block.match(/<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]
      ?? ''
    )
    const gstin               = decode(block.match(/<PARTYGSTIN[^>]*>([^<]+)<\/PARTYGSTIN>/i)?.[1]) || undefined
    const state               = decode(block.match(/<STATENAME[^>]*>([^<]+)<\/STATENAME>/i)?.[1]) || undefined
    const openingBalance      = decode(block.match(/<OPENINGBALANCE[^>]*>([^<]+)<\/OPENINGBALANCE>/i)?.[1]) || undefined
    const gstRegistrationType = decode(block.match(/<GSTREGISTRATIONTYPE[^>]*>([^<]+)<\/GSTREGISTRATIONTYPE>/i)?.[1]) || undefined

    ledgers.push({ name, group, gstin, state, openingBalance, gstRegistrationType })

  }

  return ledgers
}

// ── Fetch stock items from Tally ─────────────────────────────────────────────

async function handleFetchStockItems(tallyUrl) {
  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSStockItems</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSStockItems" ISMODIFY="No">
            <TYPE>Stock Item</TYPE>
            <NATIVEMETHOD>Name</NATIVEMETHOD>
            <NATIVEMETHOD>Parent</NATIVEMETHOD>
            <NATIVEMETHOD>BaseUnits</NATIVEMETHOD>
          </COLLECTION>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  const stockItems = parseStockItems(responseText)
  console.log('[Tally stock items] count:', stockItems.length)
  return { stockItems }
}

function parseStockItems(xml) {
  const seen = new Set()
  const items = []
  const blocks = [...xml.matchAll(/<STOCKITEM\b[^>]*>([\s\S]*?)<\/STOCKITEM>/gi)]
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim()

  for (const match of blocks) {
    const block = match[0]
    let name = block.match(/<STOCKITEM\s+NAME="([^"]+)"/i)?.[1]?.trim()
    if (!name) name = block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1]?.trim()
    if (!name || seen.has(name)) continue
    seen.add(name)

    const group = decode(
      block.match(/<PARENT\.LIST[^>]*>[\s\S]*?<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]
      ?? block.match(/<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]
      ?? ''
    )
    const unit = decode(block.match(/<BASEUNITS[^>]*>([^<]+)<\/BASEUNITS>/i)?.[1]) || undefined
    items.push({ name, group, unit })
  }
  return items
}

// ── Fetch stock groups from Tally ─────────────────────────────────────────────

async function handleFetchStockGroups(tallyUrl) {
  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSStockGroups</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSStockGroups" ISMODIFY="No">
            <TYPE>Stock Group</TYPE>
            <NATIVEMETHOD>Name</NATIVEMETHOD>
            <NATIVEMETHOD>Parent</NATIVEMETHOD>
          </COLLECTION>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  const stockGroups = parseStockGroups(responseText)
  console.log('[Tally stock groups] count:', stockGroups.length)
  return { stockGroups }
}

function parseStockGroups(xml) {
  const seen = new Set()
  const groups = []
  const blocks = [...xml.matchAll(/<STOCKGROUP\b[^>]*>([\s\S]*?)<\/STOCKGROUP>/gi)]
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim()

  for (const match of blocks) {
    const block = match[0]
    let name = block.match(/<STOCKGROUP\s+NAME="([^"]+)"/i)?.[1]?.trim()
    if (!name) name = block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1]?.trim()
    if (!name || seen.has(name)) continue
    seen.add(name)

    const parent = decode(
      block.match(/<PARENT\.LIST[^>]*>[\s\S]*?<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]
      ?? block.match(/<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]
      ?? ''
    )
    groups.push({ name, parent })
  }
  return groups
}

// ── Fetch stock units from Tally ─────────────────────────────────────────────

async function handleFetchStockUnits(tallyUrl) {
  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSStockUnits</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSStockUnits" ISMODIFY="No">
            <TYPE>Unit</TYPE>
            <NATIVEMETHOD>Name</NATIVEMETHOD>
            <NATIVEMETHOD>SymbolOriginal</NATIVEMETHOD>
          </COLLECTION>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  const stockUnits = parseStockUnits(responseText)
  console.log('[Tally stock units] count:', stockUnits.length)
  return { stockUnits }
}

function parseStockUnits(xml) {
  const seen = new Set()
  const units = []
  const blocks = [...xml.matchAll(/<UNIT\b[^>]*>([\s\S]*?)<\/UNIT>/gi)]
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim()

  for (const match of blocks) {
    const block = match[0]
    let name = block.match(/<UNIT\s+NAME="([^"]+)"/i)?.[1]?.trim()
    if (!name) name = block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1]?.trim()
    if (!name || seen.has(name)) continue
    seen.add(name)

    const symbol = decode(block.match(/<SYMBOLORIGINAL[^>]*>([^<]+)<\/SYMBOLORIGINAL>/i)?.[1]) || name
    units.push({ name, symbol })
  }
  return units
}

// ── Sync voucher XML to Tally ────────────────────────────────────────────────

async function handleSyncToTally(xml, tallyUrl) {
  console.log('[Sync] XML being posted (first 500 chars):', xml.slice(0, 500))
  console.log('[Sync] XML length:', xml.length, '| has newlines:', xml.includes('\n'))
  const responseText = await postToTally(xml, tallyUrl)
  console.log('[Sync] Tally raw response:', responseText.slice(0, 3000))
  return parseSyncResponse(responseText)
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

  const created     = get('CREATED')
  const altered     = get('ALTERED')
  const errors      = get('ERRORS')
  const exceptions  = get('EXCEPTIONS')

  // Extract any descriptive error/exception tags Tally may include.
  // TallyPrime uses several different tag names depending on version and error type.
  const allErrors = [
    ...xml.matchAll(/<(?:LINEERROR|IMPORTERROR|TALERROR|EXCEPTIONMSG|ERROR|IMPORTEXCEPTION|DSPERROR|LONGMSG|SHORTMSG|EXCEPTIONERROR|DESC)>([^<]+)<\/(?:LINEERROR|IMPORTERROR|TALERROR|EXCEPTIONMSG|ERROR|IMPORTEXCEPTION|DSPERROR|LONGMSG|SHORTMSG|EXCEPTIONERROR|DESC)>/gi),
  ]
    .map((m) => m[1].trim())
    .filter(Boolean)
  console.log('[Sync] Parsed — created:', created, 'errors:', errors, 'exceptions:', exceptions, 'messages:', allErrors)
  console.log('[Sync] Full Tally response:', xml.slice(0, 2000))

  if (errors > 0 || exceptions > 0 || created === 0) {
    let message = allErrors.length > 0 ? allErrors.join('; ') : null

    if (!message && exceptions > 0) {
      message = `Tally exception: a ledger name may not exist in Tally, or the voucher type is not configured. Open the browser console (F12) to see the full Tally response and verify your CGST/SGST ledger names match exactly.`
    }

    return {
      success: false,
      created,
      altered,
      errors,
      message: message ?? 'Tally returned 0 created vouchers. Check ledger names and try again.',
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
