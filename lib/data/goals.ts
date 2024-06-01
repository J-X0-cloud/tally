export interface GoalDefinition {
  name: string;
  /** Share of unique visitors completing the goal. */
  rate: number;
  /** Completions per converting visitor. */
  perVisitor: number;
  tracksRevenue: boolean;
}

export const GOALS: GoalDefinition[] = [
  { name: "Purchase", rate: 0.028, perVisitor: 1.0, tracksRevenue: true },
  { name: "Add to cart", rate: 0.094, perVisitor: 1.4, tracksRevenue: false },
  { name: "Begin checkout", rate: 0.046, perVisitor: 1.15, tracksRevenue: false },
  { name: "Newsletter signup", rate: 0.031, perVisitor: 1.0, tracksRevenue: false },
  { name: "Scroll 75% · /journal/*", rate: 0.058, perVisitor: 1.1, tracksRevenue: false },
  { name: "Outbound link · Instagram", rate: 0.019, perVisitor: 1.1, tracksRevenue: false },
  { name: "File download · care-guide.pdf", rate: 0.012, perVisitor: 1.2, tracksRevenue: false },
];

/** Checkout funnel steps, as a share of unique visitors reaching each step in the same visit. */
export const CHECKOUT_FUNNEL: Array<{ name: string; share: number }> = [
  { name: "Viewed a product", share: 0.42 },
  { name: "Added to cart", share: 0.094 },
  { name: "Began checkout", share: 0.046 },
  { name: "Purchased", share: 0.028 },
];
