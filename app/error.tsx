"use client";

import Link from "next/link";

/**
 * Shown when a page can't load its data, most often because the collector service (API_URL) is not
 * running or not reachable.
 */
export default function ErrorPage({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <section className="phero" style={{ textAlign: "center", padding: "96px 16px" }}>
      <div className="wrap">
        <span className="eyebrow">Something went wrong</span>
        <h1 className="center">We couldn&apos;t load these numbers.</h1>
        <p className="lede">
          The stats service didn&apos;t answer. Try again in a moment, or head back to the home page.
        </p>
        <div className="row" style={{ justifyContent: "center", gap: 12 }}>
          <button type="button" className="btn btn-p" onClick={reset}>
            Try again
          </button>
          <Link className="btn btn-g" href="/">
            Back to the site
          </Link>
        </div>
      </div>
    </section>
  );
}
