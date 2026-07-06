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
export interface BankDefaultLedger {
  keyword: string  // e.g. "HDFC", "ICICI" — matched case-insensitively against bank name
  ledger:  string  // Tally ledger name
}

export interface LedgerMapping {
  // Purchase ledgers (1:1 static keys)
  purchase_interstate_18?: string
  purchase_interstate_5?:  string
  purchase_interstate_40?: string
  purchase_up_18?:         string
  purchase_up_5?:          string
  purchase_up_40?:         string
  purchase_exempt?:        string
  // CGST / SGST input pairs
  input_cgst_9?:   string
  input_sgst_9?:   string
  input_cgst_2_5?: string
  input_sgst_2_5?: string
  input_cgst_20?:  string
  input_sgst_20?:  string
  // IGST
  igst_5?:  string
  igst_18?: string
  igst_40?: string
  // Round off
  roundoff_ledger?: string
  // Bank & Cash Book default ledgers
  bank_default_ledgers?:      BankDefaultLedger[]
  cash_book_default_ledgers?: string[]
}

/** Cast stored JSON to LedgerMapping (all fields optional, no migration needed) */
export function normalizeLedgerMapping(raw: unknown): LedgerMapping {
  if (!raw || typeof raw !== 'object') return {}
  return raw as LedgerMapping
}

export interface ExtraCharge {
  description: string
  amount: number
  ledger?: string
}

// Ledger mapping chosen for a single bill before syncing to Tally.
export interface TallyBillMapping {
  vendorLedger?: string
  purchaseLedger?: string
  cgstLedger?: string
  sgstLedger?: string
  igstLedger?: string
  godown?: string
  extraCharges?: ExtraCharge[]
  isDebit?: boolean   // misc bills only — true when user chose Debit Note at upload
  isCredit?: boolean  // misc bills only — true when user chose Credit Note at upload
}

// ── Company Feature Flags ─────────────────────────────────────────────────────
export interface CompanyFeature {
  feature: string
  enabled: boolean
}

/** Stable feature key constants — extend as new features are added */
export const COMPANY_FEATURES = {
  GODOWN:          'godown',
  DISCOUNT_COLUMN: 'discount_column',
  DEBIT_VOUCHER:   'debit_voucher',
  CREDIT_VOUCHER:  'credit_voucher',
  BANK_VOUCHER:     'bank_voucher',
  BANK_RECONCILE:   'bank_reconcile',
  CASH_BOOK:        'cash_book',
  HIDE_SETTINGS:    'hide_settings',
  VENDOR_RECONCILE: 'vendor_reconcile',
} as const

export interface DashboardSettings {
  today?: {
    salesAccounts?:        string[]
    salesIncludeVouchers?: string[]
    salesExcludeVouchers?: string[]
    cashInflowLedgers?:    string[]
    bankLedgers?:          string[]
  }
  ytd?: {
    purchaseAccounts?:          string[]
    purchaseIncludeVouchers?:   string[]
    purchaseExcludeVouchers?:   string[]
    directExpenseLedgers?:      string[]
    indirectExpenseLedgers?:         string[]
    indirectExpenseIncludeVouchers?: string[]
    indirectExpenseExcludeVouchers?: string[]
    indirectIncomeLedgers?:          string[]
    indirectIncomeIncludeVouchers?:  string[]
    indirectIncomeExcludeVouchers?:  string[]
    ebitdaLedgers?:                  string[]
    ebitdaIncludeVouchers?:          string[]
    ebitdaExcludeVouchers?:          string[]
    grossMarginTarget?:              number
    // Analysis tab ratio KPIs (ROCE/ROE/Debt-Equity) — ledger lists with no
    // standard Tally group, so the company must name them explicitly.
    interestExpenseLedgers?:         string[]
    taxPaymentLedgers?:              string[]
    nonOperatingIncomeLedgers?:      string[]
    nonOperatingInvestmentLedgers?:  string[]
    directorLoanLedgers?:            string[]
    // ROCE's "Long Term Borrowings" — Tally's "Loans (Liability)" group has
    // no long-term/short-term split, so name the specific long-term loan
    // ledgers explicitly. (Debt/Equity's "Total Interest Bearing Loans"
    // keeps using the whole Loans (Liability) group total — that one
    // genuinely wants everything, short and long term combined.)
    longTermBorrowingLedgers?:       string[]
    // Analysis tab's own Sales definition — deliberately separate from
    // today.salesAccounts/salesIncludeVouchers/salesExcludeVouchers so the
    // ratio KPIs (DSO, Net Profit) never silently depend on the Performance
    // tab's settings.
    analysisSalesAccounts?:          string[]
    analysisSalesIncludeVouchers?:   string[]
    analysisSalesExcludeVouchers?:   string[]
  }
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
  voucherType: string
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
  dashboardSettings?: DashboardSettings | null
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
  extraCharges?: ExtraCharge[]
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
  extraCharges?: ExtraCharge[]
  status: BillStatus
  tallyXml?: string
  tallyMapping?: TallyBillMapping
  syncedAt?: string
  syncError?: string
  lineItems: LineItem[]
  billType?: 'purchase' | 'debit' | 'misc'
  createdAt: string
}

export interface StockItemAlias {
  billItemName: string       // lowercase bill description
  tallyStockItemName: string // Tally stock item name
}

// ── Bank ──────────────────────────────────────────────────

export interface BankTransaction {
  id: string
  date: string
  description: string
  /** Bank statement CREDIT column — money received into account */
  debit: number | null
  /** Bank statement DEBIT column — money paid out of account */
  credit: number | null
  balance?: number | null
  synced?: boolean
  /** Counterpart ledger in Tally (expense/income/party) */
  ledger: string
  voucherType: string
  selected: boolean
  narration?: string
  entryDate?: string
}

export interface ParsedBankStatement {
  bankName: string
  accountNumber?: string
  transactions: Array<Omit<BankTransaction, 'ledger' | 'voucherType' | 'selected'>>
}

// ── Leads ─────────────────────────────────────────────────
export type LeadStatus = 'new_lead' | 'onboarded' | 'not_onboarded' | 'rejected'

export interface Lead {
  id: string
  companyName: string
  phone: string
  email: string
  description?: string
  status: LeadStatus
  remarks?: string
  createdAt: string
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
