import Link from "next/link";

import { Logo } from "@/components/site/Logo";
import { Icon } from "@/components/ui/Icon";
import type { IconName } from "@/components/ui/Icon";
import { SITE } from "@/lib/data/simulation";

const SITE_LINKS: Array<{ icon: IconName; label: string; badge?: number; active?: boolean }> = [
  { icon: "layers", label: "Dashboard", active: true },
  { icon: "live", label: "Realtime", badge: SITE.currentVisitors },
  { icon: "goal", label: "Goals" },
  { icon: "funnel", label: "Funnels" },
  { icon: "mail", label: "Reports" },
];

const WORKSPACE_LINKS: Array<{ icon: IconName; label: string; badge?: number }> = [
  { icon: "globe", label: "All sites", badge: 4 },
  { icon: "users", label: "Team" },
  { icon: "shield", label: "Settings" },
];

export function AppSidebar() {
  return (
    <aside className="aside">
      <Logo />
      <div className="grp">Site</div>
      {SITE_LINKS.map((l) =>
        l.active ? (
          <Link key={l.label} className="on" href="/demo" aria-current="page">
            <Icon name={l.icon} size={16} />
            {l.label}
          </Link>
        ) : (
          <a key={l.label} href="#">
            <Icon name={l.icon} size={16} />
            {l.label}
            {l.badge !== undefined ? <em>{l.badge}</em> : null}
          </a>
        ),
      )}
      <div className="grp">Workspace</div>
      {WORKSPACE_LINKS.map((l) => (
        <a key={l.label} href="#">
          <Icon name={l.icon} size={16} />
          {l.label}
          {l.badge !== undefined ? <em>{l.badge}</em> : null}
        </a>
      ))}
      <div className="foot">
        This is a demo with generated data for a fictional store. <Link href="/pricing">Start your own</Link>{" "}
        or <Link href="/">return to the site</Link>.
      </div>
    </aside>
  );
}

export function AppBar() {
  return (
    <div className="abar">
      <Logo className="logo mlogo" size={26} />
      <span className="crumbs">
        {SITE.name} / <b>Dashboard</b>
      </span>
      <span className="demo-tag">Live demo</span>
      <div className="row">
        <Link className="btn btn-g btn-sm" href="/">
          Back to site
        </Link>
        <Link className="btn btn-p btn-sm" href="/pricing">
          Start free trial
        </Link>
      </div>
    </div>
  );
}
