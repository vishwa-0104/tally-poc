import { TrendingUp, TrendingDown } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/shadcn/components/ui/card"
import { useFormat } from "@/shadcn/lib/format-context"

export function GrossMarginWidget({
  value,
  pct,
  targetPct,
}: {
  value: number | null
  pct: number | null
  targetPct: number | null
}) {
  const { fmt } = useFormat()
  const achieved = pct !== null && targetPct ? (pct / targetPct) * 100 : null

  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>Gross Margin</CardTitle>
      </CardHeader>
      <CardContent>
        <div className={`text-3xl font-bold tracking-tight ${value == null ? "text-muted-foreground/40" : ""}`}>
          {value != null ? fmt(value) : "—"}
        </div>
        {pct !== null && (
          <div className="mt-1 flex items-baseline gap-1.5">
            <span className="text-lg font-semibold text-muted-foreground">{pct.toFixed(1)}%</span>
            {achieved !== null && (
              <span className={`flex items-center gap-0.5 text-xs ${achieved >= 100 ? "text-emerald-600 dark:text-emerald-400" : "text-amber-600 dark:text-amber-400"}`}>
                {achieved >= 100 ? <TrendingUp className="size-3" /> : <TrendingDown className="size-3" />}
                {achieved.toFixed(1)}% of target
              </span>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
