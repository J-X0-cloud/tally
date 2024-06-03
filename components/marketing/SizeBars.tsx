import { SCRIPT_SIZES } from "@/lib/data/site";

/** Script weight compared with typical setups. `dark` restyles the bars for the plum section. */
export function SizeBars({ dark = false }: { dark?: boolean }) {
  const muted = dark ? "#CDBFCA" : undefined;
  return (
    <div className="sz">
      {SCRIPT_SIZES.map((s) => (
        <div key={s.label} className={s.highlight ? "me" : undefined}>
          <span style={s.highlight ? undefined : { color: muted }}>{s.label}</span>
          <i style={{ width: `${s.width}%`, background: dark && !s.highlight ? "#5A4A5C" : undefined }} />
          <em style={dark ? { color: s.highlight ? "#fff" : muted } : undefined}>{s.size}</em>
        </div>
      ))}
    </div>
  );
}
