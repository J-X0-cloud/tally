import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";

import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://tallystats.com"),
  title: {
    default: "Tally · Simple, cookie-free web analytics",
    template: "%s · Tally analytics",
  },
  description:
    "Tally is privacy-first web analytics: live visitors, sources, pages, goals and funnels on one page, with a 1.9 KB script and no cookies.",
  icons: { icon: { url: "/favicon.svg", type: "image/svg+xml" } },
};

export const viewport: Viewport = {
  themeColor: "#E4572E",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
