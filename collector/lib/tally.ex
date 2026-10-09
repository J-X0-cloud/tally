defmodule Tally do
  @moduledoc """
  Tally's collector service: cookie-free event ingestion, aggregation and the stats API.

  The domain is split into a few contexts:

    * `Tally.Ingest` validates tracking-script payloads and turns a request into an anonymous
      `Tally.Events.Event` (daily salted visitor hash, attribution, device classes, country).
    * `Tally.Events` buffers, stores and prunes events.
    * `Tally.Stats` aggregates stored events into totals, timeseries, breakdowns, goals and funnels.
    * `Tally.Live` keeps the set of visitors active in the last few minutes and broadcasts changes.
    * `Tally.Demo` is the seeded traffic model behind the public demo dashboard.
    * `Tally.Billing` holds the plan catalog, price quotes and per-plan Stats API limits.
  """
end
