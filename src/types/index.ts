// ── Auth ──────────────────────────────────────────────────
export type Role = 'admin' | 'company'

export interface User {
  id: string
  name: string
  email: string
  role: Role
  enterpriseName?: string
  avatar: string
}

export interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  companies: Company[]
  activeCompanyId: string | null
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
  godown?: string
}

// ── Company Feature Flags ─────────────────────────────────────────────────────
export interface CompanyFeature {
  feature: string
  enabled: boolean
}

/** Stable feature key constants — extend as new features are added */
export const COMPANY_FEATURES = {
  GODOWN: 'godown',
} as const

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
  features?: CompanyFeature[]
  syncTimestamps?: { ledgers?: string; stockItems?: string; stockGroups?: string; stockUnits?: string; godowns?: string } | null
  parseBillsLimit: number
  parseBillsUsed: number
  parseBlocked: boolean
  parseService: string
  parseModel: string
  subscriptionExpiresAt: string | null
  subscriptionRenewedAt: string | null
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
  /** Invoice-level discount amount — null when discount is only per-line (Pattern A) */
  invoiceDiscountAmount?: number | null
  lineItems: Omit<LineItem, 'id'>[]
}

export interface LineItem {
  id: string
  description: string
  hsnCode: string
  quantity: number
  unit: string
  unitPrice: number
  discountPercent?: number | null
  discountAmount?: number | null
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
  invoiceDiscountAmount?: number | null
  status: BillStatus
  tallyXml?: string
  tallyMapping?: TallyBillMapping
  syncedAt?: string
  syncError?: string
  lineItems: LineItem[]
  billType?: 'purchase' | 'misc'
  createdAt: string
}

export interface StockItemAlias {
  billItemName: string       // lowercase bill description
  tallyStockItemName: string // Tally stock item name
}

// ── Tally ─────────────────────────────────────────────────
export interface TallyGodown {
  name: string
}

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

export interface TallyStockUnit {
  name: string
  symbol: string
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
