import { createHash } from "crypto";

/**
 * SHA-256 determinista, insensible al orden, sobre una lista de nombres
 * de ingredientes (trimmed + lowercased + sorted).
 */
export function hashIngredientes(nombres: string[]): string {
  const sorted = [...nombres].map((n) => n.trim().toLowerCase()).sort();
  return createHash("sha256").update(sorted.join("|")).digest("hex");
}
