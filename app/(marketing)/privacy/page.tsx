import type { Metadata } from "next";

import { CountingFlow } from "@/components/marketing/CountingFlow";
import { DataInventory } from "@/components/marketing/DataInventory";
import { Faq } from "@/components/marketing/Faq";
import { InstallOptions } from "@/components/marketing/InstallOptions";
import { PayloadShowcase } from "@/components/marketing/PayloadShowcase";
import { SectionHead } from "@/components/marketing/SectionHead";
import { SizeBars } from "@/components/marketing/SizeBars";
import { ButtonLink } from "@/components/ui/ButtonLink";
import { PRIVACY_FAQ } from "@/lib/data/privacy";

export const metadata: Metadata = {
  title: "Privacy & script",
  description:
    "How Tally counts website visitors without cookies: daily rotating hashes, no stored IP addresses, a 1.9 KB script and simple install options.",
};

export default function PrivacyPage() {
  return (
    <>
      <section className="phero">
        <div className="wrap split">
          <div>
            <span className="eyebrow">Privacy &amp; script</span>
            <h1>Counting visits without following people.</h1>
            <p className="lede">
              Tally was built on one rule: measure how a website is used, never who is using it. Here is
              exactly how that works, and what it means for your consent banner.
            </p>
            <div className="row">
              <ButtonLink href="#install" variant="p">
                Install the script
              </ButtonLink>
              <ButtonLink href="#collect" variant="g">
                What we collect
              </ButtonLink>
            </div>
          </div>
          <div className="canvas p">
            <PayloadShowcase />
          </div>
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap">
          <SectionHead
            eyebrow="How it works"
            title="From page view to count in four steps."
            lede="No identifier ever lives on the visitor's device, and nothing we store can be traced back to a person."
          />
          <CountingFlow />
        </div>
      </section>

      <section className="sec bt" id="collect">
        <div className="wrap">
          <SectionHead eyebrow="Data inventory" title="What Tally collects, and what it never will." />
          <DataInventory />
        </div>
      </section>

      <section className="sec dark">
        <div className="wrap split">
          <div>
            <span className="eyebrow">Performance</span>
            <h2 style={{ color: "#fff", margin: "14px 0 16px" }}>
              Smaller than the image you are about to load.
            </h2>
            <p className="lede">
              A heavy analytics setup adds requests, main-thread work and layout shifts to every page.
              Tally&apos;s script is a single deferred file with no dependencies.
            </p>
          </div>
          <div className="card pad" style={{ background: "#2E2430", borderColor: "#3E3240", color: "#fff" }}>
            <SizeBars dark />
            <p style={{ fontSize: 12.5, color: "#A89AA6", marginTop: 16 }}>
              Compressed transfer size. Third-party figures are typical ranges for common setups and vary by
              configuration.
            </p>
          </div>
        </div>
      </section>

      <section className="sec" id="install">
        <div className="wrap">
          <SectionHead
            eyebrow="Install"
            title="Up and running in about a minute."
            lede="Pick whichever fits your stack. You can run Tally alongside your existing analytics while you compare."
          />
          <InstallOptions />
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap">
          <SectionHead centered eyebrow="Questions" title="Privacy FAQ" />
          <Faq items={PRIVACY_FAQ} />
        </div>
      </section>
    </>
  );
}
