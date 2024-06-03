import type { CSSProperties } from "react";

import { compact } from "@/lib/format";
import { funnelSteps } from "@/lib/metrics";

/** Column funnel: each step's bar height is its share of the first step; the hatched part is who left. */
export function StepFunnel() {
  return (
    <div className="bfn">
      {funnelSteps("30d").map((step, i) => {
        const h = Math.max(step.ofFirst, 4);
        const lost = 100 - step.ofFirst;
        return (
          <div key={step.name} className="bst">
            <small>Step {i + 1}</small>
            <h4>{step.name}</h4>
            <b>{compact(step.value)}</b>
            <div className="col">
              <span
                style={
                  {
                    height: `${h.toFixed(1)}%`,
                    "--lost": `${((lost / h) * 100).toFixed(0)}%`,
                  } as CSSProperties
                }
              />
            </div>
            <div className="dp">
              {step.dropOff === null ? (
                "Entry step"
              ) : (
                <>
                  <em>−{step.dropOff.toFixed(0)}%</em> from previous step
                </>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
