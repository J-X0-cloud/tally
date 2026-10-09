# Tally

Privacy-first, cookie-free web analytics: live visitors, sources, pages, goals and funnels from a 1.9 KB script.

**Live demo:** https://www.freelancerportfoliohub.com/jameslee/projects/tallystats/index.html

![Preview](docs/preview.webp)

## Overview

Tally shows a site owner where visitors came from, what they read and what they bought, on one page, without
cookies, consent banners or a reporting manual. Unique visitors are counted server-side with a hash that rotates
every 24 hours; IP addresses are used for a country lookup and the hash, then discarded.

This repository has two parts:

- **The collector** (`collector/`, Elixir and Phoenix) ingests events from the tracking script, aggregates them
  into stats, tracks live visitors and serves the demo dashboard and plan catalog over HTTP.
- **The site** (Next.js) is the marketing site (home, product tour, privacy and install, pricing), the working demo
  dashboard for Harrowfield Supply, a fictional ceramics store, and the tracking script. Pages fetch their data
  from the collector on the server.

## Features

- **Dashboard**: six KPI tiles that double as chart metric switches, a visitors chart with previous-period
  comparison, and Today / 7D / 30D / 12M ranges.
- **Breakdowns**: sources (channels, sources, campaigns), pages (top, entry, exit), locations and devices, each with
  its own tabs.
- **Goals and funnels**: goal conversions with revenue, and a checkout funnel with drop-off per step.
- **Tracking script** (`script/tally.ts`): one `defer` tag, SPA route changes, custom events with properties and
  revenue, `sendBeacon` delivery, no storage of any kind.
- **Ingest endpoint** (`POST /api/event`): validated payloads with per-field errors, bot filtering, referrer/UTM
  attribution into channels, screen-size classes, daily salted visitor hashes, batched writes and NDJSON output.
  No IP or user agent is stored, and the service sets no cookies.
- **Stats API** (`/api/v1/stats/:site`): totals with period comparison, timeseries, breakdowns, goals, funnels and
  realtime, with segment filters such as `source==Instagram|Pinterest;page==/products/*`. Keys are tied to a plan,
  which sets the hourly request allowance and unlocks funnels and custom properties.
- **Live visitors**: everyone active in the last five minutes, broadcast over Phoenix PubSub to a `live:<site>`
  channel, with Phoenix Presence tracking who is watching.
- **Hand-rolled charts**: SVG with non-scaling strokes and HTML axis labels, crisp from 1440px down to 390px.

## Tech stack

**Collector** (`collector/`)

- [Elixir](https://elixir-lang.org) and [Phoenix](https://www.phoenixframework.org) (JSON API, Channels, PubSub,
  Presence), served by Bandit
- ETS for the event store, daily salts, live visitors and rate-limit counters
- ExUnit for tests, including a parity test against the original TypeScript demo model
- Docker (multi-stage Phoenix release) for deployment

**Site**

- [Next.js 15](https://nextjs.org) (App Router) and React 19
- TypeScript (strict)
- [esbuild](https://esbuild.github.io) to bundle the tracking script
- Plain CSS (`app/globals.css`)

## Getting started

You need Elixir 1.18 with Erlang/OTP 27 for the collector, and Node 22 with pnpm for the site.

Start the collector:

```bash
cd collector
mix setup
mix phx.server
```

It listens on http://localhost:4000. In development the sites list is `harrowfield.co` and the Stats API accepts the
key `dev-key`.

In another terminal, start the site:

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

Send a test event (through the site's rewrite, or straight to the collector on port 4000):

```bash
curl -i localhost:3000/api/event \
  -H 'content-type: text/plain' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/605.1.15 Version/18.0 Safari/605.1.15' \
  -d '{"n":"pageview","u":"https://harrowfield.co/shop/mugs","r":"https://www.google.com/","w":1280,"d":"harrowfield.co"}'
```

Then read it back from the Stats API:

```bash
curl -H 'authorization: Bearer dev-key' 'localhost:4000/api/v1/stats/harrowfield.co/aggregate?period=day'
curl -H 'authorization: Bearer dev-key' 'localhost:4000/api/v1/stats/harrowfield.co/realtime'
```

### Tests

```bash
cd collector && mix test
pnpm typecheck && pnpm lint
```

### Environment variables

Site (`.env.example`):

| Variable  | Description                                                                         |
| --------- | ----------------------------------------------------------------------------------- |
| `API_URL` | Base URL of the collector. Read at request time, and at build time for the rewrites |

Collector (`collector/.env.example`):

| Variable               | Description                                                          |
| ---------------------- | -------------------------------------------------------------------- |
| `PORT`                 | HTTP port (default 4000)                                             |
| `TALLY_SITES`          | Comma-separated site domains the ingest endpoint accepts             |
| `TALLY_API_KEYS`       | Stats API keys as `key:plan` pairs (`starter`, `growth`, `business`) |
| `TALLY_RETENTION_DAYS` | Days of events kept in memory (default 400)                          |
| `SECRET_KEY_BASE`      | Optional; generated at boot when unset                               |
| `PHX_HOST`             | Public host name of the service                                      |

## Deploying

The collector ships with a `Dockerfile` that builds a release and listens on `$PORT`. On Railway, create one service
with its root directory set to `collector/` and another for the site at the repository root, then point the site's
`API_URL` at the collector (the private network URL works). The collector keeps events in memory, so stats start
fresh on each deploy; the NDJSON lines it writes to stdout are the durable record for a log drain.

## Project structure

```
collector/                Phoenix app (Elixir)
  lib/tally/
    ingest/               payload validation, attribution, devices and bots, geo, daily salts, visitor hash
    events/               event struct, batching buffer, ETS store, NDJSON log sink
    stats/                visits, metrics, periods, filters, breakdowns, goals, funnels, timeseries
    demo/                 seeded traffic model and dashboard report for the demo site
    billing/              plan catalog and quotes, API keys, rate limiter
    live.ex               live visitors with PubSub broadcasts
  lib/tally_web/          router, controllers, plugs, live channel and Presence
  priv/demo/              demo site seed data (JSON)
  priv/billing/           plan catalog (JSON)
  test/                   ExUnit tests
  Dockerfile
app/
  (marketing)/            home, product tour, privacy and pricing pages
  demo/                   live dashboard
  globals.css
components/
  dashboard/              DashboardShell, KpiRow, VisitorsChart, BreakdownPanel, GoalsTable, FunnelRows, sidebar
  marketing/              page sections (feature grid, privacy flow, install options, pricing, FAQ)
  site/                   header, footer, logo
  ui/                     icons, buttons, check lists, code blocks
lib/
  api.ts                  server-side client for the collector
  data/                   site copy, snippets, FAQs
  charts.ts               y domains, paths and label placement
  format.ts               number, duration and currency formatting
script/
  tally.ts                the tracking script
types/                    shared types (analytics, pricing, wire format, content)
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
| `mix phx.server`     | Start the collector (in `collector/`)     |
| `mix test`           | Run the collector's tests                 |
