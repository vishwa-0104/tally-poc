import axios from 'axios'
import type { DashboardSettings } from '@/types'

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

export async function fetchSalesTargets(
  companyId: string,
  fyYear: number,
): Promise<{ month: number; target: number }[]> {
  const { data } = await api.get(`/companies/${companyId}/targets`, { params: { fyYear } })
  return data
}

export async function saveSalesTargets(
  companyId: string,
  fyYear: number,
  targets: { month: number; target: number }[],
): Promise<void> {
  await api.put(`/companies/${companyId}/targets`, { fyYear, targets })
}

export async function fetchDashboardSettings(companyId: string): Promise<DashboardSettings> {
  const { data } = await api.get(`/companies/${companyId}/dashboard-settings`)
  return data
}

export async function saveDashboardSettings(companyId: string, settings: DashboardSettings): Promise<void> {
  await api.put(`/companies/${companyId}/dashboard-settings`, settings)
}

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
