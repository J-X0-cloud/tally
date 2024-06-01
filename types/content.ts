/** A check-list line; the optional lead is set in bold. */
export interface CheckItem {
  lead?: string;
  text: string;
}

export interface FaqItem {
  q: string;
  a: string;
  /** Optional trailing link, e.g. "Email us" + " to set it up." */
  link?: { label: string; href: string; after: string };
}
