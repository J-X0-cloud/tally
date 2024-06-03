"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { ButtonLink } from "@/components/ui/ButtonLink";
import { Icon } from "@/components/ui/Icon";
import { NAV_LINKS } from "@/lib/data/site";

import { Logo } from "./Logo";

export function Header() {
  const pathname = usePathname();
  const links = NAV_LINKS.map((l) => (
    <Link
      key={l.href}
      href={l.href}
      className={pathname === l.href ? "on" : undefined}
      aria-current={pathname === l.href ? "page" : undefined}
    >
      {l.label}
    </Link>
  ));

  return (
    <header className="hdr">
      <div className="wrap">
        <Logo />
        <nav className="nav" aria-label="Main">
          {links}
        </nav>
        <div className="hcta">
          <a className="login" href="#">
            Log in
          </a>
          <ButtonLink href="/pricing" variant="p" small>
            Start free trial
          </ButtonLink>
        </div>
        <details className="mnav">
          <summary aria-label="Menu">
            <Icon name="menu" strokeWidth={2} />
          </summary>
          <div className="mp">
            {links}
            <a href="#">Log in</a>
            <ButtonLink href="/pricing" variant="p">
              Start free trial
            </ButtonLink>
          </div>
        </details>
      </div>
    </header>
  );
}
