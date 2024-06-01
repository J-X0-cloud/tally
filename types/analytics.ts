export type RangeKey = "today" | "7d" | "30d" | "12m";
export type MetricKey = "visitors" | "visits" | "pageviews" | "bounce" | "duration" | "conversions";
export type MetricFormat = "number" | "percent" | "duration";

/** Traffic for one chart bucket (an hour, a day or a week). Bounce is %, duration is seconds. */
export type TrafficPoint = Record<MetricKey, number>;
export type Totals = Record<MetricKey, number>;

export interface MetricDefinition {
  key: MetricKey;
  label: string;
  format: MetricFormat;
  lowerIsBetter: boolean;
}

export interface RangeData {
  key: RangeKey;
  /** Current period; null for hours that haven't happened yet today. */
  current: Array<TrafficPoint | null>;
  previous: TrafficPoint[];
  labels: string[];
  tips: string[];
  totals: Totals;
  priorTotals: Totals;
  span: string;
  interval: "Hourly" | "Daily" | "Weekly";
  comparison: string;
}

export interface Delta {
  text: string;
  direction: "up" | "down";
  good: boolean;
}

export type DimensionKey = "sources" | "pages" | "locations" | "devices";

export interface BreakdownTab {
  key: string;
  label: string;
  /** Column header for the name column. */
  heading: string;
  /** Typical share of visitors per row; actual rows vary around it. */
  rows: Array<{ name: string; share: number }>;
  /** Render names in monospace (paths, campaign slugs). */
  mono?: boolean;
  chip?: "source" | "country";
}

export interface BreakdownDimension {
  key: DimensionKey;
  title: string;
  column: string;
  tabs: BreakdownTab[];
}

export interface BreakdownRow {
  name: string;
  /** ISO country code for country rows. */
  code?: string;
  value: number;
  share: number;
  /** Bar width relative to the top row, %. */
  width: number;
}

export interface GoalRow {
  name: string;
  uniques: number;
  total: number;
  conversionRate: number;
  revenue: number | null;
}

export interface FunnelStep {
  name: string;
  value: number;
  /** % of the first step. */
  ofFirst: number;
  /** % lost since the previous step; null for the first step. */
  dropOff: number | null;
}
