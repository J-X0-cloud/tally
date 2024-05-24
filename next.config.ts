import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  async rewrites() {
    // api.tallystats.com/event and first-party proxies (/stats/event) both land on the ingest route.
    return [
      { source: "/event", destination: "/api/event" },
      { source: "/stats/event", destination: "/api/event" },
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
