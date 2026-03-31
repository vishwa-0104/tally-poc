document.getElementById('version').textContent =
  chrome.runtime.getManifest().version

const btn = document.getElementById('test-btn')
const msg = document.getElementById('status-msg')
const portInput = document.getElementById('port-input')

btn.addEventListener('click', async () => {
  alert(">>>>>>>")
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

  // try {
    const response = await fetch(`https://baz.ngrok.dev`, {
      method: 'POST',
      headers: { 'Content-Type': 'text/xml;charset=UTF-8' },
      body: testXml,
    })

    alert(">>> sendinding connectionnnn ", response)

    if (response.ok) {
      msg.className = 'ok'
      msg.textContent = `Connected to Tally on port ${port}`
    } else {
      msg.className = 'err'
      msg.textContent = `Tally responded with HTTP ${response.status}`
      console.log(">>>>>>>>>>>>>> ", response.status)
    }
  } 
  // catch {
  //   msg.className = 'err'
  //   msg.textContent = `Could not reach Tally on port ${port}. Is Tally running?`
  // }

  // btn.disabled = false
  // btn.textContent = 'Test Tally Connection'
)
