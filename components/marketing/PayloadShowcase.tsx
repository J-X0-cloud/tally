import { CodeBlock } from "@/components/ui/CodeBlock";
import { DEVICE_STORAGE, PRIVACY_STATS } from "@/lib/data/privacy";
import { PAYLOAD_SNIPPET } from "@/lib/data/snippets";

const PILL_STYLE = { background: "#F1EBE3", color: "var(--ink2)" } as const;

/** Privacy hero visual: zero counters, the full request body and an empty device storage panel. */
export function PayloadShowcase() {
  return (
    <div className="ship">
      <div className="stat3">
        {PRIVACY_STATS.map((s) => (
          <div key={s.label}>
            <small>{s.label}</small>
            <b className={s.zero ? "z" : undefined}>{s.value}</b>
          </div>
        ))}
      </div>
      <CodeBlock snippet={PAYLOAD_SNIPPET} title="Network · POST /event" badge="202 Accepted" />
      <div className="card">
        <div className="hd2">
          <b>Storage on this device</b>
          <span className="tag g">Empty</span>
        </div>
        <div className="pills">
          {DEVICE_STORAGE.map((s) => (
            <span key={s} className="pill" style={PILL_STYLE}>
              {s}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
