import type { ReactNode } from "react";

/** Persimmon call-to-action band with a heading, copy and buttons. */
export function CtaBox({ title, body, children }: { title: string; body: string; children: ReactNode }) {
  return (
    <div className="cta">
      <div>
        <h2>{title}</h2>
        <p>{body}</p>
      </div>
      <div className="row">{children}</div>
    </div>
  );
}
