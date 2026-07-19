import { BadgeDollarSign } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/shadcn/components/ui/card"
import { useFormat } from "@/shadcn/lib/format-context"

export function ReceivablesWidget({ total }: { total: number | null }) {
  const { fmt } = useFormat()
  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>Receivables</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="rounded-full bg-blue-100 p-1 dark:bg-blue-900/30">
              <BadgeDollarSign className="size-4 text-blue-600" />
            </div>
            <span className="text-muted-foreground">Total Receivable</span>
          </div>
          <span className="text-lg font-bold tracking-tight">
            {total !== null ? fmt(total) : "—"}
          </span>
        </div>
      </CardContent>
    </Card>
  )
}
