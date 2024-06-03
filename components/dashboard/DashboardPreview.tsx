import { DEFAULT_METRIC, DEFAULT_RANGE } from "@/lib/metrics";

import { BreakdownPanel } from "./BreakdownPanel";
import { DashboardTop } from "./DashboardTop";
import { KpiRow } from "./KpiRow";
import { VisitorsChart } from "./VisitorsChart";

/** Non-interactive 30-day dashboard used as the home page hero visual. */
export function DashboardPreview() {
  return (
    <div className="dash dash-static">
      <DashboardTop range={DEFAULT_RANGE} />
      <KpiRow range={DEFAULT_RANGE} active={DEFAULT_METRIC} />
      <div className="card chc">
        <div className="chh">
          <b>Unique visitors</b>
          <span className="lg">
            <i className="c1" />
            This period
            <i className="c2" />
            Previous
          </span>
          <span className="int">Daily</span>
        </div>
        <VisitorsChart range={DEFAULT_RANGE} metric={DEFAULT_METRIC} interactive={false} />
      </div>
      <div className="grid2">
        <BreakdownPanel dimension="sources" range={DEFAULT_RANGE} interactive={false} />
        <BreakdownPanel dimension="pages" range={DEFAULT_RANGE} interactive={false} />
      </div>
    </div>
  );
}
