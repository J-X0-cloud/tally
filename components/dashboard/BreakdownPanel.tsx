"use client";

import clsx from "clsx";
import { useState } from "react";

import { Icon } from "@/components/ui/Icon";
import { compact } from "@/lib/format";
import { DEFAULT_SOURCE_COLOR, DIMENSIONS, SOURCE_COLORS } from "@/lib/data/dimensions";
import { breakdownRows } from "@/lib/metrics";
import type { BreakdownRow, BreakdownTab, DimensionKey, RangeKey } from "@/types/analytics";

interface BreakdownPanelProps {
  dimension: DimensionKey;
  range: RangeKey;
  /** Static previews show the first tab only and ignore clicks. */
  interactive?: boolean;
  className?: string;
}

function Chip({ tab, row }: { tab: BreakdownTab; row: BreakdownRow }) {
  if (tab.chip === "source") {
    return (
      <i className="sc" style={{ background: SOURCE_COLORS[row.name] ?? DEFAULT_SOURCE_COLOR }}>
        {row.name[0]}
      </i>
    );
  }
  if (tab.chip === "country" && row.code) return <i className="cc">{row.code}</i>;
  return null;
}

/** Ranked list with in-row bars and per-panel tabs (e.g. Channels / Sources / Campaigns). */
export function BreakdownPanel({ dimension, range, interactive = true, className }: BreakdownPanelProps) {
  const dim = DIMENSIONS[dimension];
  const [tabKey, setTabKey] = useState(dim.tabs[0].key);
  const tab = dim.tabs.find((t) => t.key === tabKey)!;
  const rows = breakdownRows(dimension, tab.key, range);

  return (
    <section className={clsx("panel", className)}>
      <header>
        <h3>{dim.title}</h3>
        <nav className="ptabs">
          {dim.tabs.map((t) => (
            <button
              key={t.key}
              type="button"
              className={t.key === tab.key ? "on" : undefined}
              aria-pressed={t.key === tab.key}
              onClick={interactive ? () => setTabKey(t.key) : undefined}
            >
              {t.label}
            </button>
          ))}
        </nav>
      </header>
      <div className="th">
        <span>{tab.heading}</span>
        <span>{dim.column}</span>
      </div>
      <ol className="bars">
        {rows.map((row) => (
          <li key={row.name}>
            <span className="bf" style={{ width: `${row.width.toFixed(1)}%` }} />
            <span className={clsx("nm", tab.mono && "mono")}>
              <Chip tab={tab} row={row} />
              <span>{row.name}</span>
            </span>
            <b>{compact(row.value)}</b>
            <small>{row.share.toFixed(0)}%</small>
          </li>
        ))}
      </ol>
      <footer>
        <a href="#">
          View details <Icon name="arrow" size={13} />
        </a>
      </footer>
    </section>
  );
}
