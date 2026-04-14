import { describe, it, expect, vi } from "vitest";
import {
  createOpenAINormalizer,
  NormalizerResponseSchema,
} from "../core/normalizerOpenAI";

function fakeOpenAI(content: string) {
  return {
    chat: {
      completions: {
        create: vi.fn().mockResolvedValue({
          choices: [{ message: { content } }],
          usage: { prompt_tokens: 100, completion_tokens: 50 },
        }),
      },
    },
  };
}

describe("normalizerOpenAI", () => {
  it("parsea respuesta válida", async () => {
    const openai = fakeOpenAI(
      JSON.stringify({
        nombre: "Leche Soprole 1 L",
        marca: "Soprole",
        categorias: ["lacteos"],
        confianza: 0.92,
        correcciones: ["capitalización", "expandido lt a 1 L"],
      }),
    );
    const normalizer = createOpenAINormalizer(openai as never);
    const res = await normalizer.normalize({
      barcode: "7802800000000",
      nombre: "leche soprole 1lt",
    });
    expect(res.confianza).toBe(0.92);
    expect(res.categorias).toEqual(["lacteos"]);
  });

  it("rechaza categorías fuera de la taxonomía", async () => {
    const openai = fakeOpenAI(
      JSON.stringify({
        nombre: "Cosa rara",
        marca: null,
        categorias: ["inventada"],
        confianza: 0.9,
        correcciones: [],
      }),
    );
    const normalizer = createOpenAINormalizer(openai as never);
    await expect(
      normalizer.normalize({ barcode: null, nombre: "cosa" }),
    ).rejects.toThrow(/taxonomía/i);
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

  it("rechaza JSON malformado", async () => {
    const openai = fakeOpenAI("no soy json");
    const normalizer = createOpenAINormalizer(openai as never);
    await expect(
      normalizer.normalize({ barcode: null, nombre: "cosa" }),
    ).rejects.toThrow();
  });
});
