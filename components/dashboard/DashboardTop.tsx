import clsx from "clsx";

import { Icon } from "@/components/ui/Icon";
import { SITE } from "@/lib/data/simulation";
import { RANGE_OPTIONS, getRange } from "@/lib/metrics";
import type { RangeKey } from "@/types/analytics";

interface DashboardTopProps {
  range: RangeKey;
  /** Omit for the static hero preview. */
  onRangeChange?: (range: RangeKey) => void;
}

/** Site switcher, live visitor count, filter button and date range. */
export function DashboardTop({ range, onRangeChange }: DashboardTopProps) {
  return (
    <div className="dtop">
      <div className="site">
        <i className="fav">{SITE.initial}</i>
        <b>{SITE.domain}</b>
        <Icon name="chev" size={14} />
      </div>
      <span className="livep">
        <i />
        <b>{SITE.currentVisitors}</b> current visitors
      </span>
      <span className="sp" />
      <button type="button" className="fbtn">
        <Icon name="filter" size={15} />
        Filter
      </button>
      <div className="rng">
        <span className="rlab">
          <Icon name="cal" size={14} />
          <span>{getRange(range).span}</span>
        </span>
        <div className="seg" role="group" aria-label="Date range">
          {RANGE_OPTIONS.map((o) => (
            <button
              key={o.key}
              type="button"
              className={clsx(o.key === range && "on")}
              aria-pressed={o.key === range}
              onClick={onRangeChange ? () => onRangeChange(o.key) : undefined}
            >
              {o.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
