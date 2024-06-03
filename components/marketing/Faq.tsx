import type { FaqItem } from "@/types/content";

export function Faq({ items }: { items: FaqItem[] }) {
  return (
    <div className="faq">
      {items.map((item, i) => (
        <details key={item.q} open={i === 0}>
          <summary>{item.q}</summary>
          <p>
            {item.a}
            {item.link ? (
              <>
                {" "}
                <a href={item.link.href} style={{ color: "var(--brand6)", fontWeight: 600 }}>
                  {item.link.label}
                </a>
                {item.link.after}
              </>
            ) : null}
          </p>
        </details>
      ))}
    </div>
  );
}
