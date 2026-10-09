import type { FaqItem } from "@/types/content";

import { CONTACT_URL } from "./site";

// Plans, prices and the comparison table are served by the collector (GET /api/plans).

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
