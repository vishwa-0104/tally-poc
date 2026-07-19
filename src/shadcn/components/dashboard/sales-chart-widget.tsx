import { useState, useMemo } from "react"
import { BarChart3, LineChart as LineChartIcon } from "lucide-react"
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardAction,
} from "@/shadcn/components/ui/card"
import { Button } from "@/shadcn/components/ui/button"
import { Tooltip, TooltipTrigger, TooltipContent, TooltipProvider } from "@/shadcn/components/ui/tooltip"
import { cn } from "@/lib/utils"
import { useFormat } from "@/shadcn/lib/format-context"

type DataPoint = { label: string; amount: number }

export function SalesChartWidget({
  data,
  title = "Sales Trend — Last 10 Days",
  className,
}: {
  data: DataPoint[]
  title?: string
  className?: string
}) {
  const maxVal = useMemo(() => Math.max(1, ...data.map((d) => d.amount)), [data])
  const minVal = useMemo(() => Math.min(...data.map((d) => d.amount), 0), [data])
  const padding = (maxVal - minVal) * 0.1
  const chartMin = minVal - padding
  const chartMax = maxVal + padding
  const chartRange = chartMax - chartMin || 1

  function yPos(value: number) {
    return ((chartMax - value) / chartRange) * 140 + 10
  }

  function xPos(i: number) {
    return 20 + (i / Math.max(1, data.length - 1)) * (280 - 20)
  }

  const [hoveredIdx, setHoveredIdx] = useState<number | null>(null)
  const [chartType, setChartType] = useState<"bar" | "line">("bar")
  const { fmt } = useFormat()

  return (
    <Card className={cn("widget-card sm:col-span-2", className)}>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardAction>
          <TooltipProvider>
            <div className="flex gap-0.5 rounded-lg border border-border p-0.5">
              <Tooltip>
                <TooltipTrigger
                  render={
                    <Button
                      size="xs"
                      variant={chartType === "bar" ? "default" : "ghost"}
                      onClick={() => setChartType("bar")}
                      className="px-1.5"
                    />
                  }
                >
                  <BarChart3 className="size-3.5" />
                </TooltipTrigger>
                <TooltipContent side="top"><p>Bar chart</p></TooltipContent>
              </Tooltip>
              <Tooltip>
                <TooltipTrigger
                  render={
                    <Button
                      size="xs"
                      variant={chartType === "line" ? "default" : "ghost"}
                      onClick={() => setChartType("line")}
                      className="px-1.5"
                    />
                  }
                >
                  <LineChartIcon className="size-3.5" />
                </TooltipTrigger>
                <TooltipContent side="top"><p>Line chart</p></TooltipContent>
              </Tooltip>
            </div>
          </TooltipProvider>
        </CardAction>
      </CardHeader>
      <CardContent>
        {data.length === 0 ? (
          <div className="flex h-40 items-center justify-center text-sm text-muted-foreground">
            No data available
          </div>
        ) : chartType === "bar" ? (
          <div className="relative flex items-end gap-2" style={{ height: 160 }}>
            {data.map((d, i) => {
              const barHeight = ((d.amount / maxVal) * 80 + 20)
              return (
                <div
                  key={d.label}
                  className="group relative flex flex-1 flex-col items-center justify-end self-stretch"
                  onMouseEnter={() => setHoveredIdx(i)}
                  onMouseLeave={() => setHoveredIdx(null)}
                >
                  {hoveredIdx === i && (
                    <div className="absolute -top-8 z-10 animate-scale-in whitespace-nowrap rounded-md bg-foreground px-2 py-1 text-xs font-medium text-background shadow-md">
                      {d.label} — {fmt(d.amount)}
                    </div>
                  )}
                  <div
                    className="w-full animate-bar-grow cursor-pointer rounded-sm bg-gradient-to-t from-primary/80 to-primary/40 transition-all duration-200 group-hover:from-primary group-hover:to-primary/60"
                    style={{
                      height: `${barHeight}%`,
                      animationDelay: `${i * 50}ms`,
                    }}
                  />
                  <span className="mt-1 text-[10px] text-muted-foreground">
                    {d.label.includes(" ") ? d.label.split(" ")[0] : d.label}
                  </span>
                </div>
              )
            })}
          </div>
        ) : (
          <div className="relative" style={{ height: 160 }}>
            <svg
              viewBox="0 0 300 160"
              className="h-full w-full overflow-visible"
              preserveAspectRatio="none"
            >
              {[0.25, 0.5, 0.75].map((f) => (
                <line
                  key={f}
                  x1={20}
                  y1={yPos(chartMin + chartRange * f)}
                  x2={280}
                  y2={yPos(chartMin + chartRange * f)}
                  stroke="currentColor"
                  className="stroke-muted-foreground/15"
                  strokeWidth="1"
                  strokeDasharray="3 4"
                />
              ))}
              {hoveredIdx !== null && (
                <line
                  x1={xPos(hoveredIdx)}
                  y1={10}
                  x2={xPos(hoveredIdx)}
                  y2={150}
                  stroke="currentColor"
                  className="stroke-muted-foreground/30"
                  strokeWidth="1"
                  strokeDasharray="3 4"
                />
              )}
              <polygon
                points={`20,150 ${data.map((d, i) => `${xPos(i)},${yPos(d.amount)}`).join(" ")} 280,150`}
                fill="url(#areaGrad)"
                opacity="0.15"
              />
              <defs>
                <linearGradient id="areaGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="var(--primary)" />
                  <stop offset="100%" stopColor="var(--primary)" stopOpacity="0" />
                </linearGradient>
              </defs>
              <polyline
                points={data.map((d, i) => `${xPos(i)},${yPos(d.amount)}`).join(" ")}
                fill="none"
                className="stroke-primary"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              {data.map((d, i) => (
                <g
                  key={d.label}
                  style={{ cursor: "pointer" }}
                  onMouseEnter={() => setHoveredIdx(i)}
                  onMouseLeave={() => setHoveredIdx(null)}
                >
                  <circle
                    cx={xPos(i)}
                    cy={yPos(d.amount)}
                    r={hoveredIdx === i ? 6 : 3}
                    className="fill-background stroke-primary transition-all duration-200"
                    strokeWidth="2"
                  />
                  {hoveredIdx === i && (
                    <circle cx={xPos(i)} cy={yPos(d.amount)} r="2" className="fill-primary" />
                  )}
                </g>
              ))}
            </svg>
            <div className="flex justify-between px-[18px]">
              {data.map((d) => (
                <span key={d.label} className="text-[10px] text-muted-foreground">
                  {d.label.includes(" ") ? d.label.split(" ")[0] : d.label}
                </span>
              ))}
            </div>
            {hoveredIdx !== null && (
              <div
                className="absolute z-10 -translate-x-1/2 animate-scale-in whitespace-nowrap rounded-md bg-foreground px-2.5 py-1.5 text-xs font-medium text-background shadow-md"
                style={{
                  left: `${(hoveredIdx / Math.max(1, data.length - 1)) * 100}%`,
                  top: yPos(data[hoveredIdx].amount) - 14,
                }}
              >
                <div>{data[hoveredIdx].label}</div>
                <div className="text-background/70">{fmt(data[hoveredIdx].amount)}</div>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
