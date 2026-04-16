import axios from 'axios'

export const api = axios.create({ baseURL: '/api' })

export async function getNextVoucherCounter(companyId: string): Promise<number> {
  const { data } = await api.post<{ counter: number }>(`/companies/${companyId}/voucher-counter/next`)
  return data.counter
}

// Attach JWT from localStorage on every request
api.interceptors.request.use((config) => {
  const raw = localStorage.getItem('tally-auth')
  if (raw) {
    try {
      const { state } = JSON.parse(raw)
      if (state?.token) config.headers.Authorization = `Bearer ${state.token}`
    } catch { /* ignore */ }
  }
  return config
})

// On 401, clear auth and redirect to login
api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('tally-auth')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  },
)
