import type { Metadata } from "next";

import { DashboardShell } from "@/components/dashboard/DashboardShell";

export const metadata: Metadata = {
  title: { absolute: "Live demo · Tally analytics dashboard" },
  description:
    "Explore a working Tally dashboard: switch date ranges and metrics, browse sources, pages, countries, devices, goals and a checkout funnel.",
};

export default function DemoPage() {
  return <DashboardShell />;
}
