import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { User } from '@/types'
import { getInitials } from '@/lib/utils'
import { api } from '@/lib/api'

interface AuthStore {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      login: async (email, password) => {
        const { data } = await api.post<{ token: string; user: User }>('/auth/login', { email, password })
        set({
          user: { ...data.user, avatar: getInitials(data.user.name) },
          token: data.token,
          isAuthenticated: true,
        })
      },

      logout: () => {
        set({ user: null, token: null, isAuthenticated: false })
      },
    }),
    {
      name: 'tally-auth',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    },
  ),
)
