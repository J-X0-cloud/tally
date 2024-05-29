import type { CheckItem } from "@/types/content";

import { Icon } from "./Icon";

/** Check-mark list; an optional bold lead-in precedes the text. */
export function CheckList({ items }: { items: CheckItem[] }) {
  return (
    <ul>
      {items.map((item) => (
        <li key={item.text}>
          <Icon name="check" size={18} strokeWidth={2.2} />
          <span>
            {item.lead ? <b>{item.lead}</b> : null}
            {item.lead ? " " : null}
            {item.text}
          </span>
        </li>
      ))}
    </ul>
  );
}
