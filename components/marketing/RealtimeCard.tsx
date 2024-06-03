import { SITE } from "@/lib/data/simulation";
import { LIVE_FEED, REALTIME_SPARK } from "@/lib/data/tour";

export function RealtimeCard() {
  return (
    <div className="card rt">
      <div className="big">
        <span>Current visitors</span>
        <b>{SITE.currentVisitors}</b>
        <span>+12 vs. 30 min ago</span>
        <div className="spark">
          {REALTIME_SPARK.map((h, i) => (
            <i key={i} style={{ height: `${h}%` }} />
          ))}
        </div>
      </div>
      <ul className="feed">
        {LIVE_FEED.map((e) => (
          <li key={e.ago}>
            <time>{e.ago} ago</time>
            <span className="p">{e.path}</span>
            <span className="t">
              <span className={e.path.includes("thank") ? "tag g" : "tag"}>{e.source}</span> · {e.country}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}
