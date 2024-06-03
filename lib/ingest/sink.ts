import type { Channel } from "./referrers";
import type { ScreenClass } from "./devices";

/** What is persisted per event. Note what's absent: no IP, no user agent, no full referrer URL. */
export interface StoredEvent {
  site: string;
  name: string;
  timestamp: string;
  visitorId: string;
  path: string;
  source: string;
  channel: Channel;
  utm: Record<string, string>;
  country: string | null;
  screen: ScreenClass;
  browser: string;
  os: string;
  props: Record<string, string | number | boolean>;
  revenue: { amount: number; currency: string } | null;
}

export interface EventSink {
  write(event: StoredEvent): Promise<void>;
}

/**
 * Buffers events and flushes them in batches to the columnar store. The flush target is injected so
 * the ingest route stays storage-agnostic.
 */
export function batchingSink(
  flush: (events: StoredEvent[]) => Promise<void>,
  { maxBatch = 500, maxWaitMs = 2000 } = {},
): EventSink {
  let buffer: StoredEvent[] = [];
  let timer: ReturnType<typeof setTimeout> | null = null;

  const drain = async () => {
    if (timer) clearTimeout(timer);
    timer = null;
    const batch = buffer;
    buffer = [];
    if (batch.length) await flush(batch);
  };

  return {
    async write(event) {
      buffer.push(event);
      if (buffer.length >= maxBatch) await drain();
      else timer ??= setTimeout(() => void drain(), maxWaitMs);
    },
  };
}
