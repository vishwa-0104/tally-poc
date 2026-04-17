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
  // Purchase ledgers (1:1 static keys)
  purchase_interstate_18?: string
  purchase_interstate_5?:  string
  purchase_up_18?:         string
  purchase_up_5?:          string
  purchase_exempt?:        string
  // CGST / SGST input pairs
  input_cgst_9?:   string
  input_sgst_9?:   string
  input_cgst_2_5?: string
  input_sgst_2_5?: string
  // IGST
  igst_5?:  string
  igst_18?: string
  // Round off
  roundoff_ledger?: string
}

/** Cast stored JSON to LedgerMapping (all fields optional, no migration needed) */
export function normalizeLedgerMapping(raw: unknown): LedgerMapping {
  if (!raw || typeof raw !== 'object') return {}
  return raw as LedgerMapping
}

// Ledger mapping chosen for a single bill before syncing to Tally.
export interface TallyBillMapping {
  vendorLedger?: string
  purchaseLedger?: string
  cgstLedger?: string
  sgstLedger?: string
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
  voucherCounter: number
  mapping: LedgerMapping | null
  createdAt: string
}

// ── Bill ──────────────────────────────────────────────────
export type BillStatus = 'pending' | 'parsed' | 'mapped' | 'synced' | 'error'

/** Raw structured output from the AI parser — never mutated after creation */
export interface ParsedBillData {
  vendorName: string
  vendorGstin: string
  buyerGstin: string | null
  billNumber: string
  billDate: string
  subtotal: number
  cgstAmount: number
  sgstAmount: number
  igstAmount: number
  totalAmount: number
  roundOffAmount?: number
  lineItems: Omit<LineItem, 'id'>[]
}

export interface LineItem {
  id: string
  description: string
  hsnCode: string
  quantity: number
  unit: string
  unitPrice: number
  discountPercent?: number
  gstRate: number
  amount: number
  tallyLedger?: string
  tallyStockItem?: string | null
}

export interface Bill {
  id: string
  companyId: string
  billNumber: string
  vendorName: string
  vendorGstin?: string
  buyerGstin?: string
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
  roundOffAmount?: number
  status: BillStatus
  tallyXml?: string
  tallyMapping?: TallyBillMapping
  syncedAt?: string
  syncError?: string
  lineItems: LineItem[]
  createdAt: string
}

export interface StockItemAlias {
  billItemName: string       // lowercase bill description
  tallyStockItemName: string // Tally stock item name
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

export interface TallyStockItem {
  name: string
  unit?: string
  group?: string
}

export interface TallyStockGroup {
  name: string
  parent: string
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
