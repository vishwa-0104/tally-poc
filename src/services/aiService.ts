import type { Bill, ParsedBillData } from '@/types'
import { api } from '@/lib/api'

export type { ParsedBillData }

/** Parse a bill image/PDF via the backend (Anthropic API key stays server-side) */
export async function parseBillWithAI(
  file: File,
  onProgress?: (step: number) => void,
  billType: 'purchase' | 'debit' | 'misc' = 'purchase',
  companyId?: string,
): Promise<ParsedBillData> {
  onProgress?.(0)
  const compressed = await compressImage(file)
  const base64 = await fileToBase64(compressed)
  onProgress?.(1)

  const { data } = await api.post<ParsedBillData>('/bills/parse', {
    base64,
    mediaType: compressed.type,
    billType,
    companyId,
  })

  onProgress?.(2)
  await delay(400)
  onProgress?.(3)

  return data
}

/** Convert a bill's parsed data into a Bill object ready for the store */
export function parsedDataToBill(
  data: ParsedBillData,
  companyId: string,
  imageUrl?: string,
  billType: 'purchase' | 'debit' | 'misc' = 'purchase',
): Bill {
  const lineItems = data.lineItems.map((item, i) => ({ ...item, id: `li_${Date.now()}_${i}` }))
  return {
    id: 'b_' + Date.now(),
    companyId,
    billNumber: data.billNumber,
    vendorName: data.vendorName,
    vendorGstin: data.vendorGstin,
    billDate: data.billDate,
    subtotal: data.subtotal,
    cgstAmount: data.cgstAmount,
    sgstAmount: data.sgstAmount,
    igstAmount: data.igstAmount,
    totalAmount: data.totalAmount,
    roundOffAmount: data.roundOffAmount ?? undefined,
    invoiceDiscountAmount: data.invoiceDiscountAmount ?? undefined,
    extraCharges: data.extraCharges?.length ? data.extraCharges : undefined,
    status: 'parsed',
    imageUrl,
    lineItems,
    originalData: data,
    isEdited: false,
    billType,
    createdAt: new Date().toISOString(),
  }
}

// ── Helpers ────────────────────────────────────────────────

const MAX_DIMENSION = 1024
const JPEG_QUALITY  = 0.80

function compressImage(file: File): Promise<File> {
  if (!file.type.startsWith('image/')) return Promise.resolve(file)

  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const img = new Image()
    img.onload = () => {
      URL.revokeObjectURL(url)
      const { width, height } = img
      const scale = Math.min(1, MAX_DIMENSION / Math.max(width, height))
      const canvas = document.createElement('canvas')
      canvas.width  = Math.round(width  * scale)
      canvas.height = Math.round(height * scale)
      const ctx = canvas.getContext('2d')!
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height)
      canvas.toBlob(
        (blob) => {
          if (!blob) { resolve(file); return }
          resolve(new File([blob], file.name.replace(/\.[^.]+$/, '.jpg'), { type: 'image/jpeg' }))
        },
        'image/jpeg',
        JPEG_QUALITY,
      )
    }
    img.onerror = reject
    img.src = url
  })
}

function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve((reader.result as string).split(',')[1])
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

function delay(ms: number) {
  return new Promise((r) => setTimeout(r, ms))
}
