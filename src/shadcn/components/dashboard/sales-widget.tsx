import { TrendingUp, TrendingDown } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/shadcn/components/ui/card"
import { useFormat } from "@/shadcn/lib/format-context"

export function SalesWidget({
  current,
  previous,
  targetInfo,
  title = "Sales",
}: {
  current: number | null
  previous: number | null
  /** Target achievement — used instead of `previous` when there's no comparable prior-period figure (e.g. YTD) */
  targetInfo?: { target: number; achieved: number } | null
  title?: string
}) {
  const { fmt } = useFormat()
  const hasPrevious = current != null && previous != null && previous > 0
  const diff = hasPrevious ? current! - previous! : 0
  const pct = hasPrevious ? ((diff / previous!) * 100).toFixed(1) : "0"
  const isUp = diff >= 0

  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className={`text-3xl font-bold tracking-tight ${current == null ? "text-muted-foreground/40" : ""}`}>
          {current != null ? fmt(current) : "—"}
        </div>
        {hasPrevious && (
          <div className={`mt-1 flex items-center gap-1 text-sm ${isUp ? "text-emerald-600 dark:text-emerald-400" : "text-red-600 dark:text-red-400"}`}>
            {isUp ? <TrendingUp className="size-4" /> : <TrendingDown className="size-4" />}
            <span>
              {isUp ? "+" : ""}
              {pct}% vs previous ({fmt(Math.abs(diff))})
            </span>
          </div>
        )}
        {!hasPrevious && targetInfo && (
          <div className="mt-1 flex items-center gap-1.5 text-sm">
            <span className={targetInfo.achieved >= 100 ? "text-emerald-600 dark:text-emerald-400" : "text-amber-600 dark:text-amber-400"}>
              {targetInfo.achieved.toFixed(1)}% of target
            </span>
            <span className="text-muted-foreground text-xs">({fmt(targetInfo.target)})</span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
