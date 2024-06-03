import { Fragment } from "react";

import { Icon } from "@/components/ui/Icon";
import { full } from "@/lib/format";
import { SEGMENT_FILTERS, SEGMENT_MATCHES } from "@/lib/data/tour";

export function SegmentBuilder() {
  return (
    <div className="fbuild">
      {SEGMENT_FILTERS.map((f, i) => (
        <Fragment key={f.field}>
          {i > 0 ? <span className="fand">AND</span> : null}
          <div className="frow">
            <span className="fsel">
              {f.field} <Icon name="chev" size={13} />
            </span>
            <span className="fsel">
              {f.operator} <Icon name="chev" size={13} />
            </span>
            <span className={f.mono ? "fsel mono" : "fsel"}>
              {f.value} {f.chevron ? <Icon name="chev" size={13} /> : null}
            </span>
          </div>
        </Fragment>
      ))}
      <div className="frow" style={{ marginTop: 6, justifyContent: "space-between" }}>
        <span className="muted" style={{ fontSize: 13 }}>
          Matches {full(SEGMENT_MATCHES)} visitors in the last 30 days
        </span>
        <span className="btn btn-p btn-sm">Save segment</span>
      </div>
    </div>
  );
}
