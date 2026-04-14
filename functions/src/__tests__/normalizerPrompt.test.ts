import { describe, it, expect } from "vitest";
import {
  SYSTEM_PROMPT,
  buildUserPrompt,
} from "../core/normalizerPrompt";

describe("normalizerPrompt", () => {
  it("SYSTEM_PROMPT menciona JSON, taxonomía y confianza", () => {
    expect(SYSTEM_PROMPT).toContain("JSON");
    expect(SYSTEM_PROMPT).toContain("lacteos");
    expect(SYSTEM_PROMPT).toMatch(/confianza/i);
  });

  it("buildUserPrompt incluye nombre y barcode", () => {
    const p = buildUserPrompt({
      barcode: "7802800000000",
      nombre: "leche soprole 1lt",
      marca: null,
    });
    expect(p).toContain("7802800000000");
    expect(p).toContain("leche soprole 1lt");
  });

  it("buildUserPrompt omite campos nulos sin romperse", () => {
    const p = buildUserPrompt({ barcode: null, nombre: "pan" });
    expect(p).toContain("pan");
    expect(p).not.toContain("null");
  });
});
