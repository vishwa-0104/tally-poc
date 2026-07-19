import type { LucideIcon } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/shadcn/components/ui/card"

export function RatioWidget({
  title,
  subtitle,
  value,
  icon: Icon,
  suffix = "",
}: {
  title: string
  subtitle?: string
  value: number | null
  icon: LucideIcon
  suffix?: string
}) {
  const noData = value == null

  return (
    <Card className="widget-card">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        {noData ? (
          <p className="text-sm italic text-muted-foreground">No data available</p>
        ) : (
          <div className="flex items-center gap-2">
            <Icon className="size-5 text-muted-foreground" />
            <span className="text-3xl font-bold tracking-tight">
              {value.toLocaleString("en-IN", { maximumFractionDigits: 1 })}
            </span>
            {suffix && <span className="text-sm text-muted-foreground">{suffix}</span>}
          </div>
        )}
        {subtitle && <p className="mt-1 text-xs text-muted-foreground">{subtitle}</p>}
      </CardContent>
    </Card>
  )
}
