import type { FaqItem } from "@/types/content";

import { CONTACT_URL } from "./site";

/** Monthly pageview tiers. The last tier has no list price. */
export const VOLUMES = ["10k", "100k", "200k", "500k", "1M", "2M", "5M", "10M+"];

export interface Plan {
  name: string;
  description: string;
  /** Monthly price per volume tier; null means custom pricing. */
  prices: Array<number | null>;
  features: string[];
  popular?: boolean;
}

export const PLANS: Plan[] = [
  {
    name: "Starter",
    description: "For a personal site or a single small store.",
    prices: [9, 19, 29, 49, 69, 99, 149, null],
    features: [
      "1 site",
      "3 years of data retention",
      "All core reports and realtime",
      "Goals and custom events",
      "Email and Slack reports",
      "Import from other analytics tools",
    ],
  },
  {
    name: "Growth",
    description: "For teams and agencies with a few sites.",
    prices: [14, 29, 44, 69, 99, 139, 199, null],
    features: [
      "Up to 5 sites and 5 teammates",
      "Everything in Starter",
      "Funnels and revenue goals",
      "Shared links and embeds",
      "Saved segments and annotations",
      "Stats API",
    ],
    popular: true,
  },
  {
    name: "Business",
    description: "For companies that live in their data.",
    prices: [29, 54, 79, 119, 159, 219, 299, null],
    features: [
      "Up to 20 sites and 20 teammates",
      "Everything in Growth",
      "5 years of data retention",
      "Custom properties",
      "First-party proxy, managed for you",
      "Priority support",
    ],
  },
];

/** Yearly billing charges ten months for twelve. */
export const YEARLY_MONTHS_CHARGED = 10;

export function planPrice(
  monthly: number | null,
  yearly: boolean,
): { price: string; note: (volume: string) => string } {
  if (monthly === null) return { price: "Custom", note: () => "Talk to us about volume pricing" };
  if (!yearly) return { price: `$${monthly}`, note: (v) => `Billed monthly · ${v} pageviews` };
  const perMonth = ((monthly * YEARLY_MONTHS_CHARGED) / 12).toFixed(2).replace(/\.?0+$/, "");
  return {
    price: `$${perMonth}`,
    note: (v) => `$${monthly * YEARLY_MONTHS_CHARGED} billed yearly · ${v} pageviews`,
  };
}

/** Columns: Starter, Growth, Business. `true` is a check, `false` a dash. */
export const COMPARISON: Array<[string, string | boolean, string | boolean, string | boolean]> = [
  ["Sites", "1", "5", "20"],
  ["Teammates", "1", "5", "20"],
  ["Data retention", "3 years", "3 years", "5 years"],
  ["Realtime, sources, pages, locations, devices", true, true, true],
  ["Goals and custom events", true, true, true],
  ["Funnels", false, true, true],
  ["Revenue goals", false, true, true],
  ["Shared links and embeds", false, true, true],
  ["Stats API", false, "600 req/hr", "2,000 req/hr"],
  ["Custom properties", false, false, true],
  ["Managed first-party proxy", false, false, true],
];

export const BILLING_FAQ: FaqItem[] = [
  {
    q: "What counts as a pageview?",
    a: "Every page load or route change on a site you track, plus custom events. Bots and filtered traffic are never billed.",
  },
  {
    q: "What happens if I go over my plan?",
    a: "We keep counting. If you exceed your tier two months in a row we will email you to suggest the next one; nothing is cut off and there are no surprise overage charges.",
  },
  {
    q: "Can I import my old analytics data?",
    a: "Yes. Historical data from most major analytics tools can be imported on every plan, so your year-over-year comparisons still work.",
  },
  {
    q: "Do you offer discounts for nonprofits?",
    a: "Registered nonprofits and open educational projects get 50% off any plan.",
    link: { label: "Email us", href: CONTACT_URL, after: " to set it up." },
  },
];
