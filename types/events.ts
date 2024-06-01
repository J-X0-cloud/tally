/**
 * Wire format sent by the tracking script to POST /api/event. Keys are one letter to keep the payload
 * (and the script) small.
 */
export interface TrackPayload {
  /** Event name: "pageview" or a custom goal name. */
  n: string;
  /** Full page URL, including UTM parameters. */
  u: string;
  /** document.referrer, or null. */
  r: string | null;
  /** Viewport width in CSS pixels, used for the screen-size class. */
  w: number;
  /** Site domain from the script's data-site attribute. */
  d: string;
  /** Custom properties. */
  p?: Record<string, string | number | boolean>;
  /** Revenue attached to a goal. */
  $?: { amount: number; currency: string };
}

export interface TallyOptions {
  props?: Record<string, string | number | boolean>;
  revenue?: { amount: number; currency: string };
}
