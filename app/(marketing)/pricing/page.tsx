import type { Metadata } from "next";

import { CtaBox } from "@/components/marketing/CtaBox";
import { Faq } from "@/components/marketing/Faq";
import { PlanComparison } from "@/components/marketing/PlanComparison";
import { PricingSection } from "@/components/marketing/PricingSection";
import { SectionHead } from "@/components/marketing/SectionHead";
import { ButtonLink } from "@/components/ui/ButtonLink";
import { BILLING_FAQ } from "@/lib/data/pricing";
import { TRIAL_URL } from "@/lib/data/site";

export const metadata: Metadata = {
  title: "Pricing",
  description:
    "Simple Tally pricing based on monthly pageviews. Every plan includes the full dashboard, goals and a 30-day free trial.",
};

export default function PricingPage() {
  return (
    <>
      <section className="phero center" style={{ textAlign: "center" }}>
        <div className="wrap">
          <span className="eyebrow">Pricing</span>
          <h1 className="center">Priced by traffic. Every report included.</h1>
          <p className="lede">
            Start with a 30-day free trial, no card required. Pick the monthly pageviews you expect; if you go
            over for a month, nothing breaks and we will just say hello.
          </p>
        </div>
      </section>

      <section style={{ paddingBottom: 40 }}>
        <div className="wrap">
          <PricingSection />
        </div>
      </section>

      <section className="sec">
        <div className="wrap">
          <SectionHead centered title="Compare plans" />
          <PlanComparison />
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap">
          <SectionHead centered title="Billing questions" />
          <Faq items={BILLING_FAQ} />
        </div>
      </section>

      <section>
        <div className="wrap">
          <CtaBox
            title="See your own numbers by lunch."
            body="One line of code, 30 days free, and your first visitors appear within a minute."
          >
            <ButtonLink href={TRIAL_URL} variant="w">
              Start free trial
            </ButtonLink>
            <ButtonLink href="/demo" variant="o">
              View live demo
            </ButtonLink>
          </CtaBox>
        </div>
      </section>
    </>
  );
}
