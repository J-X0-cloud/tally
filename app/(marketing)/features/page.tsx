import type { Metadata } from "next";

import { BreakdownPanel } from "@/components/dashboard/BreakdownPanel";
import { GoalsTable } from "@/components/dashboard/GoalsTable";
import { CtaBox } from "@/components/marketing/CtaBox";
import { DigestCard } from "@/components/marketing/DigestCard";
import { RealtimeCard } from "@/components/marketing/RealtimeCard";
import { SectionHead } from "@/components/marketing/SectionHead";
import { SegmentBuilder } from "@/components/marketing/SegmentBuilder";
import { StepFunnel } from "@/components/marketing/StepFunnel";
import { ButtonLink } from "@/components/ui/ButtonLink";
import { CheckList } from "@/components/ui/CheckList";
import { CodeBlock } from "@/components/ui/CodeBlock";
import { Icon } from "@/components/ui/Icon";
import { PURCHASE_SNIPPET } from "@/lib/data/snippets";
import { REALTIME_POINTS, REPORT_POINTS, SEGMENT_POINTS, SOURCE_POINTS } from "@/lib/data/tour";

export const metadata: Metadata = {
  title: "Product tour",
  description:
    "Realtime visitors, sources and UTM campaigns, goals and revenue, funnels, segments and shared reports: a tour of Tally's cookie-free analytics.",
};

const MUTED_PILL = { background: "#F1EBE3", color: "var(--ink2)" } as const;

export default function FeaturesPage() {
  return (
    <>
      <section className="phero">
        <div className="wrap split">
          <div className="ft">
            <span className="eyebrow">Product tour</span>
            <h1>All the answers, none of the setup.</h1>
            <p className="lede">
              Tally puts the numbers most teams check every week on one fast page, then lets you drill into
              any of them with a single click. Start with what is happening right now.
            </p>
            <CheckList items={REALTIME_POINTS} />
            <div className="row">
              <ButtonLink href="/demo" variant="p">
                Try the live demo
              </ButtonLink>
              <ButtonLink href="/pricing" variant="g">
                See pricing
              </ButtonLink>
            </div>
          </div>
          <div className="canvas">
            <RealtimeCard />
          </div>
        </div>
      </section>

      <section className="sec bt" id="funnels">
        <div className="wrap">
          <SectionHead
            eyebrow="Funnels"
            title="Find the step that leaks."
            lede="Chain pages and events into a funnel of two to eight steps. Tally shows how many visitors reach each step in the same visit and how many leave in between."
          />
          <StepFunnel />
          <div className="pills" style={{ marginTop: 18 }}>
            <span className="pill">
              <Icon name="filter" size={13} />
              Source is Instagram
            </span>
            <span className="pill">
              <Icon name="filter" size={13} />
              Device is Mobile
            </span>
            <span className="pill" style={MUTED_PILL}>
              + Add filter
            </span>
          </div>
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap split rev">
          <div className="ft">
            <span className="eyebrow">Sources &amp; campaigns</span>
            <h2>Know which channel is worth the effort.</h2>
            <p className="lede">
              Traffic is grouped into channels automatically. UTM tags, referrers and AI assistants all show
              up without a line of configuration, and every row doubles as a filter.
            </p>
            <CheckList items={SOURCE_POINTS} />
          </div>
          <div className="canvas p">
            <div className="grid2" style={{ gridTemplateColumns: "1fr" }}>
              <BreakdownPanel dimension="sources" range="30d" interactive={false} />
            </div>
          </div>
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap split">
          <div className="ft">
            <span className="eyebrow">Goals &amp; custom events</span>
            <h2>Count what matters to your business.</h2>
            <p className="lede">
              Page goals need no code. For anything else, one function call records an event with custom
              properties you can filter and break down.
            </p>
            <CodeBlock snippet={PURCHASE_SNIPPET} title="checkout.js" style={{ marginTop: 22 }} />
          </div>
          <div className="canvas">
            <div className="card pad">
              <GoalsTable range="30d" />
            </div>
          </div>
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap split rev">
          <div className="ft">
            <span className="eyebrow">Segments &amp; filters</span>
            <h2>Slice any report in two clicks.</h2>
            <p className="lede">
              Combine filters on source, page, country, device or any custom property. Save the combinations
              you use often as segments your whole team can open.
            </p>
            <CheckList items={SEGMENT_POINTS} />
          </div>
          <div className="canvas p">
            <div className="card pad">
              <SegmentBuilder />
            </div>
          </div>
        </div>
      </section>

      <section className="sec bt">
        <div className="wrap split">
          <div className="ft">
            <span className="eyebrow">Reports &amp; sharing</span>
            <h2>The numbers, delivered.</h2>
            <p className="lede">
              Weekly or monthly email digests, Slack summaries, and private share links for clients who should
              see a dashboard but never need a login.
            </p>
            <CheckList items={REPORT_POINTS} />
          </div>
          <div className="canvas">
            <DigestCard />
          </div>
        </div>
      </section>

      <section className="sec" style={{ paddingBottom: 0 }}>
        <div className="wrap">
          <CtaBox
            title="Poke around a real dashboard."
            body="The live demo runs on generated data for a fictional ceramics shop. Switch date ranges, change the metric and open every report."
          >
            <ButtonLink href="/demo" variant="w">
              Open the live demo
            </ButtonLink>
          </CtaBox>
        </div>
      </section>
    </>
  );
}
