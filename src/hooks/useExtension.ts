import { useState, useEffect } from 'react'

export function useExtensionStatus() {
  const [connected, setConnected] = useState(false)
  const [version, setVersion]     = useState<string | null>(null)

  useEffect(() => {
    const msgId = Math.random().toString(36).slice(2)

    const timer = setTimeout(() => {
      window.removeEventListener('message', handler)
    }, 2000)

    function handler(event: MessageEvent) {
      if (!event.data?.__tallyReply || event.data.__msgId !== msgId) return
      clearTimeout(timer)
      window.removeEventListener('message', handler)
      if (!event.data.error) {
        setConnected(true)
        setVersion((event.data as { version?: string }).version ?? null)
      }
    }

    window.addEventListener('message', handler)
    window.postMessage({ __tallyMsg: true, __msgId: msgId, type: 'PING' }, '*')

    return () => {
      clearTimeout(timer)
      window.removeEventListener('message', handler)
    }
  }, [])

  return { connected, version }
}
