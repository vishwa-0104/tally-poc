const { app, BrowserWindow, ipcMain } = require('electron')
const path = require('path')

// Loads .env.electron (ELECTRON_API_BASE_URL, TALLY_HOOK_PORT) before any
// module that reads those at require-time (hook-server.cjs) is loaded. In a
// packaged app there's no shell environment to inherit these from — this is
// the only place they come from. Missing file is fine in dev (electron:dev
// doesn't need it — nothing but the local Tally bridge is exercised then).
require('dotenv').config({ path: path.join(__dirname, '..', '.env.electron') })

const { handlers } = require('./tally-bridge.cjs')
const hookServer = require('./hook-server.cjs')

const isDev = process.env.NODE_ENV === 'development'

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 900,
    icon: path.join(__dirname, '..', 'build', 'icon.png'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  })

  if (isDev) {
    win.loadURL('http://localhost:3000')
    win.webContents.openDevTools()
  } else {
    win.loadFile(path.join(__dirname, '..', 'dist', 'index.html'))
  }

  // Catches Tally's own voucher-save webhook directly (see hook-server.cjs
  // for why this only works from a process running on the same machine as
  // Tally — the web+extension deployment has no equivalent).
  hookServer.start(win)
}

// Dispatches every non-PING message the preload relays (PING is answered
// directly in preload.cjs — see comment there) to tally-bridge.cjs's handler
// map, keyed by the same `type` string the extension's background.js used.
ipcMain.handle('tally-message', async (_event, message) => {
  const { type, ...payload } = message ?? {}
  const handler = handlers[type]
  if (!handler) return { error: `Unknown message type: ${type}` }
  return handler(payload)
})

app.whenReady().then(createWindow)

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow()
})
