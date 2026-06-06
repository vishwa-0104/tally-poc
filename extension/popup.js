document.getElementById('version').textContent = chrome.runtime.getManifest().version

const btn        = document.getElementById('test-btn')
const msg        = document.getElementById('status-msg')
const portInput  = document.getElementById('port-input')
const agentBadge = document.getElementById('agent-badge')

// ── Agent health check (runs on popup open) ──────────────────────────────────

async function checkAgent() {
  try {
    const res = await fetch('http://localhost:9001/health', { signal: AbortSignal.timeout(3000) })
    const json = await res.json()
    if (json.ok) {
      agentBadge.className = 'badge ok'
      agentBadge.innerHTML = '<span class="dot green"></span>Running'
    } else {
      throw new Error('not ok')
    }
  } catch {
    agentBadge.className = 'badge err'
    agentBadge.innerHTML = '<span class="dot red"></span>Not running'
  }
}

checkAgent()

// ── Tally connection test ────────────────────────────────────────────────────

btn.addEventListener('click', async () => {
  const port = parseInt(portInput.value, 10) || 9000
  btn.disabled = true
  btn.textContent = 'Connecting…'
  msg.className = ''
  msg.style.display = 'none'

  const testXml = `<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Export</TALLYREQUEST>
    <TYPE>Collection</TYPE>
    <ID>List of Companies</ID>
  </HEADER>
  <BODY>
    <DESC>
      <STATICVARIABLES>
        <SVEXPORTFORMAT>$$SysName:XML</SVEXPORTFORMAT>
      </STATICVARIABLES>
      <TDL>
        <TDLMESSAGE>
          <COLLECTION NAME="List of Companies" ISMODIFY="No">
            <TYPE>Company</TYPE>
            <NATIVEMETHOD>Name</NATIVEMETHOD>
          </COLLECTION>
        </TDLMESSAGE>
      </TDL>
    </DESC>
  </BODY>
</ENVELOPE>`

  try {
    const response = await fetch(`http://localhost:${port}`, {
      method: 'POST',
      headers: { 'Content-Type': 'text/xml;charset=UTF-8' },
      body: testXml,
    })

    if (response.ok) {
      msg.className = 'ok'
      msg.textContent = `Connected to Tally on port ${port}`
    } else {
      msg.className = 'err'
      msg.textContent = `Tally responded with HTTP ${response.status}`
    }
  } catch {
    msg.className = 'err'
    msg.textContent = `Could not reach Tally on port ${port}. Is Tally running?`
  }

  btn.disabled = false
  btn.textContent = 'Test Tally Connection'
})
