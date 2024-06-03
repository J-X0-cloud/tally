import type { MetricFormat } from "@/types/analytics";

/** 1,284 · 18.4k · 1.2M */
export function compact(n: number): string {
  const v = Math.round(n);
  if (v >= 1_000_000) return `${(v / 1e6).toFixed(1)}M`;
  if (v >= 10_000) return `${(v / 1000).toFixed(1)}k`;
  return v.toLocaleString("en-US");
}

export const full = (n: number) => Math.round(n).toLocaleString("en-US");

/** 2m 34s */
export function duration(seconds: number): string {
  const s = Math.round(seconds);
  return `${Math.floor(s / 60)}m ${String(s % 60).padStart(2, "0")}s`;
}

export function formatMetric(v: number, format: MetricFormat, fullNumber = false): string {
  if (format === "percent") return `${Math.round(v)}%`;
  if (format === "duration") return duration(v);
  return fullNumber ? full(v) : compact(v);
}

const short = (v: number) => String(Number(v.toPrecision(6)));

export function formatAxis(v: number, format: MetricFormat): string {
  if (format === "percent") return `${Math.round(v)}%`;
  if (format === "duration") return v ? `${short(Math.round((v / 60) * 10) / 10)}m` : "0";
  if (v >= 1000) return `${short(v / 1000)}k`;
  return short(v);
}

export const usd = (v: number) => `$${Math.round(v).toLocaleString("en-US")}`;
