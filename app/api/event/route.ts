import { z } from "zod";

import {
  allowedSites,
  attribute,
  clientIp,
  countryFromHeaders,
  isBot,
  salts,
  screenClass,
  sink,
  userAgentInfo,
  visitorId,
} from "@/lib/ingest";

export const runtime = "nodejs";

/** Matches the TrackPayload wire format sent by script/tally.ts. */
const PayloadSchema = z.object({
  n: z.string().trim().min(1).max(120),
  u: z.url().max(2048),
  r: z.string().max(2048).nullable(),
  w: z.number().int().min(0).max(10_000),
  d: z.string().trim().toLowerCase().min(3).max(253),
  p: z.record(z.string().max(64), z.union([z.string().max(256), z.number(), z.boolean()])).optional(),
  $: z.object({ amount: z.number().nonnegative(), currency: z.string().length(3).toUpperCase() }).optional(),
});

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-allow-headers": "content-type",
  "access-control-max-age": "86400",
};

const accepted = () => new Response(null, { status: 202, headers: CORS });

export function OPTIONS() {
  return new Response(null, { status: 204, headers: CORS });
}

/**
 * POST /api/event — ingest one pageview or custom event.
 *
 * The body arrives as text/plain (sendBeacon) and is parsed here. Bots and unknown sites are dropped
 * silently with the same 202 so the script never retries or leaks configuration.
 */
export async function POST(request: Request) {
  let json: unknown;
  try {
    json = JSON.parse(await request.text());
  } catch {
    return Response.json({ error: "invalid_json" }, { status: 400, headers: CORS });
  }

  const parsed = PayloadSchema.safeParse(json);
  if (!parsed.success) {
    return Response.json(
      { error: "invalid_payload", issues: z.flattenError(parsed.error).fieldErrors },
      { status: 400, headers: CORS },
    );
  }

  const event = parsed.data;
  const ua = request.headers.get("user-agent") ?? "";
  if (isBot(ua) || !allowedSites().has(event.d)) return accepted();

  const url = new URL(event.u);
  const now = new Date();
  const { source, channel, utm } = attribute(url, event.r);

  await sink.write({
    site: event.d,
    name: event.n,
    timestamp: now.toISOString(),
    visitorId: await visitorId(salts, event.d, clientIp(request.headers), ua, now),
    path: url.pathname,
    source,
    channel,
    utm,
    country: countryFromHeaders(request.headers),
    screen: screenClass(event.w),
    ...userAgentInfo(ua),
    props: event.p ?? {},
    revenue: event.$ ?? null,
  });

  return accepted();
}
