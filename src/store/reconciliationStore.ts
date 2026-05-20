import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export interface ReconciliationRow {
  id: string
  date: string
  description: string
  debit: number | null
  credit: number | null
  source: 'bank' | 'books'
  matched: boolean
  /** How the match was determined */
  matchBasis?: 'ref' | 'desc' | 'amount'
  /** Actual UTR / ref token that linked the two entries (only when matchBasis === 'ref') */
  matchToken?: string
}

export interface ReconciliationStats {
  totalBank:       number
  totalBooks:      number
  matched:         number
  missingFromBooks: number
  extraInBooks:    number
}

export interface ReconciliationRecord {
  id:            string
  companyId:     string
  bankName:      string
  booksName:     string
  bankFileName:  string
  booksFileName: string
  createdAt:     string
  stats:         ReconciliationStats
  rows:          ReconciliationRow[]
  /** IDs of missing-from-books rows that have been pushed to Tally */
  syncedMissingIds?: string[]
}

interface ReconciliationStore {
  records:                  ReconciliationRecord[]
  addRecord:                (record: ReconciliationRecord) => void
  removeRecord:             (id: string) => void
  getRecord:                (id: string) => ReconciliationRecord | undefined
  getRecords:               (companyId: string) => ReconciliationRecord[]
  markMissingEntriesSynced: (recordId: string, ids: string[]) => void
}

export const useReconciliationStore = create<ReconciliationStore>()(
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
    { name: 'tally-reconciliation' },
  ),
)
