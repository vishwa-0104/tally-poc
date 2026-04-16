import { z } from 'zod'

export const loginSchema = z.object({
  email: z.string().email('Please enter a valid email'),
  password: z.string().min(1, 'Password is required'),
  companyId: z.string().optional(),
})

export const registerSchema = z
  .object({
    name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Please enter a valid email'),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    confirmPassword: z.string(),
  })
  .refine((d) => d.password === d.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  })

export const newCompanySchema = z.object({
  name: z.string().min(3, 'Company name is required'),
  gstin: z
    .string()
    .regex(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/, 'Invalid GSTIN format')
    .or(z.literal('')),
  email: z.string().email('Valid email required for company login'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  port: z.number().min(1).max(65535),
})

const lineItemEditSchema = z.object({
  id: z.string(),
  description: z.string(),
  hsnCode: z.string(),
  quantity: z.coerce.number(),
  unit: z.string(),
  unitPrice: z.coerce.number(),
  discountPercent: z.coerce.number().optional(),
  gstRate: z.coerce.number(),
  amount: z.coerce.number(),
  tallyLedger: z.string().nullish(),
  tallyStockItem: z.string().nullish(),
})

export const mappingSchema = z.object({
  vendorLedger:          z.string().optional(),
  // Purchase ledgers — one per GST rate bucket present in the bill
  purchaseLedger_exempt: z.string().optional(),
  purchaseLedger_5:      z.string().optional(),
  purchaseLedger_18:     z.string().optional(),
  // CGST / SGST — intra-state bills only
  cgstLedger_5:          z.string().optional(),
  sgstLedger_5:          z.string().optional(),
  cgstLedger_18:         z.string().optional(),
  sgstLedger_18:         z.string().optional(),
  // IGST — interstate bills only
  igstLedger_5:          z.string().optional(),
  igstLedger_18:         z.string().optional(),
  // Bill meta
  billDate:       z.string().min(1, 'Date is required'),
  billNumber:     z.string().min(1, 'Bill number is required'),
  voucherNumber:  z.string().optional(),
  totalAmount:    z.coerce.number().positive('Amount must be positive'),
  roundOffAmount: z.coerce.number().optional(),
  lineItems:      z.array(lineItemEditSchema).optional(),
})

export type LoginInput      = z.infer<typeof loginSchema>
export type RegisterInput   = z.infer<typeof registerSchema>
export type NewCompanyInput = z.infer<typeof newCompanySchema>
export type MappingInput    = z.infer<typeof mappingSchema>
