export const CONTACT_EMAIL = "hello@tallystats.com";
export const CONTACT_URL = `mailto:${CONTACT_EMAIL}`;
export const TRIAL_URL = `${CONTACT_URL}?subject=Tally%20trial`;
export const ENTERPRISE_URL = `${CONTACT_URL}?subject=Tally%20Enterprise`;

export const NAV_LINKS = [
  { href: "/features", label: "Product" },
  { href: "/privacy", label: "Privacy" },
  { href: "/pricing", label: "Pricing" },
  { href: "/demo", label: "Live demo" },
] as const;

export const FOOTER_COLUMNS = [
  {
    title: "Product",
    links: [
      { href: "/features", label: "Product tour" },
      { href: "/demo", label: "Live demo" },
      { href: "/pricing", label: "Pricing" },
      { href: "#", label: "Changelog" },
    ],
  },
  {
    title: "Privacy",
    links: [
      { href: "/privacy", label: "How Tally counts" },
      { href: "/privacy#collect", label: "What we collect" },
      { href: "/privacy#install", label: "Install the script" },
      { href: "#", label: "Data processing agreement" },
    ],
  },
  {
    title: "Company",
    links: [
      { href: "#", label: "About" },
      { href: CONTACT_URL, label: "Contact" },
      { href: "#", label: "System status" },
      { href: "#", label: "Terms" },
    ],
  },
];

export const TAGLINE =
  "Simple, cookie-free web analytics for people who would rather ship than configure reports.";

/** Script weight compared with typical setups (compressed transfer size). */
export const SCRIPT_SIZES = [
  { label: "Tally", width: 2, size: "1.9 KB", highlight: true },
  { label: "Typical analytics tag", width: 48, size: "~45 KB" },
  { label: "Tag manager + tags", width: 100, size: "~95 KB" },
];
