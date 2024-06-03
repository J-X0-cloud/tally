import clsx from "clsx";

import { formatMetric } from "@/lib/format";
import { METRICS } from "@/lib/data/metrics";
import { conversionRate, delta, getRange } from "@/lib/metrics";
import type { MetricKey, RangeKey } from "@/types/analytics";

interface KpiRowProps {
  range: RangeKey;
  active: MetricKey;
  /** When set, tiles are buttons that switch the chart metric. */
  onSelect?: (metric: MetricKey) => void;
}

export function KpiRow({ range, active, onSelect }: KpiRowProps) {
  const { totals, priorTotals } = getRange(range);

  return (
    <div className="kpis">
      {METRICS.map((m) => {
        const d = delta(totals[m.key], priorTotals[m.key], m.lowerIsBetter);
        const body = (
          <>
            <span className="kl">{m.label}</span>
            <b>{formatMetric(totals[m.key], m.format)}</b>
            <span className="kd">
              <span className={`dl ${d.good ? "up" : "dn"}`}>
                {d.direction === "up" ? "↑" : "↓"} {d.text}
              </span>
              {m.key === "conversions" ? (
                <small className="sub">{conversionRate(totals).toFixed(1)}% CR</small>
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
