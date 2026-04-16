// functions/src/__tests__/mergeProducto.test.ts
import { describe, it, expect } from "vitest";
import { mergeProductoGlobal, nowFactoryForTests } from "../core/mergeProducto";
import { ProductoGlobal } from "../types";
import { Timestamp } from "firebase-admin/firestore";

const FIXED_NOW = Timestamp.fromMillis(1700000000000);
const nowFn = () => FIXED_NOW;

describe("mergeProductoGlobal", () => {
  it("crea producto nuevo con confianza alta → publicado", () => {
    const result = mergeProductoGlobal(
      null,
      {
        barcode: "7802800000000",
        nombre: "Leche Soprole 1 L",
        marca: "Soprole",
        categorias: ["lacteos"],
        imagenUrl: null,
        nutricional: null,
      },
      { uid: "u1", confianza: 0.9, source: "user", now: nowFn },
    );
    expect(result.estado).toBe("publicado");
    expect(result.contribuidores).toEqual(["u1"]);
    expect(result.camposFaltantes).toContain("imagenUrl");
    expect(result.camposFaltantes).toContain("nutricional");
    expect(result.camposFaltantes).not.toContain("marca");
  });

  it("crea producto con confianza baja → pendiente_revision", () => {
    const result = mergeProductoGlobal(
      null,
      { barcode: "1", nombre: "X", marca: null, categorias: ["otros"] },
      { uid: "u1", confianza: 0.5, source: "user", now: nowFn },
    );
    expect(result.estado).toBe("pendiente_revision");
  });

  it("rellena camposFaltantes sin sobrescribir existentes", () => {
    const existing: ProductoGlobal = {
      barcode: "1",
      nombre: "Leche Soprole 1 L",
      marca: "Soprole",
      categorias: ["lacteos"],
      imagenUrl: null,
      nutricional: null,
      contribuidores: ["u1"],
      camposFaltantes: ["imagenUrl", "nutricional"],
      aportesPorCampo: {},
      ultimaActualizacion: FIXED_NOW,
      source: "user",
      estado: "publicado",
    };
    const result = mergeProductoGlobal(
      existing,
      {
        barcode: "1",
        nombre: "Leche Soprole 1 L",
        marca: "Soprole",
        categorias: ["lacteos"],
        imagenUrl: "https://img/leche.jpg",
        nutricional: {
          energiaKcal: 60,
          proteinasG: 3,
          grasasG: 3,
          carbosG: 5,
          sodioMg: 40,
        },
      },
      { uid: "u2", confianza: 0.95, source: "user", now: nowFn },
    );
    expect(result.imagenUrl).toBe("https://img/leche.jpg");
    expect(result.nutricional?.energiaKcal).toBe(60);
    expect(result.camposFaltantes).toEqual([]);
    expect(result.contribuidores).toEqual(["u1", "u2"]);
  });

  it("no sobrescribe nombre existente con un solo aporte distinto", () => {
    const existing: ProductoGlobal = {
      barcode: "1",
      nombre: "Leche Soprole 1 L",
      marca: "Soprole",
      categorias: ["lacteos"],
      imagenUrl: null,
      nutricional: null,
      contribuidores: ["u1"],
      camposFaltantes: ["imagenUrl", "nutricional"],
      aportesPorCampo: {},
      ultimaActualizacion: FIXED_NOW,
      source: "user",
      estado: "publicado",
    };
    const result = mergeProductoGlobal(
      existing,
      {
        barcode: "1",
        nombre: "Leche Colun 1 L",
        marca: null,
        categorias: ["lacteos"],
      },
      { uid: "u2", confianza: 0.95, source: "user", now: nowFn },
    );
    expect(result.nombre).toBe("Leche Soprole 1 L"); // no sobrescrito
    expect(result.aportesPorCampo.nombre?.["Leche Colun 1 L"]).toBe(1);
  });

  it("sobrescribe con mayoría de 3+", () => {
    const existing: ProductoGlobal = {
      barcode: "1",
      nombre: "Leche Soprole 1 L",
      marca: "Soprole",
      categorias: ["lacteos"],
      imagenUrl: null,
      nutricional: null,
      contribuidores: ["u1"],
      camposFaltantes: ["imagenUrl", "nutricional"],
      aportesPorCampo: { nombre: { "Leche Colun 1 L": 2 } },
      ultimaActualizacion: FIXED_NOW,
      source: "user",
      estado: "publicado",
    };
    const result = mergeProductoGlobal(
      existing,
      {
        barcode: "1",
        nombre: "Leche Colun 1 L",
        marca: null,
        categorias: ["lacteos"],
      },
      { uid: "u4", confianza: 0.95, source: "user", now: nowFn },
    );
    expect(result.nombre).toBe("Leche Colun 1 L");
    expect(result.aportesPorCampo.nombre?.["Leche Colun 1 L"]).toBe(3);
  });

  it("no duplica uid en contribuidores", () => {
    const existing: ProductoGlobal = {
      barcode: "1",
      nombre: "X",
      marca: null,
      categorias: ["otros"],
      imagenUrl: null,
      nutricional: null,
      contribuidores: ["u1"],
      camposFaltantes: ["marca", "imagenUrl", "nutricional"],
      aportesPorCampo: {},
      ultimaActualizacion: FIXED_NOW,
      source: "user",
      estado: "publicado",
    };
    const result = mergeProductoGlobal(
      existing,
      { barcode: "1", nombre: "X", marca: null, categorias: ["otros"] },
      { uid: "u1", confianza: 0.9, source: "user", now: nowFn },
    );
    expect(result.contribuidores).toEqual(["u1"]);
  });
});

export { nowFactoryForTests };
