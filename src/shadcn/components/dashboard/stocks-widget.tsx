import { Printer, RefreshCw } from "lucide-react"
import { Button } from "@/shadcn/components/ui/button"
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardAction,
} from "@/shadcn/components/ui/card"

export function StocksWidget({
  data,
  onDownload,
  downloadPending = false,
}: {
  data: { name: string; daysSince: number; qty?: number }[]
  onDownload?: () => void
  downloadPending?: boolean
}) {
  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>Slow Moving Stocks</CardTitle>
        {onDownload && (
          <CardAction>
            <Button
              size="sm"
              variant="outline"
              className="transition-all active:scale-95"
              onClick={onDownload}
              disabled={downloadPending}
            >
              {downloadPending ? <RefreshCw className="size-4 animate-spin" /> : <Printer className="size-4" />}
              Print Report
            </Button>
          </CardAction>
        )}
      </CardHeader>
      <CardContent>
        {data.length === 0 ? (
          <p className="text-sm text-muted-foreground">No slow-moving items found</p>
        ) : (
          <div className="space-y-3">
            {data.map((s, i) => (
              <div
                key={s.name}
                className="group flex items-center justify-between border-b pb-2 transition-colors last:border-0 last:pb-0 hover:border-primary/20"
              >
                <div className="flex items-center gap-3">
                  <span className="flex size-6 items-center justify-center rounded-full bg-muted text-xs font-medium text-muted-foreground transition-colors group-hover:bg-primary/10 group-hover:text-primary">
                    {i + 1}
                  </span>
                  <div>
                    <p className="text-sm">{s.name}</p>
                    {s.qty != null && <p className="text-xs text-muted-foreground">Qty: {s.qty}</p>}
                  </div>
                </div>
                <span className={`text-sm font-medium ${s.daysSince >= 90 ? "text-red-500" : s.daysSince >= 30 ? "text-amber-500" : "text-muted-foreground"}`}>
                  {s.daysSince}d
                </span>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
