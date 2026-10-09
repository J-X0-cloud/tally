import type { CheckItem } from "@/types/content";

export const REALTIME_POINTS: CheckItem[] = [
  { lead: "Current visitors", text: "refreshed every few seconds, no reload." },
  { lead: "Live feed", text: "of page views and goal completions as they arrive." },
  { lead: "Launch mode", text: "for a full-screen view on the office TV." },
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
