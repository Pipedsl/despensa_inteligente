import { describe, it, expect } from "vitest";
import { NormalizerResponseSchema } from "../core/normalizerOpenAI";

// Tests del esquema Zod compartido entre implementaciones del normalizer
describe("NormalizerResponseSchema", () => {
  it("acepta respuesta válida", () => {
    const result = NormalizerResponseSchema.parse({
      nombre: "Leche Soprole 1 L",
      marca: "Soprole",
      categorias: ["lacteos"],
      confianza: 0.92,
      correcciones: ["capitalización"],
    });
    expect(result.confianza).toBe(0.92);
  });

  it("rechaza confianza fuera de [0,1]", () => {
    expect(() =>
      NormalizerResponseSchema.parse({
        nombre: "X",
        marca: null,
        categorias: ["otros"],
        confianza: 1.5,
        correcciones: [],
      }),
    ).toThrow();
  });

  it("rechaza categorías fuera de la taxonomía", () => {
    expect(() =>
      NormalizerResponseSchema.parse({
        nombre: "X",
        marca: null,
        categorias: ["inventada"],
        confianza: 0.9,
        correcciones: [],
      }),
    ).toThrow();
  });

  it("rechaza array de categorías vacío", () => {
    expect(() =>
      NormalizerResponseSchema.parse({
        nombre: "X",
        marca: null,
        categorias: [],
        confianza: 0.9,
        correcciones: [],
      }),
    ).toThrow();
  });
});
