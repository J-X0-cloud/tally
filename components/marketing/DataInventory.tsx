import { Icon } from "@/components/ui/Icon";
import { COLLECTED, NEVER_COLLECTED } from "@/lib/data/privacy";

function Column({ kind, title, items }: { kind: "yes" | "no"; title: string; items: string[] }) {
  const icon = kind === "yes" ? "check" : "x";
  return (
    <div className={`card ${kind}`}>
      <h3>
        <Icon name={icon} size={20} strokeWidth={2.4} />
        {title}
      </h3>
      <ul>
        {items.map((item) => (
          <li key={item}>
            <Icon name={icon} size={16} strokeWidth={2.4} />
            <span>{item}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

export function DataInventory() {
  return (
    <div className="cmp">
      <Column kind="yes" title="Collected, in aggregate" items={COLLECTED} />
      <Column kind="no" title="Never collected or stored" items={NEVER_COLLECTED} />
    </div>
  );
}
