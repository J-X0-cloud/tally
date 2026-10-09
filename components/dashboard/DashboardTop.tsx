import clsx from "clsx";

import { Icon } from "@/components/ui/Icon";
import type { RangeData, RangeKey, SiteInfo } from "@/types/analytics";

interface DashboardTopProps {
  site: SiteInfo;
  ranges: Array<{ key: RangeKey; label: string }>;
  /** The selected range's data. */
  data: RangeData;
  /** Omit for the static hero preview. */
  onRangeChange?: (range: RangeKey) => void;
}

/** Site switcher, live visitor count, filter button and date range. */
export function DashboardTop({ site, ranges, data, onRangeChange }: DashboardTopProps) {
  const range = data.key;
  return (
    <div className="dtop">
      <div className="site">
        <i className="fav">{site.initial}</i>
        <b>{site.domain}</b>
        <Icon name="chev" size={14} />
      </div>
      <span className="livep">
        <i />
        <b>{site.currentVisitors}</b> current visitors
      </span>
      <span className="sp" />
      <button type="button" className="fbtn">
        <Icon name="filter" size={15} />
        Filter
      </button>
      <div className="rng">
        <span className="rlab">
          <Icon name="cal" size={14} />
          <span>{data.span}</span>
        </span>
        <div className="seg" role="group" aria-label="Date range">
          {ranges.map((o) => (
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
