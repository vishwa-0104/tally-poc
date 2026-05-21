import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { ParsedBankStatement } from '@/types'

export type CashBookStatus = 'pending' | 'synced' | 'partially_synced' | 'error'

export interface CashBookRecord {
  id: string
  companyId: string
  bookName: string
  accountNumber?: string
  fileName: string
  uploadedAt: string
  status: CashBookStatus
  syncedAt?: string
  syncError?: string
  syncedCount: number
  totalCount: number
  totalDebit: number
  totalCredit: number
  transactions: ParsedBankStatement['transactions']
}

export function makeCashBookFingerprint(bookName: string, date: string, amount: number, description: string): string {
  return `cb|${bookName}|${date}|${Math.abs(amount)}|${description.trim()}`
}

interface CashBookStore {
  records:       CashBookRecord[]
  addRecord:     (record: CashBookRecord) => void
  updateRecord:  (id: string, patch: Partial<CashBookRecord>) => void
  removeRecord:  (id: string) => void
  getRecords:    (companyId: string) => CashBookRecord[]
  getRecord:     (id: string) => CashBookRecord | undefined
}

export const useCashBookStore = create<CashBookStore>()(
  persist(
    (set, get) => ({
      records: [],

      addRecord: (record) =>
        set((s) => ({ records: [record, ...s.records] })),

      updateRecord: (id, patch) =>
        set((s) => ({
          records: s.records.map((r) => (r.id === id ? { ...r, ...patch } : r)),
        })),

      removeRecord: (id) =>
        set((s) => ({ records: s.records.filter((r) => r.id !== id) })),

      getRecords: (companyId) =>
        get().records.filter((r) => r.companyId === companyId),

      getRecord: (id) =>
        get().records.find((r) => r.id === id),
    }),
    { name: 'tally-cash-book' },
  ),
)
