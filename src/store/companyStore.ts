import { create } from 'zustand'
import type { Company, LedgerMapping, TallyLedger, TallyStockItem, TallyStockGroup, StockItemAlias } from '@/types'
import { api } from '@/lib/api'

interface CompanyStore {
  companies: Company[]
  loading: boolean
  ledgers: Record<string, TallyLedger[]>
  stockItems: Record<string, TallyStockItem[]>
  stockGroups: Record<string, TallyStockGroup[]>
  stockItemAliases: Record<string, StockItemAlias[]>
  fetchCompanies: () => Promise<void>
  addCompany: (data: Omit<Company, 'id' | 'totalBills' | 'syncedBills' | 'pendingBills' | 'errorBills' | 'voucherCounter' | 'createdAt'> & { password: string }) => Promise<Company>
  updateMapping: (companyId: string, mapping: LedgerMapping) => Promise<void>
  getCompany: (id: string) => Company | undefined
  setLedgers: (companyId: string, ledgers: TallyLedger[]) => void
  getLedgers: (companyId: string) => TallyLedger[]
  fetchLedgersFromDb: (companyId: string) => Promise<void>
  saveLedgersToDb: (companyId: string, ledgers: TallyLedger[]) => Promise<void>
  setStockItems: (companyId: string, items: TallyStockItem[]) => void
  getStockItems: (companyId: string) => TallyStockItem[]
  fetchStockItemsFromDb: (companyId: string) => Promise<void>
  saveStockItemsToDb: (companyId: string, items: TallyStockItem[]) => Promise<void>
  getStockGroups: (companyId: string) => TallyStockGroup[]
  fetchStockGroupsFromDb: (companyId: string) => Promise<void>
  saveStockGroupsToDb: (companyId: string, groups: TallyStockGroup[]) => Promise<void>
  fetchAliases: (companyId: string) => Promise<void>
  saveAliases: (companyId: string, aliases: StockItemAlias[]) => Promise<void>
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
  stockGroups: {},
  stockItemAliases: {},

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

  getCompany: (id) => get().companies.find((c) => c.id === id),

  setLedgers: (companyId, ledgers) =>
    set((s) => ({ ledgers: { ...s.ledgers, [companyId]: ledgers } })),

  getLedgers: (companyId) => get().ledgers[companyId] ?? [],

  setStockItems: (companyId, items) =>
    set((s) => ({ stockItems: { ...s.stockItems, [companyId]: items } })),

  getStockItems: (companyId) => get().stockItems[companyId] ?? [],

  fetchStockItemsFromDb: async (companyId) => {
    const { data } = await api.get<TallyStockItem[]>(`/companies/${companyId}/stock-items`)
    set((s) => ({ stockItems: { ...s.stockItems, [companyId]: data } }))
  },

  saveStockItemsToDb: async (companyId, items) => {
    await api.put<{ saved: number }>(`/companies/${companyId}/stock-items`, items)
    set((s) => ({ stockItems: { ...s.stockItems, [companyId]: items } }))
  },

  getStockGroups: (companyId) => get().stockGroups[companyId] ?? [],

  fetchStockGroupsFromDb: async (companyId) => {
    const { data } = await api.get<TallyStockGroup[]>(`/companies/${companyId}/stock-groups`)
    set((s) => ({ stockGroups: { ...s.stockGroups, [companyId]: data } }))
  },

  saveStockGroupsToDb: async (companyId, groups) => {
    await api.put<{ saved: number }>(`/companies/${companyId}/stock-groups`, groups)
    set((s) => ({ stockGroups: { ...s.stockGroups, [companyId]: groups } }))
  },

  fetchAliases: async (companyId) => {
    const { data } = await api.get<StockItemAlias[]>(`/companies/${companyId}/stock-item-aliases`)
    set((s) => ({ stockItemAliases: { ...s.stockItemAliases, [companyId]: data } }))
  },

  saveAliases: async (companyId, aliases) => {
    if (aliases.length === 0) return
    await api.post<{ saved: number }>(`/companies/${companyId}/stock-item-aliases`, aliases)
    set((s) => {
      const existing = s.stockItemAliases[companyId] ?? []
      const merged = [...existing]
      for (const a of aliases) {
        const idx = merged.findIndex((e) => e.billItemName === a.billItemName.toLowerCase())
        const entry = { billItemName: a.billItemName.toLowerCase(), tallyStockItemName: a.tallyStockItemName }
        if (idx >= 0) merged[idx] = entry
        else merged.push(entry)
      }
      return { stockItemAliases: { ...s.stockItemAliases, [companyId]: merged } }
    })
  },

  fetchLedgersFromDb: async (companyId) => {
    const { data } = await api.get<TallyLedger[]>(`/companies/${companyId}/ledgers`)
    set((s) => ({ ledgers: { ...s.ledgers, [companyId]: data } }))
  },

  saveLedgersToDb: async (companyId, ledgers) => {
    await api.put<{ saved: number }>(`/companies/${companyId}/ledgers`, ledgers)
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
