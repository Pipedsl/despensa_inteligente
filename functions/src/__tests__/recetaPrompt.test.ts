import { describe, it, expect } from "vitest";
import { SYSTEM_PROMPT_RECETA, buildRecetaUserPrompt } from "../recetas/recetaPrompt";

describe("recetaPrompt", () => {
  it("SYSTEM_PROMPT_RECETA es string no vacío", () => {
    expect(typeof SYSTEM_PROMPT_RECETA).toBe("string");
    expect(SYSTEM_PROMPT_RECETA.length).toBeGreaterThan(100);
  });

  it("buildRecetaUserPrompt incluye todos los ingredientes", () => {
    const items = [
      { nombre: "Leche", diasParaVencer: 1 },
      { nombre: "Huevos", diasParaVencer: 5 },
      { nombre: "Harina", diasParaVencer: null },
    ];
    const prompt = buildRecetaUserPrompt(items, undefined);
    expect(prompt).toContain("Leche");
    expect(prompt).toContain("Huevos");
    expect(prompt).toContain("Harina");
  });

  it("buildRecetaUserPrompt marca urgencia cuando vence en ≤3 días", () => {
    const items = [{ nombre: "Leche", diasParaVencer: 1 }];
    const prompt = buildRecetaUserPrompt(items, undefined);
    expect(prompt).toContain("vence en 1");
  });

  it("buildRecetaUserPrompt incluye preferencias cuando se pasan", () => {
    const items = [{ nombre: "Tomate", diasParaVencer: 3 }];
    const prompt = buildRecetaUserPrompt(items, "vegetariano");
    expect(prompt).toContain("vegetariano");
  });

  it("buildRecetaUserPrompt sin preferencias no incluye 'undefined'/'null'", () => {
    const items = [{ nombre: "Queso", diasParaVencer: 2 }];
    const prompt = buildRecetaUserPrompt(items, undefined);
    expect(prompt).not.toContain("undefined");
    expect(prompt).not.toContain("null");
  });
});
