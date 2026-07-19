import { CreditCard } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/shadcn/components/ui/card"
import { useFormat } from "@/shadcn/lib/format-context"

export function PayablesWidget({ total }: { total: number | null }) {
  const { fmt } = useFormat()
  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>Payables</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="rounded-full bg-purple-100 p-1 dark:bg-purple-900/30">
              <CreditCard className="size-4 text-purple-600" />
            </div>
            <span className="text-muted-foreground">Total Payable</span>
          </div>
          <span className="text-lg font-bold tracking-tight">
            {total !== null ? fmt(total) : "—"}
          </span>
        </div>
      </CardContent>
    </Card>
  )
}
