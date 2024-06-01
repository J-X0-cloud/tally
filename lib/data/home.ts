import type { IconName } from "@/components/ui/Icon";
import type { CheckItem } from "@/types/content";

export const HERO_NOTES = ["No cookies", "1.9 KB script", "No credit card to start"];

export const CUSTOMER_WORDMARKS: Array<[string, string]> = [
  ["northpine", "w1"],
  ["Bramble & Rye", "w2"],
  ["quill.works", "w3"],
  ["Ostrander", "w4"],
  ["Fieldhouse", "w5"],
  ["Marigold Press", "w2"],
];

export const FEATURES: Array<{ icon: IconName; title: string; body: string }> = [
  {
    icon: "live",
    title: "Realtime, without the refresh",
    body: "A live visitor count and the pages people are on right now, updated every few seconds.",
  },
  {
    icon: "src",
    title: "Sources, channels and UTMs",
    body: "Search, social, email, AI assistants and every tagged campaign, grouped into channels automatically.",
  },
  {
    icon: "page",
    title: "Pages and scroll depth",
    body: "Top, entry and exit pages, with how far people actually read. No tag manager required.",
  },
  {
    icon: "goal",
    title: "Goals and revenue",
    body: "Count signups, purchases, downloads and outbound clicks, and attach order values to see revenue by source.",
  },
  {
    icon: "funnel",
    title: "Funnels",
    body: "Define up to eight steps and see exactly where visitors leave, filtered by source, device or country.",
  },
  {
    icon: "globe",
    title: "Countries and devices",
    body: "Country, region and city from an IP that is discarded right after lookup. Browser, OS and screen size.",
  },
  {
    icon: "mail",
    title: "Email and Slack reports",
    body: "A weekly digest of what changed, sent to the people who asked for it and nobody else.",
  },
  {
    icon: "share",
    title: "Shared dashboards",
    body: "Send a private link to a client or embed a read-only dashboard on a public page.",
  },
  {
    icon: "bot",
    title: "Bot and spam filtering",
    body: "Known crawlers, referrer spam and data-center traffic are filtered out before they reach your numbers.",
  },
];

export const SCRIPT_POINTS: CheckItem[] = [
  { lead: "Works everywhere.", text: "Plain HTML, any framework, or a tag manager if you already have one." },
  { lead: "Single-page apps included.", text: "History-based route changes are counted automatically." },
  { lead: "First-party option.", text: "Serve the script from your own domain for more complete counts." },
];

export const PRIVACY_PILLARS: Array<{ icon: IconName; title: string; body: string }> = [
  {
    icon: "cookie",
    title: "Nothing stored on the device",
    body: "No cookies, local storage or fingerprinting. Each visit is counted with a hash that expires every 24 hours.",
  },
  {
    icon: "key",
    title: "IP addresses are never saved",
    body: "We use an IP only for a country lookup and the daily hash, then throw it away before anything is written to disk.",
  },
  {
    icon: "server",
    title: "Your data is only yours",
    body: "No ad networks, no data resale, no cross-site profiles. Choose US or EU storage and export everything at any time.",
  },
];

export const GOAL_POINTS: CheckItem[] = [
  { lead: "Codeless goals", text: "for page visits, outbound links, file downloads and form submits." },
  { lead: "Revenue", text: "per goal and per source, in your store's currency." },
  { lead: "Funnels", text: "with drop-off at every step and a one-click filter to the visitors who left." },
];

export const TESTIMONIALS = [
  {
    quote:
      "We replaced a tag manager, two analytics tags and a consent banner with one line. Our product pages load noticeably faster and the numbers finally match what our orders say.",
    name: "Maya R.",
    role: "Founder, a ceramics studio",
    color: "#E4572E",
  },
  {
    quote:
      "I send clients a shared Tally link instead of a monthly PDF. They open it more than they ever opened the report, and nobody needs a training call.",
    name: "Daniel K.",
    role: "Owner, a two-person web agency",
    color: "#4A2E4F",
  },
  {
    quote:
      "The funnel view showed us that half our trial signups dropped at the pricing toggle. We fixed the copy that afternoon.",
    name: "Priya S.",
    role: "Growth lead, a B2B SaaS team",
    color: "#C77A1E",
  },
];
