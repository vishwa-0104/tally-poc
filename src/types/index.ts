// ── Auth ──────────────────────────────────────────────────
export type Role = 'admin' | 'company'

export interface User {
  id: string
  name: string
  email: string
  role: Role
  companyId?: string
  avatar: string
}

export interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
}

// ── Company ───────────────────────────────────────────────
export interface LedgerMapping {
  purchase: string
  cgst: string
  sgst: string
  igst: string
}

// Ledger mapping chosen for a single bill before syncing to Tally.
export interface TallyBillMapping {
  vendorLedger: string
  purchaseLedger: string
  cgstLedger: string
  sgstLedger: string
  igstLedger?: string
}

export interface Company {
  id: string
  name: string
  gstin: string
  email: string
  port: number
  totalBills: number
  syncedBills: number
  pendingBills: number
  errorBills: number
  mapping: LedgerMapping | null
  createdAt: string
}

// ── Bill ──────────────────────────────────────────────────
export type BillStatus = 'pending' | 'parsed' | 'mapped' | 'synced' | 'error'

/** Raw structured output from the AI parser — never mutated after creation */
export interface ParsedBillData {
  vendorName: string
  vendorGstin: string
  billNumber: string
  billDate: string
  subtotal: number
  cgstAmount: number
  sgstAmount: number
  igstAmount: number
  totalAmount: number
  lineItems: Omit<LineItem, 'id'>[]
}

export interface LineItem {
  id: string
  description: string
  hsnCode: string
  quantity: number
  unit: string
  unitPrice: number
  gstRate: number
  amount: number
  tallyLedger?: string
}

export interface Bill {
  id: string
  companyId: string
  billNumber: string
  vendorName: string
  vendorGstin?: string
  billDate: string
  subtotal: number
  cgstAmount: number
  sgstAmount: number
  igstAmount: number
  totalAmount: number
  /** Original AI output — immutable, never overwritten */
  originalData?: ParsedBillData
  /** True when the user has manually edited any field after AI parsing */
  isEdited?: boolean
  rawAiJson?: Record<string, unknown>
  imageUrl?: string
  status: BillStatus
  tallyXml?: string
  tallyMapping?: TallyBillMapping
  syncedAt?: string
  syncError?: string
  lineItems: LineItem[]
  createdAt: string
}

// ── Tally ─────────────────────────────────────────────────
export interface TallyLedger {
  name: string
  group: string
  gstin?: string
  state?: string
  openingBalance?: string
  gstRegistrationType?: string
}

export interface TallySyncResult {
  success: boolean
  created: number
  altered: number
  errors: number
  message?: string
}

// ── API Responses ─────────────────────────────────────────
export interface ApiResponse<T> {
  data: T
  message?: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
}

// ── Forms ─────────────────────────────────────────────────
export interface LoginForm {
  email: string
  password: string
  companyId?: string
}

export interface RegisterForm {
  name: string
  email: string
  password: string
  confirmPassword: string
}

export interface NewCompanyForm {
  name: string
  gstin: string
  email: string
  password: string
  port: number
}

export interface MappingForm {
  vendorLedger: string
  purchaseLedger: string
  cgstLedger: string
  sgstLedger: string
  igstLedger: string
  billDate: string
  billNumber: string
  totalAmount: number
}
