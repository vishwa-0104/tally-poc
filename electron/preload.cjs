/**
 * Preload — bridges window.postMessage (web app) → main process (Electron
 * equivalent of extension/content.js). Deliberately mirrors that file's exact
 * postMessage contract so the React app (src/services/tallyService.ts,
 * src/hooks/useExtension.ts, etc.) needs zero changes to work under Electron:
 *
 * Web page → preload → main process (does the actual Tally fetch, no CORS
 * restriction at all in a Node process — unlike content.js, this isn't
 * working around a same-origin limitation, just relaying).
 *
 * contextIsolation is on, but postMessage crosses that boundary by design —
 * no contextBridge API surface needed since nothing is exposed to page JS.
 */

const { ipcRenderer } = require('electron')

const VERSION = require('../package.json').version

window.addEventListener('message', (event) => {
  if (event.source !== window) return
  if (!event.data || !event.data.__tallyMsg) return

  const { __msgId, __tallyMsg: _flag, ...message } = event.data

  // PING is handled directly — no Tally network call needed, matches content.js
  if (message.type === 'PING') {
    window.postMessage({ __tallyReply: true, __msgId, version: VERSION }, '*')
    return
  }

  ipcRenderer
    .invoke('tally-message', message)
    .then((response) => {
      window.postMessage({ __tallyReply: true, __msgId, ...response }, '*')
    })
    .catch((err) => {
      window.postMessage({ __tallyReply: true, __msgId, error: err?.message ?? String(err) }, '*')
    })
})
