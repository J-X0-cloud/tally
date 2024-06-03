/**
 * Geometry for the visitors chart: a 1000×300 SVG stretched to its container (non-scaling strokes),
 * with HTML gridlines and labels so text stays crisp at any width.
 */
import type { MetricFormat } from "@/types/analytics";

export const PLOT_W = 1000;
export const PLOT_H = 300;

/** Smallest 1/2/2.5/5 × 10ⁿ step ≥ x. */
export function niceStep(x: number): number {
  const e = 10 ** Math.floor(Math.log10(x));
  return ([1, 2, 2.5, 5, 10].find((m) => m * e >= x) ?? 10) * e;
}

/**
 * Y domain with four equal gridline steps. Counts start at zero; rates and durations hug the data,
 * rounded to 5% or 30 seconds.
 */
export function yDomain(values: number[], format: MetricFormat): [number, number] {
  const max = Math.max(...values);
  if (format === "number") return [0, 4 * niceStep((max * 1.06) / 4)];
  const q = format === "percent" ? 5 : 30;
  const lo = Math.max(0, Math.floor((Math.min(...values) * 0.85) / q) * q);
  return [lo, lo + 4 * Math.ceil((max * 1.04 - lo) / 4 / q) * q];
}

export const gridValues = ([lo, hi]: [number, number]) =>
  Array.from({ length: 5 }, (_, g) => lo + ((hi - lo) * g) / 4);

export function point(i: number, v: number, n: number, [lo, hi]: [number, number]): [number, number] {
  return [(i / (n - 1)) * PLOT_W, PLOT_H - ((v - lo) / (hi - lo)) * PLOT_H];
}

/** Line through the non-null values, plus the closed area under it. */
export function seriesPaths(
  values: Array<number | null>,
  n: number,
  domain: [number, number],
): { line: string; area: string; lastIndex: number } {
  const pts = values.flatMap((v, i) => (v === null ? [] : [point(i, v, n, domain)]));
  const line = `M${pts.map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`).join(" L")}`;
  const lastIndex = values.reduce<number>((last, v, i) => (v === null ? last : i), 0);
  return {
    line,
    area: `${line} L${((lastIndex / (n - 1)) * PLOT_W).toFixed(1)},${PLOT_H} L0,${PLOT_H} Z`,
    lastIndex,
  };
}

/** Which x positions get a label, per range. */
export function xLabelIndices(range: "today" | "7d" | "30d" | "12m", labels: string[]): number[] {
  if (range === "12m") return labels.flatMap((l, i) => (l ? [i] : []));
  if (range === "today") return [0, 4, 8, 12, 16, 20];
  if (range === "7d") return labels.map((_, i) => i);
  return [1, 6, 11, 16, 21, 26];
}

/** Edge labels are pinned inside the plot instead of centred on their point. */
export function xLabelStyle(i: number, n: number): { left: string; transform?: string } {
  const x = (i / (n - 1)) * 100;
  return { left: `${x.toFixed(2)}%`, transform: x < 3 ? "none" : x > 97 ? "translateX(-100%)" : undefined };
}
