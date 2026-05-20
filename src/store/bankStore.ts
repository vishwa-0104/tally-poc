import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { ParsedBankStatement } from '@/types'

export type BankStatementStatus = 'pending' | 'synced' | 'partially_synced' | 'error'

export interface BankStatementRecord {
  id: string
  companyId: string
  bankName: string
  accountNumber?: string
  fileName: string
  uploadedAt: string
  status: BankStatementStatus
  syncedAt?: string
  syncError?: string
  syncedCount: number
  totalCount: number
  /** Total money received (bank CREDIT column) */
  totalDebit: number
  /** Total money paid (bank DEBIT column) */
  totalCredit: number
  transactions: ParsedBankStatement['transactions']
}

/** Stable fingerprint: bankName|date|amount|description */
export function makeFingerprint(bankName: string, date: string, amount: number, description: string): string {
  return `${bankName}|${date}|${Math.abs(amount)}|${description.trim()}`
}

interface BankStore {
  statements:      BankStatementRecord[]
  addStatement:    (record: BankStatementRecord) => void
  updateStatement: (id: string, patch: Partial<BankStatementRecord>) => void
  removeStatement: (id: string) => void
  getStatements:   (companyId: string) => BankStatementRecord[]
  getStatement:    (id: string) => BankStatementRecord | undefined
}

export const useBankStore = create<BankStore>()(
  persist(
    (set, get) => ({
      statements: [],

      addStatement: (record) =>
        set((s) => ({ statements: [record, ...s.statements] })),

      updateStatement: (id, patch) =>
        set((s) => ({
          statements: s.statements.map((r) => (r.id === id ? { ...r, ...patch } : r)),
        })),

      removeStatement: (id) =>
        set((s) => ({ statements: s.statements.filter((r) => r.id !== id) })),

      getStatements: (companyId) =>
        get().statements.filter((r) => r.companyId === companyId),

      getStatement: (id) =>
        get().statements.find((r) => r.id === id),
    }),
    { name: 'tally-bank-statements' },
  ),
)
