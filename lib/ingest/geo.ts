/**
 * Country from the edge network's geo headers. The IP itself is only read for hashing and is never
 * persisted or logged.
 */
export function countryFromHeaders(headers: Headers): string | null {
  const code =
    headers.get("x-vercel-ip-country") ?? headers.get("cf-ipcountry") ?? headers.get("x-country-code");
  return code && /^[A-Z]{2}$/.test(code) && code !== "XX" ? code : null;
}

export function clientIp(headers: Headers): string {
  return headers.get("x-forwarded-for")?.split(",")[0].trim() ?? headers.get("x-real-ip") ?? "0.0.0.0";
}
