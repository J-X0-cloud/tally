import type { DemoDashboard } from "@/types/analytics";

import { BreakdownPanel } from "./BreakdownPanel";
import { DashboardTop } from "./DashboardTop";
import { KpiRow } from "./KpiRow";
import { VisitorsChart } from "./VisitorsChart";

/** Non-interactive dashboard for the default range, used as the home page hero visual. */
export function DashboardPreview({ dashboard }: { dashboard: DemoDashboard }) {
  const data = dashboard.data[dashboard.defaultRange];
  const metric = dashboard.metrics.find((m) => m.key === dashboard.defaultMetric)!;
  const dimension = (key: string) => dashboard.dimensions.find((d) => d.key === key)!;

  return (
    <div className="dash dash-static">
      <DashboardTop site={dashboard.site} ranges={dashboard.ranges} data={data} />
      <KpiRow metrics={dashboard.metrics} data={data} active={metric.key} />
      <div className="card chc">
        <div className="chh">
          <b>{metric.label}</b>
          <span className="lg">
            <i className="c1" />
            This period
            <i className="c2" />
            Previous
          </span>
          <span className="int">{data.interval}</span>
        </div>
        <VisitorsChart data={data} metric={metric} interactive={false} />
      </div>
      <div className="grid2">
        <BreakdownPanel dimension={dimension("sources")} rows={data.breakdowns.sources} interactive={false} />
        <BreakdownPanel dimension={dimension("pages")} rows={data.breakdowns.pages} interactive={false} />
      </div>
    </div>
  );
}
