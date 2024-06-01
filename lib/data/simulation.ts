/**
 * Seeded traffic model for the demo site, harrowfield.co (Harrowfield Supply, a fictional handmade
 * ceramics store). 760 days ending yesterday, plus today's hours up to the current hour.
 */
import { addDays, getDayOfYear } from "date-fns";

import { createRng } from "@/lib/random";
import type { TrafficPoint } from "@/types/analytics";

export const SITE = {
  domain: "harrowfield.co",
  name: "Harrowfield Supply",
  initial: "H",
  description: "Handmade ceramics store · Timezone America/Los_Angeles · All visitors",
  currentVisitors: 38,
} as const;

export const TODAY = new Date(2026, 8, 25);
/** Local time of the snapshot: 2:40 pm. */
export const NOW = { hour: 14, minute: 40 } as const;
export const DAY_COUNT = 760;
/** Average order value used for revenue goals. */
export const AVERAGE_ORDER = 64.2;

/** Day-of-week multipliers, Monday first. */
const WEEKDAY = [1.0, 1.05, 1.03, 0.99, 0.93, 0.76, 0.81];

/** Launches, newsletters and sales: multipliers on the day's visitors. */
const SPIKES = new Map<string, number>([
  ["2024-11-29", 2.1],
  ["2024-12-02", 1.6],
  ["2025-11-28", 2.4],
  ["2025-11-29", 1.7],
  ["2025-12-01", 1.9],
  ["2025-12-02", 1.3],
  ["2026-02-10", 1.45],
  ["2026-05-06", 1.6],
  ["2026-05-07", 1.25],
  ["2026-09-16", 1.7],
  ["2026-09-17", 1.3],
]);

/** Relative traffic by hour of day (local time). */
const HOUR_SHAPE = [
  0.18, 0.12, 0.08, 0.06, 0.06, 0.09, 0.2, 0.38, 0.55, 0.7, 0.8, 0.86, 0.92, 0.95, 0.94, 0.9, 0.88, 0.9, 1.0,
  1.08, 1.12, 1.02, 0.74, 0.4,
];

const rng = createRng(11);
const key = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
export const weekdayIndex = (d: Date) => (d.getDay() + 6) % 7;

export interface DayTraffic {
  date: Date;
  point: TrafficPoint;
}

function dayPoint(i: number, date: Date): TrafficPoint {
  const t = i / DAY_COUNT;
  const base = 520 + 1180 * t ** 1.15;
  let season = 1 + 0.09 * Math.sin((getDayOfYear(date) / 365) * 2 * Math.PI + 1.1);
  if (date.getMonth() === 11 && date.getDate() > 12) season *= 1.18; // holiday gifting
  const spike = SPIKES.get(key(date)) ?? 1;
  const visitors = base * WEEKDAY[weekdayIndex(date)] * season * rng.uniform(0.9, 1.1) * spike;
  const visits = visitors * rng.uniform(1.15, 1.22);
  const conversionRate = rng.uniform(2.3, 3.2) * (spike > 1.5 ? 1.35 : 1);
  return {
    visitors,
    visits,
    pageviews: visits * rng.uniform(2.55, 3.1),
    bounce: rng.uniform(37, 45) - (spike > 1 ? 3 : 0),
    duration: rng.uniform(128, 176),
    conversions: (visitors * conversionRate) / 100,
  };
}

export const DAYS: readonly DayTraffic[] = Array.from({ length: DAY_COUNT }, (_, i) => {
  const date = addDays(TODAY, -(DAY_COUNT - i));
  return { date, point: dayPoint(i, date) };
});

function hourly(dayVisitors: number): TrafficPoint[] {
  const shapeTotal = HOUR_SHAPE.reduce((a, b) => a + b, 0);
  return HOUR_SHAPE.map((h) => {
    const visitors = ((dayVisitors * h) / shapeTotal) * rng.uniform(0.85, 1.15);
    return {
      visitors,
      visits: visitors * rng.uniform(1.12, 1.2),
      pageviews: visitors * rng.uniform(3.0, 3.6),
      bounce: rng.uniform(35, 48),
      duration: rng.uniform(115, 190),
      conversions: (visitors * rng.uniform(1.8, 3.6)) / 100,
    };
  });
}

/** Today's hours so far, and all of yesterday's hours for comparison. */
export const TODAY_HOURS: readonly TrafficPoint[] = hourly(1780 * WEEKDAY[weekdayIndex(TODAY)]).slice(
  0,
  NOW.hour + 1,
);
export const YESTERDAY_HOURS: readonly TrafficPoint[] = hourly(DAYS[DAYS.length - 1].point.visitors);
