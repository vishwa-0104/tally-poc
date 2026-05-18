import type { ParsedBankStatement } from '@/types'

export function parseCsvRow(line: string): string[] {
  const result: string[] = []
  let current = ''
  let inQuotes = false
  for (let i = 0; i < line.length; i++) {
    if (line[i] === '"') { inQuotes = !inQuotes }
    else if (line[i] === ',' && !inQuotes) { result.push(current.trim()); current = '' }
    else { current += line[i] }
  }
  result.push(current.trim())
  return result
}

export function parseAmount(val: string | undefined): number | null {
  if (!val) return null
  const n = parseFloat(val.replace(/["',\s]/g, ''))
  return isNaN(n) || n === 0 ? null : n
}

export function normalizeDate(d: string): string {
  d = d.trim().replace(/['"]/g, '')
  let m = d.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/)
  if (m) return `${m[3]}-${m[2].padStart(2, '0')}-${m[1].padStart(2, '0')}`
  if (/^\d{4}-\d{2}-\d{2}$/.test(d)) return d
  m = d.match(/^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})$/)
  if (m) {
    const months: Record<string, string> = {
      jan:'01', feb:'02', mar:'03', apr:'04', may:'05', jun:'06',
      jul:'07', aug:'08', sep:'09', oct:'10', nov:'11', dec:'12',
    }
    const mo = months[m[2].toLowerCase()]
    if (mo) return `${m[3]}-${mo}-${m[1].padStart(2, '0')}`
  }
  return d
}

export function parseCsvBankStatement(text: string, fileName: string): ParsedBankStatement {
  const lines = text.trim().split(/\r?\n/)
  if (lines.length < 2) return { bankName: fileName, transactions: [] }

  let headerIdx = 0
  for (let i = 0; i < Math.min(5, lines.length); i++) {
    if (lines[i].toLowerCase().includes('date')) { headerIdx = i; break }
  }

  const headers = parseCsvRow(lines[headerIdx]).map((h) => h.toLowerCase().replace(/['"]/g, '').trim())
  const find = (...terms: string[]) => headers.findIndex((h) => terms.some((t) => h.includes(t)))

  const dateIdx   = find('date')
  const descIdx   = find('description', 'narration', 'particulars', 'detail', 'remarks', 'transaction remark', 'txn remark')
  const debitIdx  = find('credit', 'deposit', 'cr ')
  const creditIdx = find('debit', 'withdrawal', 'dr ', 'withd')
  const balIdx    = find('balance')

  if (dateIdx === -1) return { bankName: fileName, transactions: [] }

  const transactions: ParsedBankStatement['transactions'] = []
  for (let i = headerIdx + 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue
    const cols  = parseCsvRow(lines[i])
    const raw   = cols[dateIdx]?.replace(/['"]/g, '').trim() || ''
    const desc  = (descIdx >= 0 ? cols[descIdx] : '').replace(/['"]/g, '').trim()
    if (!raw && !desc) continue

    const debit   = debitIdx  >= 0 ? parseAmount(cols[debitIdx])  : null
    const credit  = creditIdx >= 0 ? parseAmount(cols[creditIdx]) : null
    const balance = balIdx    >= 0 ? parseAmount(cols[balIdx])    : null
    if (debit === null && credit === null) continue

    transactions.push({
      id:          `txn_${Date.now()}_${i}`,
      date:        normalizeDate(raw),
      description: desc,
      debit,
      credit,
      balance:     balance ?? undefined,
    })
  }

  return { bankName: fileName.replace(/\.[^.]+$/, ''), transactions }
}
