import type { FaqItem } from "@/types/content";

export const PRIVACY_STATS = [
  { label: "Cookies set", value: "0", zero: true },
  { label: "IPs stored", value: "0", zero: true },
  { label: "Script size", value: "1.9 KB" },
];

export const DEVICE_STORAGE = ["Cookies · none", "localStorage · none", "Fingerprint · none"];

export const COUNTING_STEPS = [
  {
    title: "A page loads",
    body: "The script sends the page URL, referrer, screen width and UTM tags. That is the whole payload.",
    code: '{ u: "/shop/mugs", r: "google.com", w: 390 }',
  },
  {
    title: "A daily hash is made",
    body: "On our servers, the IP and user agent are combined with a random salt that rotates every 24 hours, then hashed.",
    code: "hash(salt₂₀₂₆₀₉₂₅ + site + ip + ua)",
  },
  {
    title: "The raw IP is dropped",
    body: "After a country lookup and the hash, the IP address is discarded. It is never written to a database or a log.",
    code: "ip → US, CA · then deleted",
  },
  {
    title: "Only totals remain",
    body: "Yesterday's salt is deleted too, so no visitor can be matched across days, sites or devices. You get aggregate counts.",
    code: "visitors: 1,842 · pageviews: 6,120",
  },
];

export const COLLECTED = [
  "Page URL and page title",
  "Referrer and UTM campaign tags",
  "Country, region and city (from IP, which is then discarded)",
  "Browser, operating system and screen size class",
  "Goals and custom events you define",
  "Visit duration and scroll depth",
];

export const NEVER_COLLECTED = [
  "Cookies, local storage or any device identifier",
  "Full IP addresses",
  "Fingerprints or cross-site identifiers",
  "Names, emails or form contents",
  "Keystrokes, mouse movements or session recordings",
  "Anything sold, shared or used for advertising",
];

export const PRIVACY_FAQ: FaqItem[] = [
  {
    q: "Do I still need a cookie banner?",
    a: "Tally itself sets no cookies and processes no personal data, so it does not need consent under most privacy laws. If other tools on your site set cookies, you may still need a banner for those. We recommend confirming with your own counsel.",
  },
  {
    q: "Where is my data stored?",
    a: "You choose a US or EU region when you add a site. Data stays in that region and is encrypted at rest and in transit.",
  },
  {
    q: "How do you count unique visitors without cookies?",
    a: "With a hash of the site, IP address and user agent plus a salt that changes every 24 hours. It lets us tell visitors apart within one day and makes it impossible to connect them across days.",
  },
  {
    q: "Can I get a data processing agreement?",
    a: "Yes. Every paid plan includes a standard DPA you can sign from your account settings in a couple of minutes.",
  },
];
