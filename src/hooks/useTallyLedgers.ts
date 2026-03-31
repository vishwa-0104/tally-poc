import { useState, useEffect } from 'react'
import type { TallyLedger } from '@/types'
import { fetchTallyLedgers } from '@/services'

export function useTallyLedgers(tallyUrl: string, enabled = true) {
  const [ledgers, setLedgers] = useState<TallyLedger[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError]     = useState<string | null>(null)

  useEffect(() => {
    if (!enabled) return
    setLoading(true)
    setError(null)
    fetchTallyLedgers(tallyUrl)
      .then(setLedgers)
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false))
  }, [tallyUrl, enabled])

  return { ledgers, loading, error }
}
