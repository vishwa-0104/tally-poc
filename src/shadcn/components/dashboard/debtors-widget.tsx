import { Printer, RefreshCw } from "lucide-react"
import { Button } from "@/shadcn/components/ui/button"
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardAction,
} from "@/shadcn/components/ui/card"
import { useFormat } from "@/shadcn/lib/format-context"

export function DebtorsWidget({
  data,
  onDownload,
  downloadPending = false,
}: {
  data: { name: string; amount: number }[]
  onDownload?: () => void
  downloadPending?: boolean
}) {
  const { fmt } = useFormat()
  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>Top Performing Debtors</CardTitle>
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
          <p className="text-sm text-muted-foreground">No debtors found</p>
        ) : (
          <div className="space-y-3">
            {data.map((d, i) => (
              <div
                key={d.name}
                className="group flex items-center justify-between border-b pb-2 transition-colors last:border-0 last:pb-0 hover:border-primary/20"
              >
                <div className="flex items-center gap-3">
                  <span className="flex size-6 items-center justify-center rounded-full bg-muted text-xs font-medium text-muted-foreground transition-colors group-hover:bg-primary/10 group-hover:text-primary">
                    {i + 1}
                  </span>
                  <span className="text-sm">{d.name}</span>
                </div>
                <span className="text-sm font-medium transition-colors group-hover:text-primary">{fmt(d.amount)}</span>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
