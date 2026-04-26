import { create } from 'zustand'
import type { Company, CompanyFeature, LedgerMapping, TallyGodown, TallyLedger, TallyStockItem, TallyStockGroup, TallyStockUnit, StockItemAlias } from '@/types'
import { api } from '@/lib/api'

interface CompanyStore {
  companies: Company[]
  loading: boolean
  ledgers: Record<string, TallyLedger[]>
  stockItems: Record<string, TallyStockItem[]>
  stockGroups: Record<string, TallyStockGroup[]>
  stockUnits: Record<string, TallyStockUnit[]>
  stockItemAliases: Record<string, StockItemAlias[]>
  godowns: Record<string, TallyGodown[]>
  fetchCompanies: () => Promise<void>
  addCompany: (data: { name: string; gstin?: string; email?: string; port: number; userId?: string }) => Promise<Company>
  updateCompany: (companyId: string, data: { name?: string; gstin?: string | null; port?: number }) => Promise<void>
  updateMapping: (companyId: string, mapping: LedgerMapping) => Promise<void>
  updateCompanyFeature: (companyId: string, feature: string, enabled: boolean) => Promise<void>
  getCompany: (id: string) => Company | undefined
  setLedgers: (companyId: string, ledgers: TallyLedger[]) => void
  getLedgers: (companyId: string) => TallyLedger[]
  fetchLedgersFromDb: (companyId: string) => Promise<void>
  saveLedgersToDb: (companyId: string, ledgers: TallyLedger[]) => Promise<void>
  setStockItems: (companyId: string, items: TallyStockItem[]) => void
  getStockItems: (companyId: string) => TallyStockItem[]
  addStockItem: (companyId: string, item: TallyStockItem) => void
  fetchStockItemsFromDb: (companyId: string) => Promise<void>
  saveStockItemsToDb: (companyId: string, items: TallyStockItem[]) => Promise<void>
  getStockGroups: (companyId: string) => TallyStockGroup[]
  fetchStockGroupsFromDb: (companyId: string) => Promise<void>
  saveStockGroupsToDb: (companyId: string, groups: TallyStockGroup[]) => Promise<void>
  getStockUnits: (companyId: string) => TallyStockUnit[]
  fetchStockUnitsFromDb: (companyId: string) => Promise<void>
  saveStockUnitsToDb: (companyId: string, units: TallyStockUnit[]) => Promise<void>
  fetchAliases: (companyId: string) => Promise<void>
  saveAliases: (companyId: string, aliases: StockItemAlias[]) => Promise<void>
  getGodowns: (companyId: string) => TallyGodown[]
  fetchGodownsFromDb: (companyId: string) => Promise<void>
  saveGodownsToDb: (companyId: string, godowns: TallyGodown[]) => Promise<void>
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
  stockUnits: {},
  stockItemAliases: {},
  godowns: {},

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

  updateCompany: async (companyId, payload) => {
    const { data } = await api.patch<Company>(`/companies/${companyId}`, payload)
    set((s) => ({
      companies: s.companies.map((c) => (c.id === companyId ? { ...c, ...data } : c)),
    }))
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

  addStockItem: (companyId, item) =>
    set((s) => ({ stockItems: { ...s.stockItems, [companyId]: [...(s.stockItems[companyId] ?? []), item] } })),

  fetchStockItemsFromDb: async (companyId) => {
    const { data } = await api.get<TallyStockItem[]>(`/companies/${companyId}/stock-items`)
    set((s) => ({ stockItems: { ...s.stockItems, [companyId]: data } }))
  },

  saveStockItemsToDb: async (companyId, items) => {
    const { data } = await api.put<{ saved: number; syncedAt: string }>(`/companies/${companyId}/stock-items`, items)
    set((s) => ({
      stockItems: { ...s.stockItems, [companyId]: items },
      companies: s.companies.map((c) => c.id === companyId
        ? { ...c, syncTimestamps: { ...c.syncTimestamps, stockItems: data.syncedAt } }
        : c),
    }))
  },

  getStockGroups: (companyId) => get().stockGroups[companyId] ?? [],

  fetchStockGroupsFromDb: async (companyId) => {
    const { data } = await api.get<TallyStockGroup[]>(`/companies/${companyId}/stock-groups`)
    set((s) => ({ stockGroups: { ...s.stockGroups, [companyId]: data } }))
  },

  saveStockGroupsToDb: async (companyId, groups) => {
    const { data } = await api.put<{ saved: number; syncedAt: string }>(`/companies/${companyId}/stock-groups`, groups)
    set((s) => ({
      stockGroups: { ...s.stockGroups, [companyId]: groups },
      companies: s.companies.map((c) => c.id === companyId
        ? { ...c, syncTimestamps: { ...c.syncTimestamps, stockGroups: data.syncedAt } }
        : c),
    }))
  },

  getStockUnits: (companyId) => get().stockUnits[companyId] ?? [],

  fetchStockUnitsFromDb: async (companyId) => {
    const { data } = await api.get<TallyStockUnit[]>(`/companies/${companyId}/stock-units`)
    set((s) => ({ stockUnits: { ...s.stockUnits, [companyId]: data } }))
  },

  saveStockUnitsToDb: async (companyId, units) => {
    const { data } = await api.put<{ saved: number; syncedAt: string }>(`/companies/${companyId}/stock-units`, units)
    set((s) => ({
      stockUnits: { ...s.stockUnits, [companyId]: units },
      companies: s.companies.map((c) => c.id === companyId
        ? { ...c, syncTimestamps: { ...c.syncTimestamps, stockUnits: data.syncedAt } }
        : c),
    }))
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
    const { data } = await api.put<{ saved: number; syncedAt: string }>(`/companies/${companyId}/ledgers`, ledgers)
    set((s) => ({
      ledgers: { ...s.ledgers, [companyId]: ledgers },
      companies: s.companies.map((c) => c.id === companyId
        ? { ...c, syncTimestamps: { ...c.syncTimestamps, ledgers: data.syncedAt } }
        : c),
    }))
  },

  updateCompanyFeature: async (companyId, feature, enabled) => {
    await api.put(`/companies/${companyId}/features`, { feature, enabled })
    set((s) => ({
      companies: s.companies.map((c) => {
        if (c.id !== companyId) return c
        const existing = c.features ?? []
        const idx = existing.findIndex((f: CompanyFeature) => f.feature === feature)
        const updated = [...existing]
        if (idx >= 0) updated[idx] = { feature, enabled }
        else updated.push({ feature, enabled })
        return { ...c, features: updated }
      }),
    }))
  },

  getGodowns: (companyId) => get().godowns[companyId] ?? [],

  fetchGodownsFromDb: async (companyId) => {
    const { data } = await api.get<TallyGodown[]>(`/companies/${companyId}/godowns`)
    set((s) => ({ godowns: { ...s.godowns, [companyId]: data } }))
  },

  saveGodownsToDb: async (companyId, godowns) => {
    const { data } = await api.put<{ saved: number; syncedAt: string }>(`/companies/${companyId}/godowns`, godowns)
    set((s) => ({
      godowns: { ...s.godowns, [companyId]: godowns },
      companies: s.companies.map((c) => c.id === companyId
        ? { ...c, syncTimestamps: { ...c.syncTimestamps, godowns: data.syncedAt } }
        : c),
    }))
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
