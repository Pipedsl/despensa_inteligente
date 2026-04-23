import { describe, it, expect } from "vitest";
import { hashIngredientes } from "../recetas/recetaCache";

describe("hashIngredientes", () => {
  it("devuelve string no vacío para lista de nombres", () => {
    const hash = hashIngredientes(["Leche", "Huevos", "Harina"]);
    expect(typeof hash).toBe("string");
    expect(hash.length).toBeGreaterThan(0);
  });

  it("es determinista — mismo input, mismo hash", () => {
    const a = hashIngredientes(["Leche", "Huevos"]);
    const b = hashIngredientes(["Leche", "Huevos"]);
    expect(a).toBe(b);
  });

  it("es insensible al orden — {A,B} == {B,A}", () => {
    const a = hashIngredientes(["Leche", "Huevos"]);
    const b = hashIngredientes(["Huevos", "Leche"]);
    expect(a).toBe(b);
  });

  it("listas distintas producen hashes distintos", () => {
    const a = hashIngredientes(["Leche"]);
    const b = hashIngredientes(["Leche", "Huevos"]);
    expect(a).not.toBe(b);
  });
});
