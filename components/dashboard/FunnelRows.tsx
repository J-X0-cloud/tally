import { compact } from "@/lib/format";
import { funnelSteps } from "@/lib/metrics";
import type { RangeKey } from "@/types/analytics";

export function FunnelRows({ range }: { range: RangeKey }) {
  return (
    <div className="fn">
      {funnelSteps(range).map((step, i) => (
        <div key={step.name} className="fr">
          <div className="fl">
            <span className="fi">{i + 1}</span>
            <span>{step.name}</span>
            {step.dropOff !== null ? <em>−{step.dropOff.toFixed(0)}% drop-off</em> : null}
          </div>
          <div className="fb">
            <span style={{ width: `${Math.max(step.ofFirst, 2).toFixed(1)}%` }} />
          </div>
          <div className="fv">
            <b>{compact(step.value)}</b>
            <small>{step.ofFirst.toFixed(1)}%</small>
          </div>
        </div>
      ))}
    </div>
  );
}
