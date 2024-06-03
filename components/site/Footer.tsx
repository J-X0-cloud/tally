import Link from "next/link";

import { FOOTER_COLUMNS, TAGLINE } from "@/lib/data/site";

import { Logo } from "./Logo";

export function Footer() {
  return (
    <footer className="foot">
      <div className="wrap">
        <div className="fcols">
          <div>
            <Logo />
            <p>{TAGLINE}</p>
          </div>
          {FOOTER_COLUMNS.map((col) => (
            <div key={col.title}>
              <h4>{col.title}</h4>
              {col.links.map((l) =>
                l.href.startsWith("/") ? (
                  <Link key={l.label} href={l.href}>
                    {l.label}
                  </Link>
                ) : (
                  <a key={l.label} href={l.href}>
                    {l.label}
                  </a>
                ),
              )}
            </div>
          ))}
        </div>
        <div className="fbot">
          <span>© 2026 Tally Analytics. All rights reserved.</span>
          <span>No cookies were set while you read this page.</span>
        </div>
      </div>
    </footer>
  );
}
