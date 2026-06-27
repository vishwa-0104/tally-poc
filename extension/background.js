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

    case 'FETCH_DAYBOOK':
      handleFetchDaybook(
        payload.tallyUrl, payload.tallyCompany, payload.fromDate, payload.toDate,
        payload.salesAccounts            || [],
        payload.salesIncludeVouchers     || [],
        payload.salesExcludeVouchers     || [],
        payload.cashInflowLedgers        || [],
        payload.bankLedgers              || [],
        payload.purchaseAccounts         || [],
        payload.indirectExpenseLedgers   || [],
        payload.indirectIncomeLedgers    || [],
        payload.indirectExpenseVouchers  || [],
        payload.indirectIncomeVouchers   || [],
      )
        .then(sendResponse)
        .catch((err) => sendResponse({ vouchers: [], rawXml: '', cashFlow: { inflow: 0, outflow: 0 }, bankFlow: { inflow: 0, outflow: 0 }, error: err.message }))
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

    case 'FETCH_GROUP_BALANCES':
      handleFetchGroupBalances(payload.tallyUrl, payload.tallyCompany, payload.asOfDate)
        .then(sendResponse)
        .catch((err) => sendResponse({ receivables: 0, payables: 0, error: err.message }))
      return true

    case 'FETCH_STOCK_VALUE':
      handleFetchStockValue(payload.tallyUrl, payload.tallyCompany, payload.fromDate, payload.toDate)
        .then(sendResponse)
        .catch((err) => sendResponse({ openingStock: 0, closingStock: 0, error: err.message }))
      return true

    case 'FETCH_LEDGER_AMOUNTS':
      handleFetchLedgerAmounts(payload.tallyUrl, payload.tallyCompany, payload.fromDate, payload.toDate, payload.ledgerNames)
        .then(sendResponse)
        .catch((err) => sendResponse({ total: 0, error: err.message }))
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
  const vouchers = parseSalesRegisterSummary(responseText, fromDate)
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
  // $$StrToDate expects DD-MMM-YYYY format, same as toTallyDisplayDate produces.
  const from = toTallyDisplayDate(fromDate)
  const to   = toTallyDisplayDate(toDate)
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
            $$Contains:VoucherTypeName:"Sales" AND $$IsInRange:Date:$$StrToDate:"${from}":$$StrToDate:"${to}"
          </SYSTEM>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
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

  return { parties }
}

// ── Fetch Day Book for a single date ────────────────────────────────────────
// Queries the TBSVouchers collection defined in TallySyncBridge.tdl (must be loaded in Tally).
// SVFROMDATE/SVTODATE tell Tally which period to scope to.
// JS date filter applied after parsing as a safety net.

async function handleFetchDaybook(tallyUrl, tallyCompany, fromDate, toDate, salesAccounts = [], salesIncludeVouchers = [], salesExcludeVouchers = [], cashInflowLedgers = [], bankLedgers = [], purchaseAccounts = [], indirectExpenseLedgers = [], indirectIncomeLedgers = [], indirectExpenseVouchers = [], indirectIncomeVouchers = []) {
  console.log('[BankDebug] handleFetchDaybook received bankLedgers:', bankLedgers)
  const from = toTallyDisplayDate(fromDate)
  const to   = toTallyDisplayDate(toDate)

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

  const fromISO = `${fromDate.slice(0,4)}-${fromDate.slice(4,6)}-${fromDate.slice(6,8)}`
  const toISO   = `${toDate.slice(0,4)}-${toDate.slice(4,6)}-${toDate.slice(6,8)}`

  const { vouchers: allVouchers, cashFlow, bankFlow, topItems, indExpTotal, indIncTotal } = parseVouchers(responseText, salesAccounts, salesIncludeVouchers, salesExcludeVouchers, cashInflowLedgers, fromISO, toISO, bankLedgers, purchaseAccounts, indirectExpenseLedgers, indirectIncomeLedgers, indirectExpenseVouchers, indirectIncomeVouchers)

  const vouchers = allVouchers.filter(v => v.date >= fromISO && v.date <= toISO)

  return { vouchers, cashFlow, bankFlow, topItems, rawXml: responseText, indExpTotal, indIncTotal }
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

  return { items }
}


// Returns all ALLLEDGERENTRIES matches from a block, trying .LIST format first,
// then bare tag format — handles both Tally Prime and ERP 9 XML export styles.
function matchAllLedgerEntries(block) {
  const withList = [...block.matchAll(/<ALLLEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES\.LIST>/gi)]
  if (withList.length > 0) return withList
  return [...block.matchAll(/<ALLLEDGERENTRIES(?!\.LIST)[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES>/gi)]
}

function parseVouchers(xml, salesAccounts = [], salesIncludeVouchers = [], salesExcludeVouchers = [], cashInflowLedgers = [], fromISO = '', toISO = '', bankLedgers = [], purchaseAccounts = [], indirectExpenseLedgers = [], indirectIncomeLedgers = [], indirectExpenseVouchers = [], indirectIncomeVouchers = []) {
  const vouchers = []
  const cashFlow = { inflow: 0, outflow: 0 }
  const bankFlow = { inflow: 0, outflow: 0 }
  const itemMap  = new Map() // name → { qty, unit, amount }

  const salesAccountSet    = salesAccounts.length    ? new Set(salesAccounts.map(n => n.toLowerCase()))    : null
  const purchaseAccountSet = purchaseAccounts.length ? new Set(purchaseAccounts.map(n => n.toLowerCase())) : null
  // Cash inflow and outflow share the same ledger names — one configured list covers both
  const inflowSet  = cashInflowLedgers.length ? new Set(cashInflowLedgers.map(n => n.toLowerCase())) : null
  const outflowSet = inflowSet
  const bankSet    = bankLedgers.length       ? new Set(bankLedgers.map(n => n.toLowerCase()))       : null
  const indExpSet        = indirectExpenseLedgers.length  ? new Set(indirectExpenseLedgers.map(n => n.toLowerCase()))  : null
  const indIncSet        = indirectIncomeLedgers.length   ? new Set(indirectIncomeLedgers.map(n => n.toLowerCase()))   : null
  const indExpVoucherSet = indirectExpenseVouchers.length ? new Set(indirectExpenseVouchers.map(n => n.toLowerCase())) : null
  const indIncVoucherSet = indirectIncomeVouchers.length  ? new Set(indirectIncomeVouchers.map(n => n.toLowerCase()))  : null

  let indExpTotal = 0
  let indIncTotal = 0

  const blocks = [...xml.matchAll(/<VOUCHER\b[^>]*>([\s\S]*?)<\/VOUCHER>/gi)]
  const decode = (s) => (s || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&apos;/g, "'").trim()
  const GST_RE  = /cgst|sgst|igst|cess/i
  const CASH_RE = /cash/i
  const BANK_RE = /\bbank\b/i

  // Track each VOUCHER block's byte range and date — used in Step 2 to correctly
  // associate ALLLEDGERENTRIES that Tally places OUTSIDE <VOUCHER> blocks
  // (happens with multi-party "as per details" Receipt vouchers).
  const voucherRanges = [] // [{start, end, date}], sorted by position

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

    voucherRanges.push({ start: match.index, end: match.index + match[0].length, date })

    // Log raw XML for purchase vouchers to help reconcile discrepancies with Tally
    if (/purchase/i.test(type) && !/debit\s*note/i.test(type)) {
      console.log(`[PurchaseXML] date=${date} voucherNo="${voucherNo}" party="${party}"\n${block}`)
    }

    // Amount: find LEDGERENTRIES.LIST where ISPARTYLEDGER=Yes (Sales/Receipt vouchers)
    let amount = 0
    const ledgerListRe = /<LEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/LEDGERENTRIES\.LIST>/gi
    for (const le of block.matchAll(ledgerListRe)) {
      const leBlock = le[0]
      if (!/ISPARTYLEDGER[^>]*>Yes/i.test(leBlock)) continue
      const leAmtRaw = decode(leBlock.match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '')
      if (leAmtRaw) { amount = Math.abs(parseFloat(leAmtRaw.replace(/,/g, '')) || 0); break }
    }

    // Fallback: ALLLEDGERENTRIES where ISPARTYLEDGER=Yes (Payment/Journal vouchers)
    if (amount === 0) {
      for (const le of matchAllLedgerEntries(block)) {
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

    // Taxable amount: total (party) minus GST ledger entries (CGST/SGST/IGST/Cess)
    // Cash/bank flow is computed here for ALL vouchers — BEFORE the amount===0 guard —
    // because Contra/Journal/transfer entries often have no parseable party ledger amount
    // but still move real money through bank/cash ledgers.
    let gstTotal            = 0
    let hasSalesLedger      = false
    let salesLedger         = ''  // first matched sales account ledger name
    let salesLedgerTotal    = 0   // sum of all matched sales account ledger amounts
    let purchaseLedger      = ''  // first matched purchase account ledger name
    let purchaseLedgerTotal = 0   // sum of all matched purchase account ledger amounts

    // Collect ledger entries from ALLLEDGERENTRIES.LIST / ALLLEDGERENTRIES first,
    // then add LEDGERENTRIES.LIST entries only when the same ledger+amount doesn't
    // already appear in the ALL set. This prevents double-counting in Purchase
    // vouchers (where Tally duplicates bank entries across both tag types) while
    // still capturing bank entries that only exist in LEDGERENTRIES.LIST
    // (Receipt/Payment vouchers — the original bank flow miss we fixed).
    const allEntries = [
      ...block.matchAll(/<ALLLEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES\.LIST>/gi),
      ...block.matchAll(/<ALLLEDGERENTRIES(?!\.LIST)[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES>/gi),
    ]
    const simpleEntries = [
      ...block.matchAll(/<LEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/LEDGERENTRIES\.LIST>/gi),
    ]

    // Key = "ledgerName::rawAmount" — same ledger+amount in both tag types = duplicate
    const seenInAll = new Set(allEntries.map(m => {
      const n = decode(m[0].match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '').toLowerCase()
      const a = decode(m[0].match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '')
      return `${n}::${a}`
    }))

    const flowEntries = [
      ...allEntries,
      ...simpleEntries.filter(m => {
        const n = decode(m[0].match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '').toLowerCase()
        const a = decode(m[0].match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '')
        return !seenInAll.has(`${n}::${a}`)
      }),
    ]

    // DEBUG: log every ledger entry found, which tag it came from, and whether it looks like a bank entry
    const debugRows = flowEntries.map(m => {
      const tag  = m[0].startsWith('<ALLLEDGERENTRIES.LIST') ? 'ALL.LIST'
                 : m[0].startsWith('<ALLLEDGERENTRIES')      ? 'ALL'
                 :                                             'SIMPLE'
      const name = decode(m[0].match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '')
      const amt  = decode(m[0].match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '')
      const flag = BANK_RE.test(name) ? '🏦' : CASH_RE.test(name) ? '💵' : ''
      return `${tag}:${flag}"${name}"(${amt})`
    })
    console.log(`[BankDebug] date=${date} type="${type}" voucherNo="${voucherNo}" | entries: [${debugRows.join(' | ')}]`)

    // Check for bank entries that only exist in LEDGERENTRIES.LIST (previously missed)
    const bankInAll    = flowEntries.filter(m => !m[0].startsWith('<LEDGERENTRIES') && BANK_RE.test(decode(m[0].match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '')))
    const bankInSimple = flowEntries.filter(m =>  m[0].startsWith('<LEDGERENTRIES') && BANK_RE.test(decode(m[0].match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '')))
    if (bankInSimple.length > 0 && bankInAll.length === 0) {
      console.warn(`[BankDebug] ⚠️  Bank entry found ONLY in LEDGERENTRIES.LIST (was previously MISSED) | type="${type}" date=${date}`)
    }

    for (const le of flowEntries) {
      const leBlock    = le[0]
      const isParty    = /ISPARTYLEDGER[^>]*>Yes/i.test(leBlock)
      const ledgerName = decode(leBlock.match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '')
      const leAmtRaw   = decode(leBlock.match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '0')
      const leAmt      = parseFloat(leAmtRaw.replace(/,/g, '')) || 0

      const ledgerLower = ledgerName.toLowerCase()

      // Never count a configured purchase/sales account as GST even if its name
      // contains "igst"/"cgst" etc. (e.g. "Credit Note 18% IGST" is a purchase ledger).
      const isConfiguredAccount = (purchaseAccountSet && purchaseAccountSet.has(ledgerLower))
                                || (salesAccountSet   && salesAccountSet.has(ledgerLower))
      if (!isParty && !isConfiguredAccount && GST_RE.test(ledgerName)) {
        gstTotal += Math.abs(leAmt)
      }


      if (salesAccountSet && salesAccountSet.has(ledgerLower)) {
        hasSalesLedger = true
        if (!salesLedger) salesLedger = ledgerName
        salesLedgerTotal += Math.abs(leAmt)
      }
      if (purchaseAccountSet && purchaseAccountSet.has(ledgerLower)) {
        if (!purchaseLedger) purchaseLedger = ledgerName
        purchaseLedgerTotal += Math.abs(leAmt)
      }

      if (indExpSet && indExpSet.has(ledgerLower) && (!indExpVoucherSet || indExpVoucherSet.has(type.toLowerCase()))) indExpTotal += Math.abs(leAmt)
      if (indIncSet && indIncSet.has(ledgerLower) && (!indIncVoucherSet || indIncVoucherSet.has(type.toLowerCase()))) indIncTotal += Math.abs(leAmt)

      // Determine if this ledger counts as cash inflow/outflow or bank inflow/outflow
      const isInflowLedger  = inflowSet ? inflowSet.has(ledgerLower)  : CASH_RE.test(ledgerName)
      const isOutflowLedger = outflowSet ? outflowSet.has(ledgerLower) : CASH_RE.test(ledgerName)
      const isBankLedger    = bankSet   ? bankSet.has(ledgerLower)    : BANK_RE.test(ledgerName)

      // Only accumulate cash/bank flow for vouchers within the requested date range.
      // TBSVouchers may return entries outside the range — the JS date filter handles
      // the vouchers array, but cashFlow/bankFlow must also be date-gated here.
      const inRange = (!fromISO || date >= fromISO) && (!toISO || date <= toISO)

      // NOTE: do NOT skip isParty entries for cash/bank ledgers.
      // In Cash Sale and Contra vouchers, Cash/Bank is the party ledger.
      let classification = 'Other'
      if (inRange && (isInflowLedger || isOutflowLedger)) {
        classification = leAmt < 0 ? 'Cash Inflow' : 'Cash Outflow'
        const action = leAmt < 0 ? '→ CASH INFLOW  +' + Math.abs(leAmt) : '→ CASH OUTFLOW +' + leAmt
        console.log(`[CashBank] ${action} | date=${date} voucher="${type}" ledger="${ledgerName}" isParty=${isParty} rawAmt="${leAmtRaw}"`)
        if (leAmt < 0) cashFlow.inflow  += Math.abs(leAmt)
        else           cashFlow.outflow += leAmt
      } else if (inRange && isBankLedger) {
        classification = leAmt < 0 ? 'Bank Inflow' : 'Bank Outflow'
        const action = leAmt < 0 ? '→ BANK INFLOW  +' + Math.abs(leAmt) : '→ BANK OUTFLOW +' + leAmt
        console.log(`[CashBank] ${action} | date=${date} voucher="${type}" ledger="${ledgerName}" isParty=${isParty} rawAmt="${leAmtRaw}"`)
        if (leAmt < 0) bankFlow.inflow  += Math.abs(leAmt)
        else           bankFlow.outflow += leAmt
      } else if (!isParty && GST_RE.test(ledgerName)) {
        classification = 'GST'
      } else if (isParty) {
        classification = 'Party'
      }

    }

    // Skip pushing to vouchers array if no party amount found — these entries still
    // contributed to cashFlow/bankFlow above so they are not lost.
    if (amount === 0) {
      if (/purchase|debit\s*note/i.test(type)) {
        const ledgerSummary = flowEntries.map(m => {
          const n = decode(m[0].match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '?')
          const a = decode(m[0].match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '0')
          const p = /ISPARTYLEDGER[^>]*>Yes/i.test(m[0]) ? '[PARTY]' : ''
          return `${p}"${n}"=${a}`
        }).join(' | ')
        console.warn(`[PurchaseDebug] ⚠️ SKIPPED amount=0 | date=${date} type="${type}" voucherNo="${voucherNo}" party="${party}" | ledgers: ${ledgerSummary}`)
      }
      continue
    }

    // Use configured ledger amounts directly (no GST subtraction needed — avoids
    // round-off and other non-GST ledger contamination). Fall back to party-minus-GST
    // for vouchers where no configured account ledger was matched.
    const taxableAmount = salesLedgerTotal    > 0 ? salesLedgerTotal
                        : purchaseLedgerTotal > 0 ? purchaseLedgerTotal
                        : Math.max(0, amount - gstTotal)

    if (/purchase|debit\s*note/i.test(type)) {
      const gstLedgers = flowEntries
        .filter(m => {
          const n = decode(m[0].match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '')
          return !/ISPARTYLEDGER[^>]*>Yes/i.test(m[0]) && GST_RE.test(n)
        })
        .map(m => {
          const n = decode(m[0].match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '')
          const a = decode(m[0].match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '0')
          return `"${n}"=${a}`
        }).join(', ')
      console.log(`[PurchaseDebug] date=${date} type="${type}" voucherNo="${voucherNo}" party="${party}" | amount=${amount.toFixed(2)} gstTotal=${gstTotal.toFixed(2)} taxable=${taxableAmount.toFixed(2)}${gstLedgers ? ` | GST: [${gstLedgers}]` : ' | ⚠️ NO GST LEDGERS FOUND'}`)
    }

    vouchers.push({ date, type, party, amount, taxableAmount, voucherNo, hasSalesLedger, salesLedger: salesLedger || undefined, purchaseLedger: purchaseLedger || undefined })

    // ── Item aggregation for Top Performing Items ──────────────────────────
    // Only count inventory entries from sales vouchers within the date range.
    const voucherInRange = (!fromISO || date >= fromISO) && (!toISO || date <= toISO)
    if (voucherInRange) {
      const typeLower     = type.toLowerCase()
      const isExcluded    = salesExcludeVouchers.length
        ? salesExcludeVouchers.some(t => t.toLowerCase() === typeLower)
        : /credit\s*note/i.test(type)
      const isIncluded    = !isExcluded && (salesIncludeVouchers.length
        ? salesIncludeVouchers.some(t => t.toLowerCase() === typeLower)
        : /sales/i.test(type))
      const ledgerOk      = !salesAccountSet || hasSalesLedger

      if (isIncluded && ledgerOk) {
        for (const ie of block.matchAll(/<ALLINVENTORYENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLINVENTORYENTRIES\.LIST>/gi)) {
          const ieBlock  = ie[0]
          const itemName = decode(ieBlock.match(/<STOCKITEMNAME[^>]*>([^<]+)<\/STOCKITEMNAME>/i)?.[1] ?? '')
          if (!itemName) continue

          const qtyRaw = decode(
            ieBlock.match(/<BILLEDQTY[^>]*>([^<]+)<\/BILLEDQTY>/i)?.[1] ??
            ieBlock.match(/<ACTUALQTY[^>]*>([^<]+)<\/ACTUALQTY>/i)?.[1] ?? '0'
          )
          const qtyNum = parseFloat(qtyRaw.replace(/,/g, '')) || 0
          const unit   = qtyRaw.replace(/^[\d.,\s-]+/, '').trim()

          const amtRaw = decode(ieBlock.match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '0')
          const amt    = Math.abs(parseFloat(amtRaw.replace(/,/g, '')) || 0)

          if (!itemMap.has(itemName)) itemMap.set(itemName, { qty: 0, unit, amount: 0 })
          const entry = itemMap.get(itemName)
          entry.qty    += qtyNum
          entry.amount += amt
        }
      }
    }
  }

  // ── Step 2: ALLLEDGERENTRIES.LIST OUTSIDE VOUCHER blocks ────────────────
  // Tally places AllLedgerEntries outside the <VOUCHER> tag for multi-party
  // "as per details" vouchers (no single PARTYLEDGERNAME). The per-block scan
  // above misses these. We scan the full XML, skip entries that are inside a
  // VOUCHER block (already handled), and look up the date of the nearest
  // preceding VOUCHER block using a binary search over voucherRanges.
  let outsideCount = 0
  for (const m of xml.matchAll(/<ALLLEDGERENTRIES\.LIST[^>]*>([\s\S]*?)<\/ALLLEDGERENTRIES\.LIST>/gi)) {
    const pos = m.index

    // Binary search: is this entry inside any VOUCHER block?
    let lo = 0, hi = voucherRanges.length - 1, isInside = false
    while (lo <= hi) {
      const mid = Math.floor((lo + hi) / 2)
      const v = voucherRanges[mid]
      if (pos < v.start)     { hi = mid - 1 }
      else if (pos >= v.end) { lo = mid + 1 }
      else                   { isInside = true; break }
    }
    if (isInside) continue // already handled in Step 1

    // Find date from nearest preceding VOUCHER block (binary search)
    lo = 0; hi = voucherRanges.length - 1
    let date = ''
    while (lo <= hi) {
      const mid = Math.floor((lo + hi) / 2)
      if (voucherRanges[mid].end <= pos) { date = voucherRanges[mid].date; lo = mid + 1 }
      else                               { hi = mid - 1 }
    }
    if (!date) continue
    const inRange = (!fromISO || date >= fromISO) && (!toISO || date <= toISO)
    if (!inRange) continue

    const leBlock    = m[0]
    const ledgerName = decode(leBlock.match(/<LEDGERNAME[^>]*>([^<]+)<\/LEDGERNAME>/i)?.[1] ?? '')
    if (!ledgerName) continue
    const leAmtRaw   = decode(leBlock.match(/<AMOUNT[^>]*>([^<]+)<\/AMOUNT>/i)?.[1] ?? '0')
    const leAmt      = parseFloat(leAmtRaw.replace(/,/g, '')) || 0
    const isParty    = /ISPARTYLEDGER[^>]*>Yes/i.test(leBlock)

    const ledgerLower     = ledgerName.toLowerCase()
    const isInflowLedger  = inflowSet ? inflowSet.has(ledgerLower)  : CASH_RE.test(ledgerName)
    const isOutflowLedger = outflowSet ? outflowSet.has(ledgerLower) : CASH_RE.test(ledgerName)
    const isBankLedger    = bankSet   ? bankSet.has(ledgerLower)    : BANK_RE.test(ledgerName)

    if (isInflowLedger || isOutflowLedger) {
      const action = leAmt < 0 ? '→ CASH INFLOW  +' + Math.abs(leAmt) : '→ CASH OUTFLOW +' + leAmt
      console.log(`[CashBank/outside] ${action} | date=${date} ledger="${ledgerName}" isParty=${isParty}`)
      if (leAmt < 0) cashFlow.inflow  += Math.abs(leAmt)
      else           cashFlow.outflow += leAmt
      outsideCount++
    } else if (isBankLedger) {
      const action = leAmt < 0 ? '→ BANK INFLOW  +' + Math.abs(leAmt) : '→ BANK OUTFLOW +' + leAmt
      console.log(`[CashBank/outside] ${action} | date=${date} ledger="${ledgerName}" isParty=${isParty}`)
      if (leAmt < 0) bankFlow.inflow  += Math.abs(leAmt)
      else           bankFlow.outflow += leAmt
      outsideCount++
    }
  }

  const topItems = [...itemMap.entries()]
    .map(([name, { qty, unit, amount }]) => ({ name, qty, unit, amount }))
    .sort((a, b) => b.amount - a.amount)
    .slice(0, 10)

  return { vouchers, cashFlow, bankFlow, topItems, indExpTotal, indIncTotal }
}

// ── Sync voucher XML to Tally ────────────────────────────────────────────────

async function handleSyncToTally(xml, tallyUrl) {
  const responseText = await postToTally(xml, tallyUrl)
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
  const responseText = await postToTally(xml, tallyUrl)
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

  const responseText = await postToTally(xml, tallyUrl)
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
  const responseText = await postToTally(xml, tallyUrl)
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
  const responseText = await postToTally(xml, tallyUrl)
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

// ── Sundry Debtors / Creditors group-level closing balance ──────────────────
// Uses TBSGroupBalances (defined in TallySyncBridge.tdl) which filters to the
// two top-level groups. Tally aggregates all child ledgers into a single record,
// so this is just 2 rows — much faster than querying individual ledger balances.
// Same SVTODATE limitation as TBSCashBankBalances: always returns current date's value.

async function fetchStockSummaryTotal(tallyUrl, tallyCompany, asOfDate, fromDate = null) {
  const fromLine = fromDate ? `\n          <SVFROMDATE>${fromDate}</SVFROMDATE>` : ''
  const xml = `<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Export Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <EXPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Stock Summary</REPORTNAME>
        <STATICVARIABLES>
          <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>${fromLine}
          <SVTODATE>${asOfDate}</SVTODATE>${companyVar(tallyCompany)}
        </STATICVARIABLES>
      </REQUESTDESC>
    </EXPORTDATA>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)

  // DSPCLAMTA = Display Closing Amount. Values use Tally's Cr/Dr sign:
  // negative = positive stock (asset/Cr), positive = deficit stock (Dr).
  // Negating and summing all entries gives the correct total stock value.
  // No double-counting: top-level stock groups aggregate their child items;
  // individual items shown separately are those not in any named group.
  const matches = [...responseText.matchAll(/<DSPCLAMTA[^>]*>([\s\S]*?)<\/DSPCLAMTA>/gi)]
  let total = 0
  for (const m of matches) {
    const raw = m[1].trim()
    if (!raw) continue
    total += -(parseFloat(raw.replace(/,/g, '')) || 0)
  }
  console.log(`[StockSummary] ${fromDate ? `fromDate=${fromDate} ` : ''}asOfDate=${asOfDate} | entries=${matches.length} | total=${total}`)
  return total
}

async function handleFetchStockValue(tallyUrl, tallyCompany, fromDate, toDate) {
  // Opening stock = closing stock at end of the day BEFORE fromDate (i.e. 31-Mar for YTD).
  // Using fromDate itself would include that day's transactions and give the wrong value.
  const d = new Date(`${fromDate.slice(0,4)}-${fromDate.slice(4,6)}-${fromDate.slice(6,8)}`)
  d.setDate(d.getDate() - 1)
  const openingDate = `${d.getFullYear()}${String(d.getMonth()+1).padStart(2,'0')}${String(d.getDate()).padStart(2,'0')}`

  const openingDisplayDate = toTallyDisplayDate(openingDate)
  const [closingStock, openingStock] = await Promise.all([
    fetchStockSummaryTotal(tallyUrl, tallyCompany, toTallyDisplayDate(toDate)),
    fetchStockSummaryTotal(tallyUrl, tallyCompany, openingDisplayDate, openingDisplayDate),
  ])

  console.log(`[StockValue] Opening (${openingDate}): ${openingStock} | Closing (${toDate}): ${closingStock}`)
  return { openingStock, closingStock }
}

async function handleFetchLedgerAmounts(tallyUrl, tallyCompany, fromDate, toDate, ledgerNames = []) {
  if (ledgerNames.length === 0) return { total: 0 }

  const from   = toTallyDisplayDate(fromDate)
  const to     = toTallyDisplayDate(toDate)
  const filter = ledgerNames.map(n => `$Name = "${n}"`).join(' OR ')

  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSLedgerAmounts</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
        <SVFROMDATE>${from}</SVFROMDATE>
        <SVTODATE>${to}</SVTODATE>${companyVar(tallyCompany)}
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="TBSLedgerAmounts" ISMODIFY="No">
            <TYPE>Ledger</TYPE>
            <NATIVEMETHOD>Name, ClosingBalance</NATIVEMETHOD>
            <FILTER>IsTargetLedger</FILTER>
          </COLLECTION>
          <SYSTEM TYPE="Formulae" NAME="IsTargetLedger">
            ${filter}
          </SYSTEM>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  const responseText = await postToTally(xml, tallyUrl)
  const blocks = [...responseText.matchAll(/<LEDGER\b[^>]*>([\s\S]*?)<\/LEDGER>/gi)]

  let total = 0
  for (const match of blocks) {
    const inner  = match[1]
    const balRaw = inner.match(/<CLOSINGBALANCE[^>]*>([\s\S]*?)<\/CLOSINGBALANCE>/i)?.[1] ?? '0'
    total += Math.abs(parseTallyBalance(balRaw.trim()))
  }

  return { total }
}


async function handleFetchGroupBalances(tallyUrl, tallyCompany, asOfDate) {
  const today = new Date()
  const pad   = (n) => String(n).padStart(2, '0')
  const fyYear  = today.getMonth() >= 3 ? today.getFullYear() : today.getFullYear() - 1
  const fyStart = `${fyYear}0401`
  const toDateRaw = asOfDate || `${today.getFullYear()}${pad(today.getMonth() + 1)}${pad(today.getDate())}`

  const xml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>TBSGroupBalances</ID>
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
  const groups = parseGroupBalances(responseText)
  const debtors   = groups.find(g => g.name.toLowerCase().includes('sundry debtor'))
  const creditors = groups.find(g => g.name.toLowerCase().includes('sundry creditor'))

  // Sundry Debtors closing balance is Dr (positive) — what customers owe you
  // Sundry Creditors closing balance is Cr (negative) — what you owe vendors
  const receivables = debtors   ? Math.abs(debtors.balance)   : 0
  const payables    = creditors ? Math.abs(creditors.balance)  : 0

  return { receivables, payables }
}

function parseGroupBalances(xml) {
  const results = []
  const blocks  = [...xml.matchAll(/<GROUP\b[^>]*>([\s\S]*?)<\/GROUP>/gi)]
  for (const [, inner] of blocks) {
    const nameM = inner.match(/<NAME[^>]*>\s*([\s\S]*?)\s*<\/NAME>/i)
    const balM  = inner.match(/<CLOSINGBALANCE[^>]*>\s*([\s\S]*?)\s*<\/CLOSINGBALANCE>/i)
    if (!nameM) continue
    const name    = nameM[1].trim()
    const balance = balM ? parseTallyBalance(balM[1].trim()) : 0
    if (name) results.push({ name, balance })
  }
  return results
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
  const rawLedgers = parseLedgerBalances(responseText)
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
