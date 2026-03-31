import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 3500,
          style: {
            fontFamily: 'Plus Jakarta Sans, sans-serif',
            fontSize: '13px',
            fontWeight: 500,
          },
          success: { style: { background: '#065F46', color: 'white' } },
          error: { style: { background: '#991B1B', color: 'white' } },
        }}
      />
    </BrowserRouter>
  </React.StrictMode>,
)
