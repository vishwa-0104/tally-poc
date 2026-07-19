import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

// Electron loads the built bundle from a file:// URL, where Vite's default
// absolute asset paths (/assets/...) don't resolve — relative paths do.
// The web build (served same-origin behind Nginx) needs the default '/'.
const isElectronBuild = process.env.ELECTRON_BUILD === 'true'

export default defineConfig({
  base: isElectronBuild ? './' : '/',
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    open: true,
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
        ws: true,
      },
    },
  },
})
