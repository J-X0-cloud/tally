/**
 * Shapes returned by the collector service (`collector/`, Elixir). The demo dashboard comes from
 * `GET /api/demo`; keys are camelCase on the wire.
 */
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

export interface Delta {
  text: string;
  direction: "up" | "down";
  good: boolean;
  /** Signed % change. */
  change: number;
}

export type DimensionKey = "sources" | "pages" | "locations" | "devices";

export interface BreakdownTab {
  key: string;
  label: string;
  /** Column header for the name column. */
  heading: string;
  /** Render names in monospace (paths, campaign slugs). */
  mono: boolean;
  chip: "source" | "country" | null;
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
  code: string | null;
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

export interface RangeData {
  key: RangeKey;
  /** Current period; null for hours that haven't happened yet today. */
  current: Array<TrafficPoint | null>;
  previous: TrafficPoint[];
  labels: string[];
  tips: string[];
  totals: Totals;
  priorTotals: Totals;
  deltas: Record<MetricKey, Delta>;
  /** Conversions as % of unique visitors. */
  conversionRate: number;
  span: string;
  interval: "Hourly" | "Daily" | "Weekly";
  comparison: string;
  /** Rows per dimension, per tab key. */
  breakdowns: Record<DimensionKey, Record<string, BreakdownRow[]>>;
  goals: GoalRow[];
  funnel: FunnelStep[];
}

export interface SiteInfo {
  domain: string;
  name: string;
  initial: string;
  description: string;
  currentVisitors: number;
}

export interface LiveFeedItem {
  ago: string;
  path: string;
  source: string;
  country: string;
}

export interface Realtime {
  currentVisitors: number;
  /** Visitors per minute over the last 30 minutes, as % of the peak minute. */
  spark: number[];
  feed: LiveFeedItem[];
}

export interface DemoDashboard {
  site: SiteInfo;
  metrics: MetricDefinition[];
  ranges: Array<{ key: RangeKey; label: string }>;
  defaultRange: RangeKey;
  defaultMetric: MetricKey;
  dimensions: BreakdownDimension[];
  realtime: Realtime;
  data: Record<RangeKey, RangeData>;
}
