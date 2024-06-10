/**
 * Tally tracking script (bundled to public/t.js, ~1.9 KB gzipped).
 *
 *   <script defer data-site="example.com" src="https://cdn.tallystats.com/t.js"></script>
 *
 * Sends one small JSON payload per page view (and per custom event). It sets no cookies, touches no
 * storage and reads nothing that identifies a person; unique visitors are counted server-side with a
 * daily rotating hash.
 */
import type { TallyOptions, TrackPayload } from "../types/events";

type TallyFn = ((name: string, options?: TallyOptions) => void) & { q?: Array<[string, TallyOptions?]> };

declare global {
  interface Window {
    tally?: TallyFn;
  }
}

const DEFAULT_ENDPOINT = "https://api.tallystats.com/event";

(function tally() {
  const script = document.currentScript as HTMLScriptElement | null;
  const site = script?.dataset.site;
  if (!script || !site) return;

  const endpoint = script.dataset.api ?? DEFAULT_ENDPOINT;
  const skip =
    /^(localhost|127(\.\d+){3}|\[::1\])$/.test(location.hostname) ||
    location.protocol === "file:" ||
    navigator.webdriver;

  function send(name: string, options?: TallyOptions): void {
    if (skip) return;
    const payload: TrackPayload = {
      n: name,
      u: location.href,
      r: document.referrer || null,
      w: window.innerWidth,
      d: site!,
    };
    if (options?.props) payload.p = options.props;
    if (options?.revenue) payload.$ = options.revenue;

    const body = JSON.stringify(payload);
    // text/plain keeps the beacon a "simple" request, so no CORS preflight is needed.
    if (!navigator.sendBeacon?.(endpoint, body)) {
      fetch(endpoint, {
        method: "POST",
        body,
        keepalive: true,
        headers: { "content-type": "text/plain" },
      }).catch(() => undefined);
    }
  }

  let lastPage = "";
  function pageview(): void {
    const page = location.pathname + location.search;
    if (page === lastPage) return;
    lastPage = page;
    send("pageview");
  }

  // Single-page apps: count history-based route changes.
  const pushState = history.pushState;
  history.pushState = function (...args: Parameters<History["pushState"]>) {
    pushState.apply(this, args);
    pageview();
  };
  window.addEventListener("popstate", pageview);

  // Replay events queued by the inline stub before the script loaded.
  const queued = window.tally?.q ?? [];
  window.tally = (name, options) => send(name, options);
  queued.forEach(([name, options]) => send(name, options));

  // Don't count pages the browser prerendered but the visitor never saw.
  if ((document.visibilityState as string) === "prerender") {
    document.addEventListener("visibilitychange", pageview, { once: true });
  } else {
    pageview();
  }
})();
