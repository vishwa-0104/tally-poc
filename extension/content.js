/**
 * Content script — bridges window.postMessage (web app) → background service worker.
 *
 * Web page → content script → background (does the actual Tally fetch)
 *
 * Why this split:
 * - Web page can't call chrome.runtime directly (service worker sleep issue)
 * - Content script → background always wakes the service worker reliably
 * - Only background can make cross-origin fetch to http://localhost:9000 (no CORS)
 */

const VERSION = chrome.runtime.getManifest().version

window.addEventListener('message', (event) => {
  if (event.source !== window) return
  if (!event.data || !event.data.__tallyMsg) return

  const { __msgId, __tallyMsg: _flag, ...message } = event.data

  // PING is handled directly — no Tally network call needed
  if (message.type === 'PING') {
    window.postMessage({ __tallyReply: true, __msgId, version: VERSION }, '*')
    return
  }

  // All other messages forwarded to background (which has cross-origin fetch access)
  try {
    chrome.runtime.sendMessage(message, (response) => {
      const err = chrome.runtime.lastError
      if (err) {
        console.error('[TallySync] Background error:', err.message)
      }
      window.postMessage({
        __tallyReply: true,
        __msgId,
        ...(err ? { error: err.message } : response),
      }, '*')
    })
  } catch (e) {
    // Extension was reloaded — context is gone; notify the page so it doesn't hang
    window.postMessage({ __tallyReply: true, __msgId, error: 'Extension reloaded. Please refresh the page.' }, '*')
  }
})
