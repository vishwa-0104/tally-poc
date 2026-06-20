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
      handleFetchLedgers(payload.tallyUrl, payload.tallyCompany)
        .then(sendResponse)
        .catch((err) => sendResponse({ ledgers: [], error: err.message }))
      return true // keep channel open for async

    case 'FETCH_STOCK_ITEMS':
      handleFetchStockItems(payload.tallyUrl, payload.tallyCompany)
        .then(sendResponse)
        .catch((err) => sendResponse({ stockItems: [], error: err.message }))
      return true

    case 'FETCH_STOCK_GROUPS':
      handleFetchStockGroups(payload.tallyUrl, payload.tallyCompany)
        .then(sendResponse)
        .catch((err) => sendResponse({ stockGroups: [], error: err.message }))
      return true

    case 'FETCH_STOCK_UNITS':
      handleFetchStockUnits(payload.tallyUrl, payload.tallyCompany)
        .then(sendResponse)
        .catch((err) => sendResponse({ stockUnits: [], error: err.message }))
      return true

    case 'FETCH_GODOWNS':
      handleFetchGodowns(payload.tallyUrl, payload.tallyCompany)
        .then(sendResponse)
        .catch((err) => sendResponse({ godowns: [], error: err.message }))
      return true

    case 'FETCH_VOUCHER_TYPES':
      handleFetchVoucherTypes(payload.tallyUrl, payload.tallyCompany)
        .then(sendResponse)
        .catch((err) => sendResponse({ voucherTypes: [], error: err.message }))
      return true

    case 'SYNC_TO_TALLY':
      handleSyncToTally(payload.xml, payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ success: false, created: 0, altered: 0, errors: 1, message: err.message }))
      return true

    case 'CREATE_STOCK_ITEM':
      handleCreateStockItem(payload, payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ success: false, created: 0, altered: 0, errors: 1, message: err.message }))
      return true

    case 'CREATE_STOCK_GROUP':
      handleCreateStockGroup(payload, payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ success: false, created: 0, altered: 0, errors: 1, message: err.message }))
      return true

    case 'CREATE_LEDGER':
      handleCreateLedger(payload, payload.tallyUrl)
        .then(sendResponse)
        .catch((err) => sendResponse({ success: false, created: 0, altered: 0, errors: 1, message: err.message }))
      return true

    case 'SYNC_BANK_TO_TALLY':
      handleSyncBankToTally(payload.rows, payload.bankLedger, payload.tallyUrl, payload.tallyCompany)
        .then(sendResponse)
        .catch((err) => sendResponse({ success: false, created: 0, altered: 0, errors: 1, message: err.message }))
      return true

    case 'FETCH_VOUCHERS':
      handleFetchVouchers(payload.tallyUrl, payload.tallyCompany, payload.fromDate, payload.toDate, payload.voucherType)
        .then(sendResponse)
        .catch((err) => sendResponse({ vouchers: [], error: err.message }))
      return true

    case 'FETCH_SALES_PARTY':
      handleFetchSalesParty(payload.tallyUrl, payload.tallyCompany, payload.fromDate, payload.toDate)
        .then(sendResponse)
        .catch((err) => sendResponse({ parties: [], error: err.message }))
      return true

    case 'FETCH_AGENT':
      handleFetchAgent(payload.endpoint, payload.params)
        .then(sendResponse)
        .catch((err) => sendResponse({ ok: false, error: err.message }))
      return true

    case 'FETCH_DAYBOOK':
      handleFetchDaybook(payload.tallyUrl, payload.tallyCompany, payload.fromDate, payload.toDate)
        .then(sendResponse)
        .catch((err) => sendResponse({ vouchers: [], rawXml: '', error: err.message }))
      return true

    case 'FETCH_SLOW_STOCK':
      handleFetchSlowStock(payload.tallyUrl, payload.tallyCompany)
        .then(sendResponse)
        .catch((err) => sendResponse({ items: [], error: err.message }))
      return true

    case 'FETCH_LEDGER_BALANCES':
      handleFetchLedgerBalances(payload.tallyUrl, payload.tallyCompany, payload.asOfDate)
        .then(sendResponse)
        .catch((err) => sendResponse({ rawLedgers: [], error: err.message }))
      return true

    default:
      sendResponse({ error: `Unknown message type: ${type}` })
  }
})

// ── Fetch ledger names from Tally ────────────────────────────────────────────

function companyVar(tallyCompany) {
  return tallyCompany ? `\n        <SVCURRENTCOMPANY>${tallyCompany}</SVCURRENTCOMPANY>` : ''
}

async function handleFetchLedgers(tallyUrl, tallyCompany) {
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
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${companyVar(tallyCompany)}
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSLedgers" ISMODIFY="No">
            <TYPE>Ledger</TYPE>
            
            <NATIVEMETHOD>Name, Parent, LedgerAddress, StateName, OpeningBalance</NATIVEMETHOD>
            
            <NATIVEMETHOD>PartyGSTIN</NATIVEMETHOD>
            <NATIVEMETHOD>GSTRegistrationType</NATIVEMETHOD>
            
            <NATIVEMETHOD>GstPartyIdentificationNo</NATIVEMETHOD>

            <FETCH>Name, Parent, PartyGSTIN, GstPartyIdentificationNo, GSTRegistrationType, LEDGSTREGDETAILS.*</FETCH>
          </COLLECTION>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)

  // Find and log the first ledger block that contains any GSTIN-like string
  // so we can see the exact tag name Tally is using
  const gstinPatternInXml = responseText.match(/<LEDGER\b[^>]*>[\s\S]{0,2000}?[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z][\s\S]{0,200}?<\/LEDGER>/i)
  if (gstinPatternInXml) {
    console.log('[Invoice ledgers GSTIN block sample]', gstinPatternInXml[0])
  } else {
    console.log('[Invoice ledgers raw - first 8000]', responseText.slice(0, 8000))
  }

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

  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").replace(/&#39;/g, "'").trim()

  for (const match of ledgerBlocks) {
    const block = match[0]

    // Name: try attribute first, then inner tag — decode HTML entities before storing
    let name = decode(block.match(/<LEDGER\s+NAME="([^"]+)"/i)?.[1] ?? '')
    if (!name) name = decode(block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1] ?? '')
    if (!name || seen.has(name)) continue
    seen.add(name)

    // Parent group — TallyPrime wraps in PARENT.LIST, older Tally uses bare <PARENT>
    const group = decode(
      block.match(/<PARENT\.LIST[^>]*>[\s\S]*?<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]
      ?? block.match(/<PARENT[^>]*>([^<]+)<\/PARENT>/i)?.[1]
      ?? ''
    )
    // GSTIN appears under different tag names depending on Tally version:
    // TallyPrime: <PARTYGSTIN> | Tally ERP 9: <INCOMETAXNUMBER> (used for GSTIN)
    // TallyPrime nested: <GSTREGISTRATIONDETAILS.LIST><GSTIN>...</GSTIN>
    const GSTIN_RE = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$/
    const candidateGstin = decode(
      block.match(/<PARTYGSTIN[^>]*>([^<]+)<\/PARTYGSTIN>/i)?.[1]
      ?? block.match(/<FETCHEDGSTIN[^>]*>([^<]+)<\/FETCHEDGSTIN>/i)?.[1]
      ?? block.match(/<GSTREGISTRATIONDETAILS\.LIST[^>]*>[\s\S]*?<GSTIN[^>]*>([^<\s]+)<\/GSTIN>/i)?.[1]
      ?? block.match(/<GSTIN[^>]*>([^<]+)<\/GSTIN>/i)?.[1]
      ?? block.match(/<INCOMETAXNUMBER[^>]*>([^<]+)<\/INCOMETAXNUMBER>/i)?.[1]
      ?? ''
    )
    const gstin = GSTIN_RE.test(candidateGstin) ? candidateGstin : undefined
    const state               = decode(block.match(/<STATENAME[^>]*>([^<]+)<\/STATENAME>/i)?.[1]) || undefined
    const openingBalance      = decode(block.match(/<OPENINGBALANCE[^>]*>([^<]+)<\/OPENINGBALANCE>/i)?.[1]) || undefined
    const gstRegistrationType = decode(block.match(/<GSTREGISTRATIONTYPE[^>]*>([^<]+)<\/GSTREGISTRATIONTYPE>/i)?.[1]) || undefined

    ledgers.push({ name, group, gstin, state, openingBalance, gstRegistrationType })

  }

  return ledgers
}

// ── Fetch stock items from Tally ─────────────────────────────────────────────

async function handleFetchStockItems(tallyUrl, tallyCompany) {
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
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${companyVar(tallyCompany)}
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
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").replace(/&#39;/g, "'").trim()

  for (const match of blocks) {
    const block = match[0]
    let name = decode(block.match(/<STOCKITEM\s+NAME="([^"]+)"/i)?.[1] ?? '')
    if (!name) name = decode(block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1] ?? '')
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

async function handleFetchStockGroups(tallyUrl, tallyCompany) {
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
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${companyVar(tallyCompany)}
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
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").replace(/&#39;/g, "'").trim()

  for (const match of blocks) {
    const block = match[0]
    let name = decode(block.match(/<STOCKGROUP\s+NAME="([^"]+)"/i)?.[1] ?? '')
    if (!name) name = decode(block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1] ?? '')
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

async function handleFetchStockUnits(tallyUrl, tallyCompany) {
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
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${companyVar(tallyCompany)}
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
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").replace(/&#39;/g, "'").trim()

  for (const match of blocks) {
    const block = match[0]
    let name = decode(block.match(/<UNIT\s+NAME="([^"]+)"/i)?.[1] ?? '')
    if (!name) name = decode(block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1] ?? '')
    if (!name || seen.has(name)) continue
    seen.add(name)

    const symbol = decode(block.match(/<SYMBOLORIGINAL[^>]*>([^<]+)<\/SYMBOLORIGINAL>/i)?.[1]) || name
    units.push({ name, symbol })
  }
  return units
}

// ── Fetch godowns from Tally ─────────────────────────────────────────────────

async function handleFetchGodowns(tallyUrl, tallyCompany) {
  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSGodowns</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${companyVar(tallyCompany)}
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSGodowns" ISMODIFY="No">
            <TYPE>Godown</TYPE>
            <NATIVEMETHOD>Name</NATIVEMETHOD>
          </COLLECTION>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  const godowns = parseGodowns(responseText)
  console.log('[Tally godowns] count:', godowns.length)
  return { godowns }
}

function parseGodowns(xml) {
  const seen = new Set()
  const godowns = []
  const blocks = [...xml.matchAll(/<GODOWN\b[^>]*>([\s\S]*?)<\/GODOWN>/gi)]
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").replace(/&#39;/g, "'").trim()

  for (const match of blocks) {
    const block = match[0]
    let name = decode(block.match(/<GODOWN\s+NAME="([^"]+)"/i)?.[1] ?? '')
    if (!name) name = decode(block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1] ?? '')
    if (!name || seen.has(name)) continue
    seen.add(name)
    godowns.push({ name })
  }
  return godowns
}

// ── Fetch voucher types from Tally ───────────────────────────────────────────

async function handleFetchVoucherTypes(tallyUrl, tallyCompany) {
  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSVoucherTypes</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${companyVar(tallyCompany)}
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSVoucherTypes" ISMODIFY="No">
            <TYPE>Voucher Type</TYPE>
            <NATIVEMETHOD>Name</NATIVEMETHOD>
          </COLLECTION>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  const voucherTypes = parseVoucherTypes(responseText)
  console.log('[Tally voucher types] count:', voucherTypes.length)
  return { voucherTypes }
}

function parseVoucherTypes(xml) {
  const seen = new Set()
  const types = []
  const blocks = [...xml.matchAll(/<VOUCHERTYPE\b[^>]*>([\s\S]*?)<\/VOUCHERTYPE>/gi)]
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").replace(/&#39;/g, "'").trim()

  for (const match of blocks) {
    const block = match[0]
    let name = decode(block.match(/<VOUCHERTYPE\s+NAME="([^"]+)"/i)?.[1] ?? '')
    if (!name) name = decode(block.match(/<NAME[^>]*>([^<]+)<\/NAME>/i)?.[1] ?? '')
    if (!name || seen.has(name)) continue
    seen.add(name)
    types.push(name)
  }
  return types
}

// ── Fetch vouchers (for dashboard) ──────────────────────────────────────────

// Convert YYYYMMDD → DD-MMM-YYYY (Tally's native date format for report requests)
function toTallyDisplayDate(yyyymmdd) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  const y = yyyymmdd.slice(0, 4)
  const m = parseInt(yyyymmdd.slice(4, 6), 10) - 1
  const d = yyyymmdd.slice(6, 8)
  return `${d}-${months[m]}-${y}`
}

async function handleFetchVouchers(tallyUrl, tallyCompany, fromDate, toDate, _voucherType) {
  const xml = `<ENVELOPE>
  <HEADER><TALLYREQUEST>Export Data</TALLYREQUEST></HEADER>
  <BODY><EXPORTDATA>
    <REQUESTDESC>
      <REPORTNAME>Sales Register</REPORTNAME>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
        <SVFROMDATE>${toTallyDisplayDate(fromDate)}</SVFROMDATE>
        <SVTODATE>${toTallyDisplayDate(toDate)}</SVTODATE>
        ${tallyCompany ? `<SVCURRENTCOMPANY>${tallyCompany}</SVCURRENTCOMPANY>` : ''}
      </STATICVARIABLES>
    </REQUESTDESC>
  </EXPORTDATA></BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  console.log('[SalesRegister] response length:', responseText.length)
  console.log('[SalesRegister] raw (first 1000):', responseText.slice(0, 1000))

  // Sales Register returns monthly summary (DSPPERIOD + DSPCRAMTA), not individual vouchers
  const vouchers = parseSalesRegisterSummary(responseText, fromDate)
  console.log('[SalesRegister] parsed monthly totals:', JSON.stringify(vouchers))
  return { vouchers }
}

// Parse Sales Register summary response:
// <DSPPERIOD>April</DSPPERIOD>
// <DSPACCINFO><DSPCRAMT><DSPCRAMTA>3225626.00</DSPCRAMTA></DSPCRAMT></DSPACCINFO>
function parseSalesRegisterSummary(xml, fromDate) {
  const MONTHS = { jan:0, feb:1, mar:2, apr:3, may:4, jun:5, jul:6, aug:7, sep:8, oct:9, nov:10, dec:11 }
  const year   = parseInt(fromDate.slice(0, 4), 10)
  const decode = (s) => (s || '').replace(/&amp;/g, '&').trim()

  // Extract all DSPPERIOD and DSPCRAMTA values in order
  const periods = [...xml.matchAll(/<DSPPERIOD[^>]*>([^<]+)<\/DSPPERIOD>/gi)].map(m => decode(m[1]))
  const amounts = [...xml.matchAll(/<DSPCRAMTA[^>]*>([^<]+)<\/DSPCRAMTA>/gi)].map(m => parseFloat(decode(m[1]).replace(/,/g, '')) || 0)

  console.log('[SalesRegister] periods:', periods, '| amounts:', amounts)

  const vouchers = []
  for (let i = 0; i < periods.length; i++) {
    const monthName = periods[i].trim().toLowerCase().slice(0, 3)
    const monthIdx  = MONTHS[monthName]
    if (monthIdx === undefined) continue
    const amount = amounts[i] ?? 0
    if (amount === 0) continue

    // Use financial year logic: Apr-Mar. If month < Apr, it's next year
    const vYear = monthIdx >= 3 ? year : year + 1
    const date  = `${vYear}-${String(monthIdx + 1).padStart(2, '0')}-01`
    vouchers.push({ date, type: 'Sales GST', party: '', amount, voucherNo: '' })
  }
  return vouchers
}

// ── Fetch party-wise sales totals (Sales Register Collection) ───────────────

async function handleFetchSalesParty(tallyUrl, tallyCompany, fromDate, toDate) {
  // TDL Collection with hardcoded date values in the formula so Tally actually filters.
  // $$SVFromDate/$$SVToDate do not resolve inside FILTER formulae — pass dates directly.
  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSSalesParty</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${companyVar(tallyCompany)}
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSSalesParty" ISMODIFY="No">
            <TYPE>Voucher</TYPE>
            <NATIVEMETHOD>Date, VoucherTypeName, PartyLedgerName, Amount</NATIVEMETHOD>
            <FILTER>IsSalesAndInRange</FILTER>
          </COLLECTION>
          <SYSTEM TYPE="Formulae" NAME="IsSalesAndInRange">
            $$Contains:VoucherTypeName:"Sales" AND $$IsInRange:Date:$$StrToDate:"${fromDate}":$$StrToDate:"${toDate}"
          </SYSTEM>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  console.log('[SalesParty] response length:', responseText.length)
  console.log('[SalesParty] raw (first 1000):', responseText.slice(0, 1000))

  console.log('[SalesParty] response length:', responseText.length)
  console.log('[SalesParty] raw (first 500):', responseText.slice(0, 500))

  const decode  = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").trim()
  const blocks  = [...responseText.matchAll(/<VOUCHER\b[^>]*>([\s\S]*?)<\/VOUCHER>/gi)]
  const map     = new Map()

  for (const match of blocks) {
    const block  = match[0]
    const party  = decode(block.match(/<PARTYLEDGERNAME[^>]*>([^<]+)<\/PARTYLEDGERNAME>/i)?.[1] ?? '')
    const amtRaw = decode(block.match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '0')
    const amount = Math.abs(parseFloat(amtRaw.replace(/,/g, '')) || 0)
    if (!party || amount === 0) continue
    map.set(party, (map.get(party) ?? 0) + amount)
  }

  const parties = [...map.entries()]
    .sort(([, a], [, b]) => b - a)
    .map(([name, amount]) => ({ name, amount }))

  console.log(`[SalesParty] voucher blocks=${blocks.length} | unique parties=${parties.length} | top3: ${JSON.stringify(parties.slice(0, 3))}`)
  return { parties }
}

// ── Fetch data from local TallySyncAgent (ODBC bridge on :9001) ─────────────

async function handleFetchAgent(endpoint, params) {
  const query = params && Object.keys(params).length > 0
    ? '?' + new URLSearchParams(params).toString()
    : ''
  const response = await fetch(`http://localhost:9001/${endpoint}${query}`)
  if (!response.ok) throw new Error(`TallySyncAgent error: ${response.status}`)
  return response.json()
}

// ── Fetch Day Book for a single date ────────────────────────────────────────
// Queries the TBSVouchers collection defined in TallySyncBridge.tdl (must be loaded in Tally).
// SVFROMDATE/SVTODATE tell Tally which period to scope to.
// JS date filter applied after parsing as a safety net.

async function handleFetchDaybook(tallyUrl, tallyCompany, fromDate, toDate) {
  const from = toTallyDisplayDate(fromDate)  // "01-Apr-2026"
  const to   = toTallyDisplayDate(toDate)    // "30-Jun-2026"

  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSVouchers</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
        <SVFROMDATE>${from}</SVFROMDATE>
        <SVTODATE>${to}</SVTODATE>
        ${companyVar(tallyCompany)}
      </STATICVARIABLES>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  console.log(`[Daybook/TDL] ${from} → ${to} | response length:`, responseText.length)
  console.log('[Daybook/TDL] raw (first 3000):', responseText.slice(0, 3000))

  const allVouchers = parseVouchers(responseText)

  const fromISO = `${fromDate.slice(0,4)}-${fromDate.slice(4,6)}-${fromDate.slice(6,8)}`
  const toISO   = `${toDate.slice(0,4)}-${toDate.slice(4,6)}-${toDate.slice(6,8)}`
  const vouchers = allVouchers.filter(v => v.date >= fromISO && v.date <= toISO)

  console.log(`[Daybook/TDL] total from Tally: ${allVouchers.length} | in range [${fromISO}..${toISO}]: ${vouchers.length}`)

  // Group by date for easy verification
  const byDate = {}
  for (const v of vouchers) {
    if (!byDate[v.date]) byDate[v.date] = []
    byDate[v.date].push({ type: v.type, amount: v.amount })
  }
  console.log('[Daybook/TDL] grouped by date:', JSON.stringify(byDate, null, 2))

  return { vouchers, rawXml: responseText }
}

// ── Slow / inactive stock ────────────────────────────────────────────────────
// Scans the full financial year of sales vouchers to find the last sale date
// for each stock item. Returns all items with closing stock sorted by
// daysSince desc (never-sold / oldest sale first).

async function handleFetchSlowStock(tallyUrl, tallyCompany) {
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim()
  const pad    = (n) => String(n).padStart(2, '0')

  // Full financial year (Apr 1 → today) to capture complete sale history
  const today  = new Date()
  const fyYear = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1
  const fyFrom = toTallyDisplayDate(`${fyYear}0401`)
  const fyTo   = toTallyDisplayDate(`${today.getFullYear()}${pad(today.getMonth()+1)}${pad(today.getDate())}`)

  const makeXml = (id, from, to) => `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>${id}</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$SysName:XML</SVEXPORTFORMAT>
        <SVFROMDATE>${from}</SVFROMDATE>
        <SVTODATE>${to}</SVTODATE>
        ${companyVar(tallyCompany)}
      </STATICVARIABLES>
    </DESC>
  </BODY>
</ENVELOPE>`

  console.log(`[SlowStock] FY: ${fyFrom} → ${fyTo}`)
  const movementText = await postToTally(makeXml('TBSInventoryMovement', fyFrom, fyTo), tallyUrl)

  // Build lastSaleDate map: itemName → most recent sale date
  const lastSaleMap = {}
  for (const vMatch of movementText.matchAll(/<VOUCHER\b[^>]*>([\s\S]*?)<\/VOUCHER>/gi)) {
    const block = vMatch[0]
    const type  = decode(block.match(/<VOUCHERTYPENAME[^>]*>([^<]+)<\/VOUCHERTYPENAME>/i)?.[1] ?? '')
    if (!type.toLowerCase().includes('sales')) continue
    const rawDate = decode(block.match(/<DATE[^>]*>([^<]+)<\/DATE>/i)?.[1] ?? '')
    if (!rawDate || rawDate.length !== 8) continue
    const isoDate = `${rawDate.slice(0,4)}-${rawDate.slice(4,6)}-${rawDate.slice(6,8)}`
    for (const inv of block.matchAll(/<ALLINVENTORYENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLINVENTORYENTRIES\.LIST>/gi)) {
      const name = decode(inv[0].match(/<STOCKITEMNAME[^>]*>([^<]+)<\/STOCKITEMNAME>/i)?.[1] ?? '')
      if (name && (!lastSaleMap[name] || isoDate > lastSaleMap[name])) lastSaleMap[name] = isoDate
    }
  }

  const todayISO = today.toISOString().slice(0, 10)
  const items = Object.entries(lastSaleMap).map(([name, lastSaleDate]) => {
    const daysSince = Math.floor((new Date(todayISO) - new Date(lastSaleDate)) / 86400000)
    return { name, lastSaleDate, daysSince }
  })

  items.sort((a, b) => b.daysSince - a.daysSince)

  console.log(`[SlowStock] Unique items sold this FY: ${items.length}`)
  console.log('[SlowStock] Top 5 slowest:', JSON.stringify(items.slice(0,5), null, 2))
  return { items }
}


function parseVouchers(xml) {
  const vouchers = []
  const blocks = [...xml.matchAll(/<VOUCHER\b[^>]*>([\s\S]*?)<\/VOUCHER>/gi)]
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").trim()

  for (const match of blocks) {
    const block = match[0]

    const rawDate   = decode(block.match(/<DATE[^>]*>([^<]+)<\/DATE>/i)?.[1] ?? '')
    const type      = decode(block.match(/<VOUCHERTYPENAME[^>]*>([^<]+)<\/VOUCHERTYPENAME>/i)?.[1] ?? '')
    const party     = decode(block.match(/<PARTYLEDGERNAME[^>]*>([^<]+)<\/PARTYLEDGERNAME>/i)?.[1] ?? '')
    const voucherNo = decode(block.match(/<VOUCHERNUMBER[^>]*>([^<]+)<\/VOUCHERNUMBER>/i)?.[1] ?? '')

    if (!rawDate) continue

    // Tally date format: YYYYMMDD → YYYY-MM-DD
    const date = rawDate.length === 8
      ? `${rawDate.slice(0, 4)}-${rawDate.slice(4, 6)}-${rawDate.slice(6, 8)}`
      : rawDate

    // Amount: find LEDGERENTRIES.LIST where ISPARTYLEDGER=Yes (Sales/Receipt vouchers)
    let amount = 0
    const ledgerListRe = /<LEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/LEDGERENTRIES\.LIST>/gi
    for (const le of block.matchAll(ledgerListRe)) {
      const leBlock = le[0]
      if (!/ISPARTYLEDGER[^>]*>Yes/i.test(leBlock)) continue
      const leAmtRaw = decode(leBlock.match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '')
      if (leAmtRaw) { amount = Math.abs(parseFloat(leAmtRaw.replace(/,/g, '')) || 0); break }
    }

    // Fallback: ALLLEDGERENTRIES.LIST where ISPARTYLEDGER=Yes (Payment/Journal vouchers)
    if (amount === 0) {
      for (const le of block.matchAll(/<ALLLEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES\.LIST>/gi)) {
        const leBlock = le[0]
        if (!/ISPARTYLEDGER[^>]*>Yes/i.test(leBlock)) continue
        const leAmtRaw = decode(leBlock.match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '')
        if (leAmtRaw) { amount = Math.abs(parseFloat(leAmtRaw.replace(/,/g, '')) || 0); break }
      }
    }

    // Last fallback: sum ALLINVENTORYENTRIES amounts (taxable value without GST)
    if (amount === 0) {
      for (const ie of block.matchAll(/<ALLINVENTORYENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLINVENTORYENTRIES\.LIST>/gi)) {
        const ieAmt = decode(ie[0].match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '0')
        amount += Math.abs(parseFloat(ieAmt.replace(/,/g, '')) || 0)
      }
    }

    if (amount === 0) continue

    // Taxable amount: total (party) minus GST ledger entries (CGST/SGST/IGST/Cess)
    const GST_RE = /cgst|sgst|igst|cess/i
    let gstTotal = 0
    for (const le of block.matchAll(/<ALLLEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES\.LIST>/gi)) {
      const leBlock  = le[0]
      if (/ISPARTYLEDGER[^>]*>Yes/i.test(leBlock)) continue
      const ledgerName = decode(leBlock.match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '')
      if (!GST_RE.test(ledgerName)) continue
      const leAmtRaw = decode(leBlock.match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '0')
      gstTotal += Math.abs(parseFloat(leAmtRaw.replace(/,/g, '')) || 0)
    }
    const taxableAmount = Math.max(0, amount - gstTotal)

    vouchers.push({ date, type, party, amount, taxableAmount, voucherNo })
  }

  return vouchers
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

// ── Create ledger in Tally ────────────────────────────────────────────────────

async function handleCreateLedger(payload, tallyUrl) {
  const xml = buildLedgerXml(payload)
  console.log('[CreateLedger] Full XML:\n', xml)
  const responseText = await postToTally(xml, tallyUrl)
  console.log('[CreateLedger] Tally raw response:', responseText.slice(0, 3000))
  return parseSyncResponse(responseText)
}

// ── Sync bank transactions to Tally ─────────────────────────────────────────

async function handleSyncBankToTally(rows, bankLedger, tallyUrl, tallyCompany) {
  const esc = (s) => (s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
  const companyLine = tallyCompany ? `\n          <SVCURRENTCOMPANY>${esc(tallyCompany)}</SVCURRENTCOMPANY>` : ''

  const tallymessages = rows.map((row) => {
    const date = (row.date || '').replace(/-/g, '')
    const vchType = row.voucherType || (row.isPayment ? 'Payment' : 'Receipt')
    const amt = Math.abs(row.amount)

    // Payment (money out): Bank Cr, Party Dr
    // Receipt (money in):  Bank Dr, Party Cr
    const bankPositive = row.isPayment ? 'No'  : 'Yes'
    const bankAmt      = row.isPayment ? amt   : -amt
    const partyPositive = row.isPayment ? 'Yes' : 'No'
    const partyAmt      = row.isPayment ? -amt  : amt

    return `        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <VOUCHER VCHTYPE="${esc(vchType)}" ACTION="Create" OBJVIEW="Accounting Voucher View">
            <DATE>${date}</DATE>
            <NARRATION>${esc(row.narration || row.description)}</NARRATION>
            <VOUCHERTYPENAME>${esc(vchType)}</VOUCHERTYPENAME>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${esc(bankLedger)}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>${bankPositive}</ISDEEMEDPOSITIVE>
              <AMOUNT>${bankAmt}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${esc(row.ledger)}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>${partyPositive}</ISDEEMEDPOSITIVE>
              <AMOUNT>${partyAmt}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
          </VOUCHER>
        </TALLYMESSAGE>`
  }).join('\n')

  const xml = `<?xml version="1.0" encoding="utf-8"?>
<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Vouchers</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${companyLine}
        </STATICVARIABLES>
      </REQUESTDESC>
      <REQUESTDATA>
${tallymessages}
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>`

  console.log('[SyncBank] Posting XML to Tally, rows:', rows.length)
  const responseText = await postToTally(xml, tallyUrl)
  console.log('[SyncBank] Tally response:', responseText.slice(0, 2000))
  return parseSyncResponse(responseText)
}

// Maps first-2-digit GSTIN state code → Tally state name
const GSTIN_STATE_MAP = {
  '01': 'Jammu & Kashmir',   '02': 'Himachal Pradesh',  '03': 'Punjab',
  '04': 'Chandigarh',        '05': 'Uttarakhand',        '06': 'Haryana',
  '07': 'Delhi',             '08': 'Rajasthan',          '09': 'Uttar Pradesh',
  '10': 'Bihar',             '11': 'Sikkim',             '12': 'Arunachal Pradesh',
  '13': 'Nagaland',          '14': 'Manipur',            '15': 'Mizoram',
  '16': 'Tripura',           '17': 'Meghalaya',          '18': 'Assam',
  '19': 'West Bengal',       '20': 'Jharkhand',          '21': 'Odisha',
  '22': 'Chhattisgarh',      '23': 'Madhya Pradesh',     '24': 'Gujarat',
  '25': 'Daman & Diu',       '26': 'Dadra & Nagar Haveli', '27': 'Maharashtra',
  '28': 'Andhra Pradesh',    '29': 'Karnataka',          '30': 'Goa',
  '31': 'Lakshadweep',       '32': 'Kerala',             '33': 'Tamil Nadu',
  '34': 'Puducherry',        '35': 'Andaman & Nicobar Islands',
  '36': 'Telangana',         '37': 'Andhra Pradesh',     '38': 'Ladakh',
  '97': 'Other Territory',   '99': 'Centre Jurisdiction',
}

function getFYStartYYYYMMDD() {
  const now = new Date()
  const year = now.getMonth() >= 3 ? now.getFullYear() : now.getFullYear() - 1
  return `${year}0401`
}

function buildLedgerXml({ name, gstin, pan, address, state, pincode, under, gstRegistrationType, tallyCompany }) {
  const esc = (s) => (s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
  const parent = under || 'Sundry Creditors'
  const companyBlock = tallyCompany
    ? `\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>${esc(tallyCompany)}</SVCURRENTCOMPANY>\n        </STATICVARIABLES>`
    : ''
  const today  = getTodayYYYYMMDD()
  const fyStart = getFYStartYYYYMMDD()

  const resolvedState = state?.trim() || (gstin ? (GSTIN_STATE_MAP[gstin.slice(0, 2)] || '') : '')

  // ADDRESS.LIST — split on newline for multi-line addresses
  const addressLines = address?.trim() ? address.trim().split('\n').filter(Boolean) : []
  const addressListBlock = addressLines.length > 0
    ? `\n       <ADDRESS.LIST TYPE="String">\n${addressLines.map(l => `        <ADDRESS>${esc(l)}</ADDRESS>`).join('\n')}\n       </ADDRESS.LIST>` : ''

  const regType = gstRegistrationType || (gstin ? 'Regular' : 'Unregistered/Consumer')
  // VATDEALERTYPE mirrors regType but uses Tally's internal label for Unregistered
  const vatDealerType = regType === 'Unregistered/Consumer' ? 'Unregistered' : regType

  // Always render LEDGSTREGDETAILS.LIST — needed for state/type even without GSTIN
  // Include <GSTIN> only when a GSTIN is actually provided
  const gstBlock = `
      <LEDGSTREGDETAILS.LIST>
       <APPLICABLEFROM>${fyStart}</APPLICABLEFROM>
       <GSTREGISTRATIONTYPE>${esc(regType)}</GSTREGISTRATIONTYPE>${pan ? `
       <INCOMETAXNUMBER>${esc(pan)}</INCOMETAXNUMBER>` : ''}
       <STATE>${esc(resolvedState)}</STATE>
       <PLACEOFSUPPLY>${esc(resolvedState)}</PLACEOFSUPPLY>${gstin ? `
       <GSTIN>${esc(gstin)}</GSTIN>` : ''}
       <ISOTHTERRITORYASSESSEE>No</ISOTHTERRITORYASSESSEE>
       <CONSIDERPURCHASEFOREXPORT>No</CONSIDERPURCHASEFOREXPORT>
       <ISTRANSPORTER>No</ISTRANSPORTER>
       <ISCOMMONPARTY>No</ISCOMMONPARTY>
      </LEDGSTREGDETAILS.LIST>`

  const mailingBlock = `
      <LEDMAILINGDETAILS.LIST>${addressListBlock}
       <APPLICABLEFROM>${fyStart}</APPLICABLEFROM>
       <MAILINGNAME>${esc(name)}</MAILINGNAME>${pincode ? `
       <PINCODE>${esc(pincode)}</PINCODE>` : ''}
       <STATE>${esc(resolvedState)}</STATE>
       <COUNTRY>India</COUNTRY>
      </LEDMAILINGDETAILS.LIST>`

  return `<?xml version="1.0" encoding="utf-8"?>
<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>All Masters</REPORTNAME>${companyBlock}
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <LEDGER NAME="${esc(name)}" RESERVEDNAME="" Action="Create">
            <STARTINGFROM>${fyStart}</STARTINGFROM>
            <CREATEDDATE>${today}</CREATEDDATE>
            
            <PRIORSTATENAME>${esc(resolvedState)}</PRIORSTATENAME>
            <GSTREGISTRATIONTYPE>${esc(regType)}</GSTREGISTRATIONTYPE>
            <VATDEALERTYPE>${esc(vatDealerType)}</VATDEALERTYPE>
            <PARENT>${esc(parent)}</PARENT>
            <TAXTYPE>Others</TAXTYPE>
            <COUNTRYOFRESIDENCE>India</COUNTRYOFRESIDENCE>${gstin ? `
            <PARTYGSTIN>${esc(gstin)}</PARTYGSTIN>` : ''}
            <GSTTYPEOFSUPPLY>Goods</GSTTYPEOFSUPPLY>
            <OLDLEDSTATENAME>${esc(resolvedState)}</OLDLEDSTATENAME>
            <OLDCOUNTRYNAME>India</OLDCOUNTRYNAME>
            <ISBILLWISEON>Yes</ISBILLWISEON>
            <ISCOSTCENTRESON>No</ISCOSTCENTRESON>
            <ISINTERESTON>No</ISINTERESTON>
            <ALLOWINMOBILE>No</ALLOWINMOBILE>
            <LANGUAGENAME.LIST>
              <NAME.LIST TYPE="String">
                <NAME>${esc(name)}</NAME>
              </NAME.LIST>
              <LANGUAGEID> 1033</LANGUAGEID>
            </LANGUAGENAME.LIST>${gstBlock}${mailingBlock}
          </LEDGER>
        </TALLYMESSAGE>
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>`
}

// ── Create stock item in Tally ────────────────────────────────────────────────

async function handleCreateStockItem(payload, tallyUrl) {
  const xml = buildStockItemXml(payload)
  console.log('[CreateStockItem] Full XML:\n', xml)
  const responseText = await postToTally(xml, tallyUrl)
  console.log('[CreateStockItem] Tally raw response:', responseText.slice(0, 3000))
  return parseSyncResponse(responseText)
}

function getTodayYYYYMMDD() {
  const d = new Date()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}${m}${day}`
}

// ── Create stock group in Tally ───────────────────────────────────────────────

async function handleCreateStockGroup(payload, tallyUrl) {
  const xml = buildStockGroupXml(payload)
  console.log('[CreateStockGroup] Full XML:\n', xml)
  const responseText = await postToTally(xml, tallyUrl)
  console.log('[CreateStockGroup] Full Tally response:\n', responseText)
  return parseSyncResponse(responseText)
}

function buildStockGroupXml({ name, parent, tallyCompany }) {
  const companyBlock = tallyCompany
    ? `\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>${tallyCompany}</SVCURRENTCOMPANY>\n        </STATICVARIABLES>`
    : ''

  return `<?xml version="1.0" encoding="utf-8"?>
<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>All Masters</REPORTNAME>${companyBlock}
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <STOCKGROUP NAME="${name}" ACTION="Create">
            <NAME>${name}</NAME>
            <PARENT>${parent || ''}</PARENT>
          </STOCKGROUP>
        </TALLYMESSAGE>
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>`
}

function buildStockItemXml({ name, group, unit, description, gstApplicable, taxability, hsnCode, gstRate, typeOfSupply, tallyCompany }) {
  const applicable = gstApplicable === 'Yes' ? 'Applicable' : 'Not Applicable'
  const date = getTodayYYYYMMDD()

  const hsnBlock = hsnCode ? `
            <HSNDETAILS.LIST>
              <APPLICABLEFROM>${date}</APPLICABLEFROM>
              <HSNCODE>${hsnCode}</HSNCODE>
              ${description ? `<HSN>${description}</HSN>` : ''}
              <SRCOFHSNDETAILS>Specify Details Here</SRCOFHSNDETAILS>
            </HSNDETAILS.LIST>` : ''

  let gstBlock = ''
  if (gstApplicable === 'Yes') {
    const isTaxable = taxability === 'Taxable'

    if (isTaxable && gstRate) {
      const halfRate = gstRate / 2
      gstBlock = `
            <GSTDETAILS.LIST>
              <APPLICABLEFROM>${date}</APPLICABLEFROM>
              <CALCULATIONTYPE>On Value</CALCULATIONTYPE>
              <TAXABILITY>Taxable</TAXABILITY>
              <SRCOFGSTDETAILS>Specify Details Here</SRCOFGSTDETAILS>
              <STATEWISEDETAILS.LIST>
                <STATENAME>&#4; Any</STATENAME>
                <RATEDETAILS.LIST>
                  <GSTRATEDUTYHEAD>CGST</GSTRATEDUTYHEAD>
                  <GSTRATEVALUATIONTYPE>Based on Value</GSTRATEVALUATIONTYPE>
                  <GSTRATE>${halfRate}</GSTRATE>
                  <GSTRATEPERUNIT>0</GSTRATEPERUNIT>
                </RATEDETAILS.LIST>
                <RATEDETAILS.LIST>
                  <GSTRATEDUTYHEAD>SGST/UTGST</GSTRATEDUTYHEAD>
                  <GSTRATEVALUATIONTYPE>Based on Value</GSTRATEVALUATIONTYPE>
                  <GSTRATE>${halfRate}</GSTRATE>
                  <GSTRATEPERUNIT>0</GSTRATEPERUNIT>
                </RATEDETAILS.LIST>
                <RATEDETAILS.LIST>
                  <GSTRATEDUTYHEAD>IGST</GSTRATEDUTYHEAD>
                  <GSTRATEVALUATIONTYPE>Based on Value</GSTRATEVALUATIONTYPE>
                  <GSTRATE>${gstRate}</GSTRATE>
                  <GSTRATEPERUNIT>0</GSTRATEPERUNIT>
                </RATEDETAILS.LIST>
                <RATEDETAILS.LIST>
                  <GSTRATEDUTYHEAD>Cess</GSTRATEDUTYHEAD>
                  <GSTRATEVALUATIONTYPE>&#4; Not Applicable</GSTRATEVALUATIONTYPE>
                  <GSTRATE>0</GSTRATE>
                  <GSTRATEPERUNIT>0</GSTRATEPERUNIT>
                </RATEDETAILS.LIST>
                <RATEDETAILS.LIST>
                  <GSTRATEDUTYHEAD>State Cess</GSTRATEDUTYHEAD>
                  <GSTRATEVALUATIONTYPE>Based on Value</GSTRATEVALUATIONTYPE>
                  <GSTRATE>0</GSTRATE>
                  <GSTRATEPERUNIT>0</GSTRATEPERUNIT>
                </RATEDETAILS.LIST>
              </STATEWISEDETAILS.LIST>
            </GSTDETAILS.LIST>`
    } else {
      gstBlock = `
            <GSTDETAILS.LIST>
              <APPLICABLEFROM>${date}</APPLICABLEFROM>
              <TAXABILITY>${taxability || 'Exempt'}</TAXABILITY>
              <SRCOFGSTDETAILS>Specify Details Here</SRCOFGSTDETAILS>
            </GSTDETAILS.LIST>`
    }
  }

  const companyBlock = tallyCompany
    ? `\n        <STATICVARIABLES>\n          <SVCURRENTCOMPANY>${tallyCompany}</SVCURRENTCOMPANY>\n        </STATICVARIABLES>`
    : ''

  return `<?xml version="1.0" encoding="utf-8"?>
<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>All Masters</REPORTNAME>${companyBlock}
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <STOCKITEM NAME="${name}" ACTION="Create">
            <NAME>${name}</NAME>
            ${group ? `<PARENT>${group}</PARENT>` : ''}
            ${unit ? `<BASEUNITS>${unit}</BASEUNITS>` : ''}
            <GSTAPPLICABLE>${applicable}</GSTAPPLICABLE>
            ${typeOfSupply ? `<GSTTYPEOFSUPPLY>${typeOfSupply}</GSTTYPEOFSUPPLY>` : ''}${hsnBlock}${gstBlock}
          </STOCKITEM>
        </TALLYMESSAGE>
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>`
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
    throw new Error(`Invoice sync server responded with HTTP ${response.status}. Is Invoice ERP running?`)
  }

  return response.text()
}

// ── Cash + Bank ledger balances (closing balance as of a date) ───────────────
// Uses TBSCashBankBalances — filtered to Cash-in-Hand and Bank Accounts groups only.
// Fetching ClosingBalance for ALL ledgers is O(ledgers × transactions) and causes
// Tally to hang. Filtering to ~5-10 ledgers makes this near-instant.

async function handleFetchLedgerBalances(tallyUrl, tallyCompany, asOfDate) {
  const today = new Date()
  const pad   = (n) => String(n).padStart(2, '0')
  const fyYear = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1
  const fyStart = `${fyYear}0401`
  const toDateRaw = asOfDate || `${today.getFullYear()}${pad(today.getMonth() + 1)}${pad(today.getDate())}`

  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSCashBankBalances</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
        <SVFROMDATE>${toTallyDisplayDate(fyStart)}</SVFROMDATE>
        <SVTODATE>${toTallyDisplayDate(toDateRaw)}</SVTODATE>${companyVar(tallyCompany)}
      </STATICVARIABLES>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  console.log('[LedgerBalances] response length:', responseText.length, '| first 1000:', responseText.slice(0, 1000))

  const rawLedgers = parseLedgerBalances(responseText)
  console.log('[LedgerBalances] parsed count:', rawLedgers.length, '| sample:', rawLedgers.slice(0, 5))
  return { rawLedgers }
}

function parseLedgerBalances(xml) {
  const results = []
  const blocks = [...xml.matchAll(/<LEDGER\b[^>]*>([\s\S]*?)<\/LEDGER>/gi)]
  for (const [, inner] of blocks) {
    const nameM   = inner.match(/<NAME[^>]*>\s*([\s\S]*?)\s*<\/NAME>/i)
    const parentM = inner.match(/<PARENT[^>]*>\s*([\s\S]*?)\s*<\/PARENT>/i)
    const balM    = inner.match(/<CLOSINGBALANCE[^>]*>\s*([\s\S]*?)\s*<\/CLOSINGBALANCE>/i)
    if (!nameM) continue
    const name    = nameM[1].trim()
    const group   = parentM ? parentM[1].trim() : ''
    const balance = balM ? parseTallyBalance(balM[1].trim()) : 0
    if (name) results.push({ name, group, balance })
  }
  return results
}

// Tally returns "14000.00 Dr" (asset/positive) or "5000.00 Cr" (liability/negative)
function parseTallyBalance(str) {
  const clean = str.replace(/,/g, '')
  const m = clean.match(/([-\d.]+)\s*(Dr|Cr)?/i)
  if (!m) return 0
  const num  = parseFloat(m[1]) || 0
  const isCr = (m[2] || '').toLowerCase() === 'cr'
  return isCr ? -num : num
}
