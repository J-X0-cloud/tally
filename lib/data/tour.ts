import type { CheckItem } from "@/types/content";

export const REALTIME_POINTS: CheckItem[] = [
  { lead: "Current visitors", text: "refreshed every few seconds, no reload." },
  { lead: "Live feed", text: "of page views and goal completions as they arrive." },
  { lead: "Launch mode", text: "for a full-screen view on the office TV." },
];

/** Visitors per minute over the last 30 minutes, as % of the peak minute. */
export const REALTIME_SPARK = [
  34, 41, 38, 52, 47, 44, 58, 61, 55, 49, 63, 70, 66, 58, 62, 74, 69, 72, 80, 76, 71, 83, 78, 88, 92, 85, 79,
  90, 86, 100,
];

export const LIVE_FEED = [
  { ago: "2s", path: "/products/speckled-stoneware-mug", source: "Instagram", country: "US" },
  { ago: "6s", path: "/cart", source: "Direct", country: "CA" },
  { ago: "11s", path: "/journal/how-we-glaze", source: "ChatGPT", country: "GB" },
  { ago: "19s", path: "/shop/planters", source: "Google", country: "US" },
  { ago: "24s", path: "/checkout/thank-you", source: "Newsletter", country: "US" },
  { ago: "31s", path: "/", source: "Pinterest", country: "AU" },
];

export const SOURCE_POINTS: CheckItem[] = [
  { lead: "Channels", text: "like organic search, email, social and AI assistants." },
  { lead: "UTM reports", text: "for source, medium, campaign, term and content." },
  { lead: "Search terms", text: "from a connected search console account." },
];

export const SEGMENT_POINTS: CheckItem[] = [
  { lead: "Click to filter", text: "from any row in any report." },
  { lead: "Saved segments", text: "shared across a workspace." },
  { lead: "Comparisons", text: "against the previous period or the same period last year." },
];

export const SEGMENT_FILTERS: Array<{
  field: string;
  operator: string;
  value: string;
  mono?: boolean;
  chevron?: boolean;
}> = [
  { field: "Source", operator: "is", value: "Instagram, Pinterest", chevron: true },
  { field: "Page", operator: "contains", value: "/products/", mono: true },
  { field: "Screen", operator: "is", value: "Mobile", chevron: true },
];

export const SEGMENT_MATCHES = 4212;

export const REPORT_POINTS: CheckItem[] = [
  { lead: "Email and Slack digests", text: "on the schedule you pick." },
  { lead: "Shared links", text: "with optional password protection." },
  { lead: "Embeds", text: "for public transparency pages." },
  { lead: "Stats API", text: "and CSV export for everything else." },
];

export const DIGEST = {
  subject: "Your week on harrowfield.co",
  meta: "Tally weekly digest · Sep 18 – Sep 24",
  topSource: "Google",
  topPage: "/shop/mugs",
  biggestMover: "Newsletter +64%",
};
