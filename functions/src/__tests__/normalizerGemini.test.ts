import { describe, it, expect, vi } from "vitest";
import { createGeminiNormalizer } from "../core/normalizerGemini";
import type { GoogleGenerativeAI } from "@google/generative-ai";

function fakeGenAI(content: string): GoogleGenerativeAI {
  return {
    getGenerativeModel: vi.fn().mockReturnValue({
      generateContent: vi.fn().mockResolvedValue({
        response: { text: () => content },
      }),
    }),
  } as unknown as GoogleGenerativeAI;
}

describe("normalizerGemini", () => {
  it("parsea respuesta válida", async () => {
    const genAI = fakeGenAI(
      JSON.stringify({
        nombre: "Leche Soprole 1 L",
        marca: "Soprole",
        categorias: ["lacteos"],
        confianza: 0.92,
        correcciones: ["capitalización", "expandido lt a 1 L"],
      }),
    );
    const normalizer = createGeminiNormalizer(genAI);
    const res = await normalizer.normalize({
      barcode: "7802800000000",
      nombre: "leche soprole 1lt",
    });
    expect(res.confianza).toBe(0.92);
    expect(res.categorias).toEqual(["lacteos"]);
  });

  it("rechaza categorías fuera de la taxonomía", async () => {
    const genAI = fakeGenAI(
      JSON.stringify({
        nombre: "Cosa rara",
        marca: null,
        categorias: ["inventada"],
        confianza: 0.9,
        correcciones: [],
      }),
    );
    const normalizer = createGeminiNormalizer(genAI);
    await expect(
      normalizer.normalize({ barcode: null, nombre: "cosa" }),
    ).rejects.toThrow(/taxonomía/i);
  });

  it("rechaza JSON malformado", async () => {
    const genAI = fakeGenAI("no soy json");
    const normalizer = createGeminiNormalizer(genAI);
    await expect(
      normalizer.normalize({ barcode: null, nombre: "cosa" }),
    ).rejects.toThrow();
  });

  it("rechaza confianza fuera de [0,1]", async () => {
    const genAI = fakeGenAI(
      JSON.stringify({
        nombre: "X",
        marca: null,
        categorias: ["otros"],
        confianza: 1.5,
        correcciones: [],
      }),
    );
    const normalizer = createGeminiNormalizer(genAI);
    await expect(
      normalizer.normalize({ barcode: null, nombre: "X" }),
    ).rejects.toThrow();
  });
});
