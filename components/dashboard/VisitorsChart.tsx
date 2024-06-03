"use client";

import { useId, useLayoutEffect, useRef, useState } from "react";
import type { PointerEvent } from "react";

import { PLOT_H, PLOT_W, gridValues, seriesPaths, xLabelIndices, xLabelStyle, yDomain } from "@/lib/charts";
import { formatAxis, formatMetric } from "@/lib/format";
import { metricDef } from "@/lib/data/metrics";
import { getRange } from "@/lib/metrics";
import type { MetricKey, RangeKey } from "@/types/analytics";

interface VisitorsChartProps {
  range: RangeKey;
  metric: MetricKey;
  /** Show the previous period in the tooltip (the dashed line is hidden by CSS when off). */
  compare?: boolean;
  interactive?: boolean;
}

const BRAND = "#E4572E";
const PREVIOUS = "#BFB4A9";

/** Current period as a filled line, previous period dashed, with a crosshair tooltip on hover. */
export function VisitorsChart({ range, metric, compare = true, interactive = true }: VisitorsChartProps) {
  const gradientId = `ga${useId().replace(/:/g, "")}`;
  const plotRef = useRef<HTMLDivElement>(null);
  const tipRef = useRef<HTMLDivElement>(null);
  const [hover, setHover] = useState<{ i: number; width: number } | null>(null);

  const data = getRange(range);
  const def = metricDef(metric);
  const cur = data.current.map((p) => (p ? p[metric] : null));
  const prev = data.previous.map((p) => p[metric]);
  const n = prev.length;
  const domain = yDomain([...cur.filter((v): v is number => v !== null), ...prev], def.format);
  const [lo, hi] = domain;
  const current = seriesPaths(cur, n, domain);
  const previous = seriesPaths(prev, n, domain);
  const pct = (i: number) => (i / (n - 1)) * 100;
  const heightPct = (v: number) => ((v - lo) / (hi - lo)) * 100;

  useLayoutEffect(() => {
    const tip = tipRef.current;
    if (!tip || !hover) return;
    const w = tip.offsetWidth || 180;
    const px = (pct(hover.i) / 100) * hover.width;
    tip.style.left = `${Math.max(0, Math.min(hover.width - w, px + (px > hover.width / 2 ? -w - 14 : 14)))}px`;
  });

  function onPointerMove(e: PointerEvent<HTMLDivElement>) {
    const r = plotRef.current!.getBoundingClientRect();
    const i = Math.max(0, Math.min(n - 1, Math.round(((e.clientX - r.left) / r.width) * (n - 1))));
    setHover({ i, width: r.width });
  }

  const hovered = hover ? { c: cur[hover.i], p: prev[hover.i], x: pct(hover.i) } : null;

  return (
    <div className="ch">
      <div
        className="ch-plot"
        ref={plotRef}
        onPointerMove={interactive ? onPointerMove : undefined}
        onPointerLeave={interactive ? () => setHover(null) : undefined}
      >
        <div className="yg">
          {gridValues(domain).map((v, g) => (
            <span key={g} style={{ bottom: `${g * 25}%` }}>
              <em>{formatAxis(v, def.format)}</em>
            </span>
          ))}
        </div>
        <svg
          viewBox={`0 0 ${PLOT_W} ${PLOT_H}`}
          preserveAspectRatio="none"
          role="img"
          aria-label={`${def.label} chart, ${data.span}`}
        >
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor={BRAND} stopOpacity={0.22} />
              <stop offset="1" stopColor={BRAND} stopOpacity={0} />
            </linearGradient>
          </defs>
          <path className="a" d={current.area} fill={`url(#${gradientId})`} />
          <path className="pv" d={previous.line} />
          <path className="ln" d={current.line} />
        </svg>
        {range === "today" ? (
          <i
            className="nowdot"
            style={{
              left: `${pct(current.lastIndex).toFixed(2)}%`,
              bottom: `${heightPct(cur[current.lastIndex]!).toFixed(2)}%`,
            }}
          />
        ) : null}
        {interactive ? (
          <div className={hovered ? "hv on" : "hv"}>
            {hovered ? (
              <>
                <i className="vl" style={{ left: `${hovered.x}%` }} />
                {hovered.c !== null ? (
                  <i className="hd" style={{ left: `${hovered.x}%`, bottom: `${heightPct(hovered.c)}%` }} />
                ) : null}
                <div className="tt" ref={tipRef}>
                  <strong>{data.tips[hover!.i]}</strong>
                  <div>
                    <span>
                      <i style={{ background: BRAND }} />
                      {def.label}
                    </span>
                    <b>{hovered.c === null ? "–" : formatMetric(hovered.c, def.format, true)}</b>
                  </div>
                  {compare ? (
                    <div>
                      <span>
                        <i style={{ background: PREVIOUS }} />
                        Previous
                      </span>
                      <b>{formatMetric(hovered.p, def.format, true)}</b>
                    </div>
                  ) : null}
                </div>
              </>
            ) : null}
          </div>
        ) : null}
      </div>
      <div className="xl">
        {xLabelIndices(range, data.labels).map((i) => (
          <span key={i} style={xLabelStyle(i, n)}>
            {data.labels[i]}
          </span>
        ))}
      </div>
    </div>
  );
}
