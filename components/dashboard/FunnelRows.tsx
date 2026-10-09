import { compact } from "@/lib/format";
import type { FunnelStep } from "@/types/analytics";

export function FunnelRows({ steps }: { steps: FunnelStep[] }) {
  return (
    <div className="fn">
      {steps.map((step, i) => (
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
