import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export interface VendorReconciliationRow {
  id: string
  date: string
  description: string
  debit: number | null
  credit: number | null
  source: 'bank' | 'books'
  matched: boolean
  matchBasis?: 'ref' | 'desc' | 'amount'
  matchToken?: string
}

export interface VendorReconciliationStats {
  totalBank:        number
  totalBooks:       number
  matched:          number
  missingFromBooks: number
  extraInBooks:     number
}

export interface VendorReconciliationRecord {
  id:            string
  companyId:     string
  bankName:      string
  booksName:     string
  bankFileName:  string
  booksFileName: string
  createdAt:     string
  stats:         VendorReconciliationStats
  rows:          VendorReconciliationRow[]
  syncedMissingIds?: string[]
}

interface VendorReconciliationStore {
  records:                  VendorReconciliationRecord[]
  addRecord:                (record: VendorReconciliationRecord) => void
  removeRecord:             (id: string) => void
  getRecord:                (id: string) => VendorReconciliationRecord | undefined
  getRecords:               (companyId: string) => VendorReconciliationRecord[]
  markMissingEntriesSynced: (recordId: string, ids: string[]) => void
}

export const useVendorReconciliationStore = create<VendorReconciliationStore>()(
  persist(
    (set, get) => ({
      records: [],
      addRecord:    (record) => set((s) => ({ records: [record, ...s.records] })),
      removeRecord: (id)     => set((s) => ({ records: s.records.filter((r) => r.id !== id) })),
      getRecord:    (id)     => get().records.find((r) => r.id === id),
      getRecords:   (companyId) => get().records.filter((r) => r.companyId === companyId),
      markMissingEntriesSynced: (recordId, ids) =>
        set((s) => ({
          records: s.records.map((r) =>
            r.id !== recordId ? r : {
              ...r,
              syncedMissingIds: [...new Set([...(r.syncedMissingIds ?? []), ...ids])],
            }
          ),
        })),
    }),
    { name: 'tally-vendor-reconciliation' },
  ),
)
