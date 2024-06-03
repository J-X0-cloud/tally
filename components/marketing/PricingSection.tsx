"use client";

import clsx from "clsx";
import { useState } from "react";

import { ButtonLink } from "@/components/ui/ButtonLink";
import { CheckList } from "@/components/ui/CheckList";
import { PLANS, VOLUMES, planPrice } from "@/lib/data/pricing";
import { ENTERPRISE_URL, TRIAL_URL } from "@/lib/data/site";

/** Pageview tier and billing period pickers (radio groups) driving the three plan cards. */
export function PricingSection() {
  const [volume, setVolume] = useState(0);
  const [yearly, setYearly] = useState(false);

  return (
    <>
      <div className="pctl">
        <span className="cap" id="tier-label">
          Monthly pageviews
        </span>
        <div className="grpl" role="radiogroup" aria-labelledby="tier-label">
          {VOLUMES.map((v, i) => (
            <label key={v} className={clsx(i === volume && "on")}>
              <input
                className="vis"
                type="radio"
                name="volume"
                checked={i === volume}
                onChange={() => setVolume(i)}
              />
              {v}
            </label>
          ))}
        </div>
        <div className="grpl" role="radiogroup" aria-label="Billing period">
          {(
            [
              [false, "Monthly"],
              [true, "Yearly · 2 months free"],
            ] as const
          ).map(([isYearly, label]) => (
            <label key={label} className={clsx(yearly === isYearly && "on")}>
              <input
                className="vis"
                type="radio"
                name="period"
                checked={yearly === isYearly}
                onChange={() => setYearly(isYearly)}
              />
              {label}
            </label>
          ))}
        </div>
      </div>

      <div className="plans">
        {PLANS.map((plan) => {
          const { price, note } = planPrice(plan.prices[volume], yearly);
          return (
            <div key={plan.name} className={clsx("plan", plan.popular && "hot")}>
              {plan.popular ? <span className="hotb">Most popular</span> : null}
              <h3>{plan.name}</h3>
              <p className="d">{plan.description}</p>
              <div className="price">
                {price}
                {price === "Custom" ? null : <small>/mo</small>}
              </div>
              <div className="per">{note(VOLUMES[volume])}</div>
              <ButtonLink href={TRIAL_URL} variant={plan.popular ? "p" : "d"}>
                Start 30-day trial
              </ButtonLink>
              <CheckList items={plan.features.map((text) => ({ text }))} />
            </div>
          );
        })}
      </div>

      <div className="ent">
        <div>
          <h3>Enterprise</h3>
          <p>
            More than 10 million monthly pageviews, 20+ sites, single sign-on, raw event exports or a custom
            agreement? We will put a plan together with you.
          </p>
        </div>
        <ButtonLink href={ENTERPRISE_URL} variant="g">
          Contact sales
        </ButtonLink>
      </div>
    </>
  );
}
