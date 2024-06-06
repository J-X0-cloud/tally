import { DashboardPreview } from "@/components/dashboard/DashboardPreview";
import { FunnelRows } from "@/components/dashboard/FunnelRows";
import { CtaBox } from "@/components/marketing/CtaBox";
import { FeatureGrid } from "@/components/marketing/FeatureGrid";
import { PrivacyPillars } from "@/components/marketing/PrivacyPillars";
import { SectionHead } from "@/components/marketing/SectionHead";
import { SizeBars } from "@/components/marketing/SizeBars";
import { Testimonials } from "@/components/marketing/Testimonials";
import { ButtonLink } from "@/components/ui/ButtonLink";
import { CheckList } from "@/components/ui/CheckList";
import { CodeBlock } from "@/components/ui/CodeBlock";
import { Icon } from "@/components/ui/Icon";
import { CUSTOMER_WORDMARKS, GOAL_POINTS, HERO_NOTES, SCRIPT_POINTS } from "@/lib/data/home";
import { SITE } from "@/lib/data/simulation";
import { INSTALL_SNIPPET } from "@/lib/data/snippets";

export default function HomePage() {
  return (
    <>
      <section className="hero">
        <div className="wrap">
          <span className="badge">
            <b>New</b>Funnels now support up to eight steps
          </span>
          <h1>
            Your website traffic, <span>on one honest page.</span>
          </h1>
          <p className="lede">
            Tally is cookie-free web analytics. See where visitors come from, what they read and what they
            buy, without consent banners, fingerprinting or a 90-page reporting manual.
          </p>
          <div className="row">
            <ButtonLink href="/pricing" variant="p">
              Start a 30-day free trial
            </ButtonLink>
            <ButtonLink href="/demo" variant="g">
              Open the live demo <Icon name="arrow" size={16} />
            </ButtonLink>
          </div>
          <div className="note">
            {HERO_NOTES.map((n) => (
              <span key={n}>
                <Icon name="check" size={15} strokeWidth={2.4} />
                {n}
              </span>
            ))}
          </div>
        </div>
        <div className="stage">
          <div className="wrap">
            <div className="win">
              <div className="win-top">
                <i />
                <i />
                <i />
                <span className="url">app.tallystats.com/{SITE.domain}</span>
              </div>
              <DashboardPreview />
            </div>
          </div>
        </div>
      </section>

      <section className="logos">
        <div className="wrap">
          <p>Counting visits for independent shops, SaaS teams, agencies and publishers</p>
          <div className="l">
            {CUSTOMER_WORDMARKS.map(([name, style]) => (
              <span key={name} className={style}>
                {name}
              </span>
            ))}
          </div>
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap">
          <SectionHead
            centered
            eyebrow="What you get"
            title="Everything you check every week. Nothing you never open."
            lede="One dashboard, no report builder, no sampling. Click any row to filter the whole page by it."
          />
          <FeatureGrid />
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap split">
          <div className="ft">
            <span className="eyebrow">Lightweight script</span>
            <h2>One line of code. About 1.9 KB.</h2>
            <p className="lede">
              The Tally script is smaller than most favicons. It loads with{" "}
              <code className="mono">defer</code>, sets no cookies and never blocks rendering, so your Core
              Web Vitals stay where you left them.
            </p>
            <CheckList items={SCRIPT_POINTS} />
            <ButtonLink href="/privacy#install" variant="d">
              See install options
            </ButtonLink>
          </div>
          <div>
            <CodeBlock snippet={INSTALL_SNIPPET} title="index.html" badge="1.9 KB gzipped" />
            <div className="card pad" style={{ marginTop: 18 }}>
              <SizeBars />
            </div>
          </div>
        </div>
      </section>

      <section className="sec dark">
        <div className="wrap">
          <SectionHead
            eyebrow="Privacy by design"
            title="No cookies. No personal data. No banner."
            titleStyle={{ color: "#fff" }}
            lede="Tally measures traffic, not people. There is nothing to consent to, so every visitor is counted from the first page view instead of after a pop-up."
          />
          <PrivacyPillars />
          <div className="row" style={{ marginTop: 36 }}>
            <ButtonLink href="/privacy" variant="p">
              How Tally counts without cookies
            </ButtonLink>
          </div>
        </div>
      </section>

      <section className="sec">
        <div className="wrap split rev">
          <div className="ft">
            <span className="eyebrow">Goals &amp; funnels</span>
            <h2>See the step where people give up.</h2>
            <p className="lede">
              Turn any page or click into a goal, attach revenue, and chain goals into a funnel. Filter by
              channel to find out which traffic actually buys.
            </p>
            <CheckList items={GOAL_POINTS} />
            <ButtonLink href="/features#funnels" variant="d">
              Explore goals and funnels
            </ButtonLink>
          </div>
          <div className="canvas">
            <div className="card pad">
              <div className="chh">
                <b>Checkout funnel</b>
                <span className="int">Last 30 days</span>
              </div>
              <FunnelRows range="30d" />
            </div>
          </div>
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap">
          <SectionHead centered eyebrow="From customers" title="Analytics people actually open." />
          <Testimonials />
        </div>
      </section>

      <section>
        <div className="wrap">
          <CtaBox
            title="Try Tally free for 30 days."
            body="Add one line to your site and see your first visitors within a minute. Keep your old analytics running alongside while you compare."
          >
            <ButtonLink href="/pricing" variant="w">
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
