/** The plan catalog served by the collector at `GET /api/plans`. */
export interface PriceQuote {
  /** Display price, e.g. "$29", "$24.17" or "Custom". */
  price: string;
  note: string;
  /** List price per month; null for custom pricing. */
  monthly: number | null;
}

export interface PlanPrices {
  id: string;
  name: string;
  description: string;
  features: string[];
  popular: boolean;
  /** One entry per volume tier, in the catalog's volume order. */
  prices: Array<{ volume: string; monthly: PriceQuote; yearly: PriceQuote }>;
}

export interface PricingCatalog {
  /** Monthly pageview tiers. */
  volumes: string[];
  yearlyMonthsCharged: number;
  plans: PlanPrices[];
  /** Columns follow `plans`; `true` is a check, `false` a dash. */
  comparison: Array<{ feature: string; values: Array<string | boolean> }>;
}
