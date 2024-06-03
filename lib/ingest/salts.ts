import { randomBytes } from "node:crypto";

/**
 * Daily salts for visitor hashing. A new random salt is created the first time it's needed each UTC day,
 * and older salts are deleted, so hashes can never be linked across days — not even by us.
 *
 * This in-memory store suits a single instance; multi-instance deployments swap in a shared store with
 * the same interface (e.g. Redis with a 48-hour TTL).
 */
export interface SaltStore {
  saltFor(day: string): Promise<Buffer>;
}

export function memorySaltStore(): SaltStore {
  const salts = new Map<string, Buffer>();
  return {
    async saltFor(day) {
      let salt = salts.get(day);
      if (!salt) {
        salt = randomBytes(32);
        salts.set(day, salt);
        for (const key of salts.keys()) if (key < day) salts.delete(key);
      }
      return salt;
    },
  };
}

export const utcDay = (d = new Date()) => d.toISOString().slice(0, 10);
