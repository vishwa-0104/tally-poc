import { Card, CardContent, CardHeader, CardTitle } from "@/shadcn/components/ui/card"
import { useFormat } from "@/shadcn/lib/format-context"

export function NetMarginWidget({ value, pct }: { value: number | null; pct: number | null }) {
  const { fmt } = useFormat()
  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>Net Margin</CardTitle>
      </CardHeader>
      <CardContent>
        <div className={`text-3xl font-bold tracking-tight ${value == null ? "text-muted-foreground/40" : value < 0 ? "text-red-600 dark:text-red-400" : ""}`}>
          {value != null ? fmt(value) : "—"}
        </div>
        {pct !== null && (
          <div className="mt-1">
            <span className="text-lg font-semibold text-muted-foreground">{pct.toFixed(1)}%</span>
            <span className="ml-1.5 text-xs text-muted-foreground">Net margin</span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
