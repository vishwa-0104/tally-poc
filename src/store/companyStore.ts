import { create } from 'zustand'
import type { Company, LedgerMapping, TallyLedger, TallyStockItem } from '@/types'
import { api } from '@/lib/api'

interface CompanyStore {
  companies: Company[]
  loading: boolean
  ledgers: Record<string, TallyLedger[]>
  stockItems: Record<string, TallyStockItem[]>
  fetchCompanies: () => Promise<void>
  addCompany: (data: Omit<Company, 'id' | 'totalBills' | 'syncedBills' | 'pendingBills' | 'errorBills' | 'createdAt'> & { password: string }) => Promise<Company>
  updateMapping: (companyId: string, mapping: LedgerMapping) => Promise<void>
  getCompany: (id: string) => Company | undefined
  setLedgers: (companyId: string, ledgers: TallyLedger[]) => void
  getLedgers: (companyId: string) => TallyLedger[]
  fetchLedgersFromDb: (companyId: string) => Promise<void>
  saveLedgersToDb: (companyId: string, ledgers: TallyLedger[]) => Promise<void>
  setStockItems: (companyId: string, items: TallyStockItem[]) => void
  getStockItems: (companyId: string) => TallyStockItem[]
  incrementBillCount: (companyId: string) => void
  incrementPending: (companyId: string) => void
  incrementSynced: (companyId: string) => void
  incrementError: (companyId: string) => void
  decrementPending: (companyId: string) => void
  decrementError: (companyId: string) => void
}

export const useCompanyStore = create<CompanyStore>((set, get) => ({
  companies: [],
  loading: false,
  ledgers: {},
  stockItems: {},

  fetchCompanies: async () => {
    set({ loading: true })
    try {
      const { data } = await api.get<Company[]>('/companies')
      set({ companies: data })
    } finally {
      set({ loading: false })
    }
  },

  addCompany: async (payload) => {
    const { data } = await api.post<Company>('/companies', payload)
    set((s) => ({ companies: [...s.companies, data] }))
    return data
  },

  updateMapping: async (companyId, mapping) => {
    const { data } = await api.put<Company>(`/companies/${companyId}/mapping`, mapping)
    set((s) => ({
      companies: s.companies.map((c) => (c.id === companyId ? { ...c, mapping: data.mapping } : c)),
    }))
  },

  getCompany: (id) => {
    console.log(">>>>>> userwww ", id, get().companies)
    return get().companies.find((c) => c.id === id)},

  setLedgers: (companyId, ledgers) =>
    set((s) => ({ ledgers: { ...s.ledgers, [companyId]: ledgers } })),

  getLedgers: (companyId) => get().ledgers[companyId] ?? [],

  setStockItems: (companyId, items) =>
    set((s) => ({ stockItems: { ...s.stockItems, [companyId]: items } })),

  getStockItems: (companyId) => get().stockItems[companyId] ?? [],

  fetchLedgersFromDb: async (companyId) => {
    console.log('[Step 5] Loading ledgers from DB for company:', companyId)
    const { data } = await api.get<TallyLedger[]>(`/companies/${companyId}/ledgers`)
    console.log('[Step 6] Ledgers loaded from DB. Count:', data.length, data.length === 0 ? '⚠ DB is empty — go to Settings and click Sync Ledgers' : '')
    set((s) => ({ ledgers: { ...s.ledgers, [companyId]: data } }))
  },

  saveLedgersToDb: async (companyId, ledgers) => {
    console.log('[Step 3] Sending ledgers to backend API. companyId:', companyId, '| Count:', ledgers.length)
    const { data } = await api.put<{ saved: number }>(`/companies/${companyId}/ledgers`, ledgers)
    console.log('[Step 4] Backend response:', data)
    set((s) => ({ ledgers: { ...s.ledgers, [companyId]: ledgers } }))
  },

  // Local-only counter helpers (optimistic, synced counts come from fetchCompanies)
  incrementBillCount: (companyId) =>
    set((s) => ({ companies: s.companies.map((c) => c.id === companyId ? { ...c, totalBills: c.totalBills + 1, pendingBills: c.pendingBills + 1 } : c) })),

  incrementPending: (companyId) =>
    set((s) => ({ companies: s.companies.map((c) => c.id === companyId ? { ...c, pendingBills: c.pendingBills + 1 } : c) })),

  incrementSynced: (companyId) =>
    set((s) => ({ companies: s.companies.map((c) => c.id === companyId ? { ...c, syncedBills: c.syncedBills + 1 } : c) })),

  incrementError: (companyId) =>
    set((s) => ({ companies: s.companies.map((c) => c.id === companyId ? { ...c, errorBills: c.errorBills + 1 } : c) })),

  decrementPending: (companyId) =>
    set((s) => ({ companies: s.companies.map((c) => c.id === companyId ? { ...c, pendingBills: Math.max(0, c.pendingBills - 1) } : c) })),

  decrementError: (companyId) =>
    set((s) => ({ companies: s.companies.map((c) => c.id === companyId ? { ...c, errorBills: Math.max(0, c.errorBills - 1) } : c) })),
}))
