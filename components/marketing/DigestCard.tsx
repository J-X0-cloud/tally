import { compact } from "@/lib/format";
import { DIGEST } from "@/lib/data/tour";
import { getRange } from "@/lib/metrics";

/** The weekly email digest, filled from the last 7 days. */
export function DigestCard() {
  const { totals } = getRange("7d");
  const stats = [
    { label: "Visitors", value: totals.visitors },
    { label: "Pageviews", value: totals.pageviews },
    { label: "Purchases", value: totals.conversions },
  ];
  return (
    <div className="card mailc">
      <div className="mh">
        <b>{DIGEST.subject}</b>
        {DIGEST.meta}
      </div>
      <div className="mb">
        <div className="kv">
          {stats.map((s) => (
            <div key={s.label}>
              <small>{s.label}</small>
              <b>{compact(s.value)}</b>
            </div>
          ))}
        </div>
        <ul>
          <li>
            <span>Top source</span>
            <b>{DIGEST.topSource}</b>
          </li>
          <li>
            <span>Top page</span>
            <span className="mono" style={{ fontSize: 12.5 }}>
              {DIGEST.topPage}
            </span>
          </li>
          <li>
            <span>Biggest mover</span>
            <span className="tag o">{DIGEST.biggestMover}</span>
          </li>
        </ul>
      </div>
    </div>
  );
}
