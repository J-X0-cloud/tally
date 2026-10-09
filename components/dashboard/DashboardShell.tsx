"use client";

import clsx from "clsx";
import Link from "next/link";
import { useState } from "react";

import type { DemoDashboard, MetricKey, RangeKey } from "@/types/analytics";

import { AppBar, AppSidebar } from "./AppSidebar";
import { BreakdownPanel } from "./BreakdownPanel";
import { DashboardTop } from "./DashboardTop";
import { FunnelRows } from "./FunnelRows";
import { GoalsTable } from "./GoalsTable";
import { KpiRow } from "./KpiRow";
import { VisitorsChart } from "./VisitorsChart";

/**
 * The live demo: one date range and one chart metric drive every panel; each breakdown panel keeps
 * its own tab. Comparison with the previous period can be switched off. Every range arrives in one
 * response from the collector, so switching is instant.
 */
export function DashboardShell({ dashboard }: { dashboard: DemoDashboard }) {
  const [range, setRange] = useState<RangeKey>(dashboard.defaultRange);
  const [metric, setMetric] = useState<MetricKey>(dashboard.defaultMetric);
  const [compare, setCompare] = useState(true);
  const { site, metrics, dimensions } = dashboard;
  const data = dashboard.data[range];
  const metricDef = metrics.find((m) => m.key === metric)!;
  const dimension = (key: string) => dimensions.find((d) => d.key === key)!;

  return (
    <div className="app">
      <AppSidebar site={site} />
      <div className="amain">
        <AppBar site={site} />
        <div className={clsx("dash", !compare && "nocmp")} id="dash">
          <div className="dh">
            <div>
              <h1>{site.name}</h1>
              <p>{site.description}</p>
            </div>
          </div>
          <DashboardTop site={site} ranges={dashboard.ranges} data={data} onRangeChange={setRange} />
          <KpiRow metrics={metrics} data={data} active={metric} onSelect={setMetric} />
          <div className="card chc">
            <div className="chh">
              <b id="mname">{metricDef.label}</b>
              <span className="lg">
                <i className="c1" />
                This period
                <i className="c2" />
                <span>{data.comparison}</span>
              </span>
              <label className="cmpt">
                <input type="checkbox" checked={compare} onChange={(e) => setCompare(e.target.checked)} />
                Compare
              </label>
              <span className="int">{data.interval}</span>
            </div>
            <VisitorsChart data={data} metric={metricDef} compare={compare} />
          </div>
          <div className="grid2">
            <BreakdownPanel dimension={dimension("sources")} rows={data.breakdowns.sources} />
            <BreakdownPanel dimension={dimension("pages")} rows={data.breakdowns.pages} />
          </div>
          <div className="grid2">
            <BreakdownPanel dimension={dimension("locations")} rows={data.breakdowns.locations} />
            <BreakdownPanel dimension={dimension("devices")} rows={data.breakdowns.devices} />
          </div>
          <div className="grid3">
            <section className="panel">
              <header>
                <h3>Goal conversions</h3>
                <a className="int" style={{ fontSize: 12.5, color: "var(--muted)" }} href="#">
                  Manage goals
                </a>
              </header>
              <GoalsTable rows={data.goals} />
            </section>
            <section className="panel">
              <header>
                <h3>Checkout funnel</h3>
              </header>
              <p className="fsub">Product view → cart → checkout → purchase, same visit</p>
              <FunnelRows steps={data.funnel} />
            </section>
          </div>
          <div className="dfoot">
            <span>Demo data is generated for a fictional store by the Tally collector service.</span>
            <span>
              Like what you see? <Link href="/pricing">Start a free trial</Link>
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
