# Tally

Privacy-first, cookie-free web analytics: live visitors, sources, pages, goals and funnels from a 1.9 KB script.

**Live demo:** https://www.freelancerportfoliohub.com/jameslee/projects/tallystats/index.html

![Preview](docs/preview.webp)

## Overview

Tally shows a site owner where visitors came from, what they read and what they bought, on one page, without
cookies, consent banners or a reporting manual. Unique visitors are counted server-side with a hash that rotates
every 24 hours; IP addresses are used for a country lookup and the hash, then discarded.

This repository contains the marketing site (home, product tour, privacy and install, pricing), the working demo
dashboard for Harrowfield Supply, a fictional ceramics store, the tracking script, and the ingest endpoint it posts to.

## Features

- **Dashboard** — six KPI tiles that double as chart metric switches, a visitors chart with previous-period
  comparison, and Today / 7D / 30D / 12M ranges.
- **Breakdowns** — sources (channels, sources, campaigns), pages (top, entry, exit), locations and devices, each with
  its own tabs.
- **Goals and funnels** — goal conversions with revenue, and a checkout funnel with drop-off per step.
- **Tracking script** (`script/tally.ts`) — one `defer` tag, SPA route changes, custom events with properties and
  revenue, `sendBeacon` delivery, no storage of any kind.
- **Ingest endpoint** (`POST /api/event`) — zod-validated payloads, bot filtering, referrer/UTM attribution into
  channels, screen-size classes, daily salted visitor hashes and batched NDJSON output. No IP or user agent is stored.
- **Hand-rolled charts** — SVG with non-scaling strokes and HTML axis labels, crisp from 1440px down to 390px.

## Tech stack

- [Next.js 15](https://nextjs.org) (App Router) and React 19
- TypeScript (strict)
- [zod](https://zod.dev) for payload validation
- [esbuild](https://esbuild.github.io) to bundle the tracking script
- [date-fns](https://date-fns.org) for date labels
- Plain CSS (`app/globals.css`)

## Getting started

```bash
pnpm install
cp .env.example .env.local
pnpm dev
```

Open http://localhost:3000 for the site and http://localhost:3000/demo for the dashboard.

Build the tracking script to `public/t.js`:

```bash
pnpm build:tracker
```

Send a test event:

```bash
curl -i localhost:3000/api/event \
  -H 'content-type: text/plain' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/605.1.15 Version/18.0 Safari/605.1.15' \
  -d '{"n":"pageview","u":"https://harrowfield.co/shop/mugs","r":"https://www.google.com/","w":1280,"d":"harrowfield.co"}'
```

### Environment variables

| Variable      | Description                                              |
| ------------- | -------------------------------------------------------- |
| `TALLY_SITES` | Comma-separated site domains the ingest endpoint accepts |

## Project structure

```
app/
  (marketing)/        home, product tour, privacy and pricing pages
  demo/               live dashboard
  api/event/          ingest endpoint for the tracking script
  globals.css
components/
  dashboard/          DashboardShell, KpiRow, VisitorsChart, BreakdownPanel, GoalsTable, FunnelRows, sidebar
  marketing/          page sections (feature grid, privacy flow, install options, pricing, FAQ)
  site/               header, footer, logo
  ui/                 icons, buttons, check lists, code blocks
lib/
  data/               demo traffic model, dimensions, goals, site copy, snippets, pricing
  ingest/             attribution, devices and bots, geo, daily salts, visitor hash, event sink
  metrics.ts          ranges, totals, deltas, breakdowns, goals and funnel
  charts.ts           y domains, paths and label placement
script/
  tally.ts            the tracking script
types/                shared types (analytics, wire format, content)
```

## Scripts

| Script               | Description                               |
| -------------------- | ----------------------------------------- |
| `pnpm dev`           | Start the dev server with Turbopack       |
| `pnpm build`         | Bundle the tracker, then build the app    |
| `pnpm build:tracker` | Bundle `script/tally.ts` to `public/t.js` |
| `pnpm start`         | Serve the production build                |
| `pnpm lint`          | Lint with the Next.js ESLint config       |
| `pnpm typecheck`     | Type-check with `tsc --noEmit`            |
