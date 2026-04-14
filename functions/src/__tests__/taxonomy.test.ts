import { describe, it, expect } from "vitest";
import { CATEGORIAS, isValidCategoria } from "../core/taxonomy";

describe("taxonomy", () => {
  it("incluye categorías core", () => {
    expect(CATEGORIAS).toContain("lacteos");
    expect(CATEGORIAS).toContain("bebidas");
    expect(CATEGORIAS).toContain("otros");
  });

  it("isValidCategoria acepta valores de la taxonomía", () => {
    expect(isValidCategoria("lacteos")).toBe(true);
  });

  it("isValidCategoria rechaza desconocidas", () => {
    expect(isValidCategoria("inventada")).toBe(false);
  });
});
