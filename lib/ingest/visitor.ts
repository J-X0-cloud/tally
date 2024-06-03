import { createHash } from "node:crypto";

import type { SaltStore } from "./salts";
import { utcDay } from "./salts";

/**
 * Anonymous visitor id for one site on one day: sha256(daily salt + site + ip + user agent), truncated.
 * The IP is used here and for the country lookup only; it is never stored.
 */
export async function visitorId(
  store: SaltStore,
  site: string,
  ip: string,
  userAgent: string,
  now = new Date(),
): Promise<string> {
  const salt = await store.saltFor(utcDay(now));
  return createHash("sha256")
    .update(salt)
    .update(site)
    .update(ip)
    .update(userAgent)
    .digest("hex")
    .slice(0, 16);
}
