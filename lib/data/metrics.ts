import type { MetricDefinition, MetricKey } from "@/types/analytics";

export const METRICS: MetricDefinition[] = [
  { key: "visitors", label: "Unique visitors", format: "number", lowerIsBetter: false },
  { key: "visits", label: "Total visits", format: "number", lowerIsBetter: false },
  { key: "pageviews", label: "Pageviews", format: "number", lowerIsBetter: false },
  { key: "bounce", label: "Bounce rate", format: "percent", lowerIsBetter: true },
  { key: "duration", label: "Visit duration", format: "duration", lowerIsBetter: false },
  { key: "conversions", label: "Conversions", format: "number", lowerIsBetter: false },
];

export const metricDef = (key: MetricKey) => METRICS.find((m) => m.key === key)!;
