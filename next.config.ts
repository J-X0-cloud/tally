import type { NextConfig } from "next";

/** The collector service (Elixir, collector/) that ingests events and serves the stats. */
const API_URL = (process.env.API_URL || "http://localhost:4000").replace(/\/+$/, "");

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  async rewrites() {
    // The tracking script's event endpoint, including first-party proxy paths, is forwarded to the
    // collector. Rewrites are resolved at build time, so API_URL must be set when running `next build`.
    return [
      { source: "/api/event", destination: `${API_URL}/api/event` },
      { source: "/event", destination: `${API_URL}/api/event` },
      { source: "/stats/event", destination: `${API_URL}/api/event` },
      { source: "/stats/t.js", destination: "/t.js" },
    ];
  },
  async headers() {
    return [
      {
        source: "/t.js",
        headers: [{ key: "cache-control", value: "public, max-age=86400, stale-while-revalidate=604800" }],
      },
    ];
  },
};

export default nextConfig;
