import type { Bill, ParsedBillData } from '@/types'
import { api } from '@/lib/api'

export type { ParsedBillData }

/** Parse a bill image/PDF via the backend (Anthropic API key stays server-side) */
export async function parseBillWithAI(
  file: File,
  onProgress?: (step: number) => void,
): Promise<ParsedBillData> {
  onProgress?.(0)
  const base64 = await fileToBase64(file)
  onProgress?.(1)

  const { data } = await api.post<ParsedBillData>('/bills/parse', {
    base64,
    mediaType: file.type,
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
    status: 'parsed',
    imageUrl,
    lineItems,
    originalData: data,
    isEdited: false,
    createdAt: new Date().toISOString(),
  }
}

// ── Helpers ────────────────────────────────────────────────

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
