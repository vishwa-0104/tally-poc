import { create } from 'zustand'
import type { Bill, BillStatus } from '@/types'
import { api } from '@/lib/api'

interface BillStore {
  bills: Record<string, Bill[]>
  loading: boolean
  fetchBills: (companyId: string) => Promise<void>
  getBills: (companyId: string) => Bill[]
  getBill: (companyId: string, billId: string) => Bill | undefined
  addBill: (bill: Bill) => Promise<void>
  updateBillStatus: (companyId: string, billId: string, status: BillStatus, extra?: Partial<Bill>) => Promise<void>
  deleteBill: (companyId: string, billId: string) => Promise<void>
}

export const useBillStore = create<BillStore>((set, get) => ({
  bills: {},
  loading: false,

  fetchBills: async (companyId) => {
    set({ loading: true })
    try {
      const { data } = await api.get<Bill[]>(`/companies/${companyId}/bills`)
      set((s) => ({ bills: { ...s.bills, [companyId]: data } }))
    } finally {
      set({ loading: false })
    }
  },

  getBills: (companyId) => get().bills[companyId] ?? [],

  getBill: (companyId, billId) =>
    (get().bills[companyId] ?? []).find((b) => b.id === billId),

  addBill: async (bill) => {
    const { data } = await api.post<Bill>(`/companies/${bill.companyId}/bills`, bill)
    set((s) => ({
      bills: {
        ...s.bills,
        [bill.companyId]: [data, ...(s.bills[bill.companyId] ?? [])],
      },
    }))
  },

  updateBillStatus: async (companyId, billId, status, extra = {}) => {
    const existing = get().getBill(companyId, billId)
    if (!existing) return

    const updated: Bill = { ...existing, status, ...extra }

    // Optimistic update — UI reflects the new status immediately
    set((s) => ({
      bills: {
        ...s.bills,
        [companyId]: (s.bills[companyId] ?? []).map((b) => (b.id === billId ? updated : b)),
      },
    }))

    try {
      const { data } = await api.put<Bill>(`/bills/${billId}`, updated)
      // Reconcile with server response (e.g. normalised status casing)
      set((s) => ({
        bills: {
          ...s.bills,
          [companyId]: (s.bills[companyId] ?? []).map((b) => (b.id === billId ? data : b)),
        },
      }))
    } catch (err) {
      // Revert to previous state if the API call fails
      set((s) => ({
        bills: {
          ...s.bills,
          [companyId]: (s.bills[companyId] ?? []).map((b) => (b.id === billId ? existing : b)),
        },
      }))
      throw err
    }
  },

  deleteBill: async (companyId, billId) => {
    // Optimistic remove
    set((s) => ({
      bills: {
        ...s.bills,
        [companyId]: (s.bills[companyId] ?? []).filter((b) => b.id !== billId),
      },
    }))
    try {
      await api.delete(`/bills/${billId}`)
    } catch (err) {
      // Revert on failure
      const { data } = await api.get<Bill[]>(`/companies/${companyId}/bills`)
      set((s) => ({ bills: { ...s.bills, [companyId]: data } }))
      throw err
    }
  },
}))
