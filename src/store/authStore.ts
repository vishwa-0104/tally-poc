import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { User, Company } from '@/types'
import { getInitials } from '@/lib/utils'
import { api } from '@/lib/api'

interface AuthStore {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  companies: Company[]
  activeCompanyId: string | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  switchCompany: (companyId: string) => Promise<void>
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      companies: [],
      activeCompanyId: null,

      login: async (email, password) => {
        const { data } = await api.post<{ token: string; user: User; companies: Company[]; defaultCompanyId: string | null }>('/auth/login', { email, password })
        const defaultId = data.defaultCompanyId ?? data.companies?.[0]?.id ?? null
        set({
          user: { ...data.user, avatar: getInitials(data.user.name) },
          token: data.token,
          isAuthenticated: true,
          companies: data.companies ?? [],
          activeCompanyId: defaultId,
        })
      },

      logout: () => {
        set({ user: null, token: null, isAuthenticated: false, companies: [], activeCompanyId: null })
      },

      switchCompany: async (companyId: string) => {
        await api.patch('/users/default-company', { companyId }).catch(() => {})
        set({ activeCompanyId: companyId })
        window.location.reload()
      },
    }),
    {
      name: 'tally-auth',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
        companies: state.companies,
        activeCompanyId: state.activeCompanyId,
      }),
    },
  ),
)
