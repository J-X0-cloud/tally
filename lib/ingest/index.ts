import { memorySaltStore } from "./salts";
import { batchingSink } from "./sink";

export { attribute } from "./referrers";
export { isBot, screenClass, userAgentInfo } from "./devices";
export { clientIp, countryFromHeaders } from "./geo";
export { visitorId } from "./visitor";
export type { StoredEvent } from "./sink";

/** Process-wide salt store and event sink used by the ingest route. */
export const salts = memorySaltStore();

/**
 * Events are written as NDJSON to stdout, where the platform log drain ships them to the analytics
 * store in the configured region. Each line is one event with no personal data.
 */
export const sink = batchingSink(async (events) => {
  process.stdout.write(events.map((e) => JSON.stringify(e)).join("\n") + "\n");
});

/** Sites this deployment accepts events for, from TALLY_SITES. */
export function allowedSites(): Set<string> {
  return new Set(
    (process.env.TALLY_SITES ?? "")
      .split(",")
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean),
  );
}
