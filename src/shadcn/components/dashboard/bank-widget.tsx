import { ArrowDownRight, ArrowUpRight, Landmark } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/shadcn/components/ui/card"
import { useFormat } from "@/shadcn/lib/format-context"

export function BankWidget({
  inflow,
  outflow,
  balance,
}: {
  inflow: number | null
  outflow: number | null
  balance: number | null
}) {
  const { fmt } = useFormat()
  const val = (v: number | null) => (v !== null ? fmt(v) : "—")
  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>Bank</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="rounded-full bg-emerald-100 p-1 dark:bg-emerald-900/30">
              <ArrowDownRight className="size-4 text-emerald-600" />
            </div>
            <span className="text-muted-foreground">Inflow</span>
          </div>
          <span className="font-medium">{val(inflow)}</span>
        </div>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="rounded-full bg-red-100 p-1 dark:bg-red-900/30">
              <ArrowUpRight className="size-4 text-red-600" />
            </div>
            <span className="text-muted-foreground">Outflow</span>
          </div>
          <span className="font-medium">{val(outflow)}</span>
        </div>
        <div className="flex items-center justify-between border-t pt-4">
          <div className="flex items-center gap-2">
            <div className="rounded-full bg-primary/10 p-1">
              <Landmark className="size-4 text-primary" />
            </div>
            <span className="text-sm font-medium">Balance</span>
          </div>
          <span className="text-lg font-bold tracking-tight">{val(balance)}</span>
        </div>
      </CardContent>
    </Card>
  )
}
