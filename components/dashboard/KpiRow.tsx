import clsx from "clsx";

import { formatMetric } from "@/lib/format";
import type { MetricDefinition, MetricKey, RangeData } from "@/types/analytics";

interface KpiRowProps {
  metrics: MetricDefinition[];
  data: RangeData;
  active: MetricKey;
  /** When set, tiles are buttons that switch the chart metric. */
  onSelect?: (metric: MetricKey) => void;
}

export function KpiRow({ metrics, data, active, onSelect }: KpiRowProps) {
  const { totals, deltas, conversionRate } = data;

  return (
    <div className="kpis">
      {metrics.map((m) => {
        const d = deltas[m.key];
        const body = (
          <>
            <span className="kl">{m.label}</span>
            <b>{formatMetric(totals[m.key], m.format)}</b>
            <span className="kd">
              <span className={`dl ${d.good ? "up" : "dn"}`}>
                {d.direction === "up" ? "↑" : "↓"} {d.text}
              </span>
              {m.key === "conversions" ? (
                <small className="sub">{conversionRate.toFixed(1)}% CR</small>
              ) : null}
            </span>
          </>
        );
        const cls = clsx("kpi", m.key === active && "on");
        return onSelect ? (
          <button
            key={m.key}
            type="button"
            className={cls}
            aria-pressed={m.key === active}
            onClick={() => onSelect(m.key)}
          >
            {body}
          </button>
        ) : (
          <div key={m.key} className={cls}>
            {body}
          </div>
        );
      })}
    </div>
  );
}
