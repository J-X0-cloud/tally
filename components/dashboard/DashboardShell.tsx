"use client";

import clsx from "clsx";
import Link from "next/link";
import { useState } from "react";

import { metricDef } from "@/lib/data/metrics";
import { SITE } from "@/lib/data/simulation";
import { DEFAULT_METRIC, DEFAULT_RANGE, getRange } from "@/lib/metrics";
import type { MetricKey, RangeKey } from "@/types/analytics";

import { AppBar, AppSidebar } from "./AppSidebar";
import { BreakdownPanel } from "./BreakdownPanel";
import { DashboardTop } from "./DashboardTop";
import { FunnelRows } from "./FunnelRows";
import { GoalsTable } from "./GoalsTable";
import { KpiRow } from "./KpiRow";
import { VisitorsChart } from "./VisitorsChart";

/**
 * The live demo: one date range and one chart metric drive every panel; each breakdown panel keeps
 * its own tab. Comparison with the previous period can be switched off.
 */
export function DashboardShell() {
  const [range, setRange] = useState<RangeKey>(DEFAULT_RANGE);
  const [metric, setMetric] = useState<MetricKey>(DEFAULT_METRIC);
  const [compare, setCompare] = useState(true);
  const data = getRange(range);

  return (
    <div className="app">
      <AppSidebar />
      <div className="amain">
        <AppBar />
        <div className={clsx("dash", !compare && "nocmp")} id="dash">
          <div className="dh">
            <div>
              <h1>{SITE.name}</h1>
              <p>{SITE.description}</p>
            </div>
          </div>
          <DashboardTop range={range} onRangeChange={setRange} />
          <KpiRow range={range} active={metric} onSelect={setMetric} />
          <div className="card chc">
            <div className="chh">
              <b id="mname">{metricDef(metric).label}</b>
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
            <VisitorsChart range={range} metric={metric} compare={compare} />
          </div>
          <div className="grid2">
            <BreakdownPanel dimension="sources" range={range} />
            <BreakdownPanel dimension="pages" range={range} />
          </div>
          <div className="grid2">
            <BreakdownPanel dimension="locations" range={range} />
            <BreakdownPanel dimension="devices" range={range} />
          </div>
          <div className="grid3">
            <section className="panel">
              <header>
                <h3>Goal conversions</h3>
                <a className="int" style={{ fontSize: 12.5, color: "var(--muted)" }} href="#">
                  Manage goals
                </a>
              </header>
              <GoalsTable range={range} />
            </section>
            <section className="panel">
              <header>
                <h3>Checkout funnel</h3>
              </header>
              <p className="fsub">Product view → cart → checkout → purchase, same visit</p>
              <FunnelRows range={range} />
            </section>
          </div>
          <div className="dfoot">
            <span>Demo data is generated for a fictional store and refreshes when the page is rebuilt.</span>
            <span>
              Like what you see? <Link href="/pricing">Start a free trial</Link>
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
