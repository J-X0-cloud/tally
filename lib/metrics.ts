/**
 * Metrics service for the dashboard: range bucketing, totals with period comparison, KPI deltas,
 * breakdown tables, goals and the checkout funnel. All derived from the seeded traffic model.
 */
import { format } from "date-fns";

import { createRng, hashSeed } from "@/lib/random";
import { DIMENSIONS } from "@/lib/data/dimensions";
import { CHECKOUT_FUNNEL, GOALS } from "@/lib/data/goals";
import { AVERAGE_ORDER, DAYS, NOW, TODAY, TODAY_HOURS, YESTERDAY_HOURS } from "@/lib/data/simulation";
import type {
  BreakdownRow,
  Delta,
  DimensionKey,
  FunnelStep,
  GoalRow,
  MetricKey,
  RangeData,
  RangeKey,
  Totals,
  TrafficPoint,
} from "@/types/analytics";

export const RANGE_OPTIONS: Array<{ key: RangeKey; label: string }> = [
  { key: "today", label: "Today" },
  { key: "7d", label: "7D" },
  { key: "30d", label: "30D" },
  { key: "12m", label: "12M" },
];

export const DEFAULT_RANGE: RangeKey = "30d";
export const DEFAULT_METRIC: MetricKey = "visitors";

/** Visitors counted on several days are one unique visitor over the range; this is the typical overlap. */
const MULTI_DAY_UNIQUE_RATIO = 0.86;
const YEAR_UNIQUE_RATIO = 0.8;

const dayLabel = (d: Date) => format(d, "MMM d");

/** Sum counts; average bounce and duration weighted by visits. */
export function aggregate(points: readonly TrafficPoint[], multiDay = true): Totals {
  const sum = (k: MetricKey) => points.reduce((a, p) => a + p[k], 0);
  const visits = sum("visits");
  return {
    visitors: sum("visitors") * (multiDay ? MULTI_DAY_UNIQUE_RATIO : 1),
    visits,
    pageviews: sum("pageviews"),
    bounce: points.reduce((a, p) => a + p.bounce * p.visits, 0) / visits,
    duration: points.reduce((a, p) => a + p.duration * p.visits, 0) / visits,
    conversions: sum("conversions"),
  };
}

const hourLabel = (h: number) => `${h % 12 || 12}${h < 12 ? "am" : "pm"}`;

function buildRange(key: RangeKey): RangeData {
  if (key === "today") {
    const labels = Array.from({ length: 24 }, (_, h) => hourLabel(h));
    return {
      key,
      current: [...TODAY_HOURS, ...Array<null>(23 - NOW.hour).fill(null)],
      previous: [...YESTERDAY_HOURS],
      labels,
      tips: labels.map((l) => `Today ${l}`),
      totals: aggregate(TODAY_HOURS, false),
      priorTotals: aggregate(YESTERDAY_HOURS.slice(0, NOW.hour + 1), false),
      span: `Today, ${dayLabel(TODAY)} · until ${NOW.hour % 12}:${NOW.minute}pm`,
      interval: "Hourly",
      comparison: "vs. yesterday",
    };
  }

  if (key === "7d" || key === "30d") {
    const n = key === "7d" ? 7 : 30;
    const cur = DAYS.slice(-n);
    const prev = DAYS.slice(-2 * n, -n);
    const last = cur[cur.length - 1].date;
    return {
      key,
      current: cur.map((d) => d.point),
      previous: prev.map((d) => d.point),
      labels: cur.map((d) => (n === 7 ? format(d.date, "EEE d") : dayLabel(d.date))),
      tips: cur.map((d) => format(d.date, "EEE, MMM d")),
      totals: aggregate(cur.map((d) => d.point)),
      priorTotals: aggregate(prev.map((d) => d.point)),
      span: `${dayLabel(cur[0].date)} – ${dayLabel(last)}, ${last.getFullYear()}`,
      interval: "Daily",
      comparison: "vs. previous period",
    };
  }

  // 12 months: 52 weekly buckets, compared with the same weeks a year earlier.
  const weeks = Array.from({ length: 52 }, (_, w) =>
    w < 51 ? DAYS.slice(-364 + w * 7, -364 + w * 7 + 7) : DAYS.slice(-7),
  );
  const priorWeeks = Array.from({ length: 52 }, (_, w) => DAYS.slice(-728 + w * 7, -728 + w * 7 + 7));
  const weekPoint = (days: (typeof weeks)[number]): TrafficPoint => aggregate(days.map((d) => d.point));
  const year = (ws: typeof weeks) => {
    const t = aggregate(ws.flat().map((d) => d.point));
    return { ...t, visitors: t.visitors * YEAR_UNIQUE_RATIO };
  };
  const first = weeks[0][0].date;
  const last = weeks[51][weeks[51].length - 1].date;

  return {
    key,
    current: weeks.map(weekPoint),
    previous: priorWeeks.map(weekPoint),
    labels: weeks.map((w) => (w[0].date.getDate() <= 7 ? format(w[0].date, "MMM") : "")),
    tips: weeks.map((w) => `Week of ${dayLabel(w[0].date)}, ${w[0].date.getFullYear()}`),
    totals: year(weeks),
    priorTotals: year(priorWeeks),
    span: `${dayLabel(first)}, ${first.getFullYear()} – ${dayLabel(last)}, ${last.getFullYear()}`,
    interval: "Weekly",
    comparison: "vs. previous year",
  };
}

const cache = new Map<RangeKey, RangeData>();

export function getRange(key: RangeKey): RangeData {
  if (!cache.has(key)) cache.set(key, buildRange(key));
  return cache.get(key)!;
}

export function delta(current: number, prior: number, lowerIsBetter = false): Delta {
  const change = prior ? ((current - prior) / prior) * 100 : 0;
  return {
    text: `${Math.abs(change) < 10 ? Math.abs(change).toFixed(1) : Math.round(Math.abs(change))}%`,
    direction: change > 0 ? "up" : "down",
    good: lowerIsBetter ? change < 0 : change > 0,
  };
}

export const conversionRate = (t: Totals) => (t.conversions / t.visitors) * 100;

// ------------------------------------------------------------------ breakdowns, goals, funnel

/** Rows for one breakdown tab, varied deterministically per range and sorted by visitors. */
export function breakdownRows(dimension: DimensionKey, tabKey: string, range: RangeKey): BreakdownRow[] {
  const tab = DIMENSIONS[dimension].tabs.find((t) => t.key === tabKey)!;
  const total = getRange(range).totals.visitors;
  const rng = createRng(hashSeed(`${dimension}/${tabKey}/${range}`));
  const rows = tab.rows
    .map(({ name, share }) => {
      const [code, label] = name.includes("|") ? name.split("|") : [undefined, name];
      return { name: label, code, value: total * share * rng.uniform(0.9, 1.1) };
    })
    .sort((a, b) => b.value - a.value);
  const top = rows[0].value;
  return rows.map((r) => ({ ...r, share: (r.value / total) * 100, width: (r.value / top) * 100 }));
}

export function goalRows(range: RangeKey): GoalRow[] {
  const visitors = getRange(range).totals.visitors;
  const rng = createRng(range.length * 7 + 3);
  return GOALS.map((g) => {
    const uniques = visitors * g.rate * rng.uniform(0.92, 1.08);
    return {
      name: g.name,
      uniques,
      total: uniques * g.perVisitor,
      conversionRate: (uniques / visitors) * 100,
      // ~5% of buyers place a second order in the same period
      revenue: g.tracksRevenue ? uniques * 1.05 * AVERAGE_ORDER : null,
    };
  });
}

export function funnelSteps(range: RangeKey): FunnelStep[] {
  const visitors = getRange(range).totals.visitors;
  const values = CHECKOUT_FUNNEL.map((s) => visitors * s.share);
  return CHECKOUT_FUNNEL.map((s, i) => ({
    name: s.name,
    value: values[i],
    ofFirst: (values[i] / values[0]) * 100,
    dropOff: i === 0 ? null : (1 - values[i] / values[i - 1]) * 100,
  }));
}
