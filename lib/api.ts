/**
 * Server-side client for the collector service. Pages call these during rendering; the browser never
 * talks to the collector directly except through the tracking script's event endpoint.
 */
import { connection } from "next/server";
import { cache } from "react";

import type { DemoDashboard } from "@/types/analytics";
import type { PricingCatalog } from "@/types/pricing";

const DEFAULT_API_URL = "http://localhost:4000";
const TIMEOUT_MS = 8000;

export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number | null,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

/** Base URL of the collector, from API_URL, without a trailing slash. */
export function apiUrl(): string {
  return (process.env.API_URL || DEFAULT_API_URL).replace(/\/+$/, "");
}

async function getJson<T>(path: string): Promise<T> {
  // Render at request time: the data lives in the service, not in the build.
  await connection();

  const url = `${apiUrl()}${path}`;
  let res: Response;
  try {
    res = await fetch(url, {
      cache: "no-store",
      headers: { accept: "application/json" },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
  } catch (cause) {
    throw new ApiError(`Collector unreachable at ${url}: ${(cause as Error).message}`, null);
  }
  if (!res.ok) throw new ApiError(`GET ${url} answered ${res.status}`, res.status);
  return (await res.json()) as T;
}

/** The demo dashboard for every range. Deduplicated per request. */
export const getDemoDashboard = cache(() => getJson<DemoDashboard>("/api/demo"));

/** Plans, prices for every tier and billing period, and the comparison table. */
export const getPricing = cache(() => getJson<PricingCatalog>("/api/plans"));
