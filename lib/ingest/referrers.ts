/** Referrer and UTM classification into the source and channel shown in the Top sources panel. */
export type Channel =
  | "Organic Search"
  | "Paid Search"
  | "Organic Social"
  | "Email"
  | "AI Assistants"
  | "Referral"
  | "Direct";

const SOURCES: Array<{ pattern: RegExp; source: string; channel: Channel }> = [
  { pattern: /(^|\.)google\./, source: "Google", channel: "Organic Search" },
  { pattern: /(^|\.)bing\.com$/, source: "Bing", channel: "Organic Search" },
  { pattern: /(^|\.)duckduckgo\.com$/, source: "DuckDuckGo", channel: "Organic Search" },
  { pattern: /(^|\.)(chatgpt\.com|chat\.openai\.com)$/, source: "ChatGPT", channel: "AI Assistants" },
  { pattern: /(^|\.)perplexity\.ai$/, source: "Perplexity", channel: "AI Assistants" },
  { pattern: /(^|\.)(instagram\.com|l\.instagram\.com)$/, source: "Instagram", channel: "Organic Social" },
  { pattern: /(^|\.)pinterest\./, source: "Pinterest", channel: "Organic Social" },
  { pattern: /(^|\.)(facebook\.com|fb\.me)$/, source: "Facebook", channel: "Organic Social" },
  { pattern: /(^|\.)reddit\.com$/, source: "Reddit", channel: "Organic Social" },
];

export interface Attribution {
  source: string;
  channel: Channel;
  utm: Partial<Record<"source" | "medium" | "campaign" | "term" | "content", string>>;
}

export function attribute(pageUrl: URL, referrer: string | null): Attribution {
  const utm: Attribution["utm"] = {};
  for (const key of ["source", "medium", "campaign", "term", "content"] as const) {
    const v = pageUrl.searchParams.get(`utm_${key}`);
    if (v) utm[key] = v.slice(0, 100);
  }

  const medium = utm.medium?.toLowerCase();
  if (medium === "email" || medium === "newsletter")
    return { source: utm.source ?? "Newsletter", channel: "Email", utm };
  if (medium === "cpc" || medium === "ppc" || medium === "paid")
    return { source: utm.source ?? "Paid", channel: "Paid Search", utm };

  let host: string | null = null;
  try {
    host = referrer ? new URL(referrer).hostname.replace(/^www\./, "") : null;
  } catch {
    host = null;
  }
  // Internal navigation isn't a new source.
  if (!host || host === pageUrl.hostname.replace(/^www\./, "")) {
    return utm.source
      ? { source: utm.source, channel: "Referral", utm }
      : { source: "Direct / None", channel: "Direct", utm };
  }
  const known = SOURCES.find((s) => s.pattern.test(host!));
  return known
    ? { source: known.source, channel: known.channel, utm }
    : { source: host, channel: "Referral", utm };
}
