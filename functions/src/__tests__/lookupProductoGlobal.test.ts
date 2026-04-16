// functions/src/__tests__/lookupProductoGlobal.test.ts
import { describe, it, expect } from "vitest";
import {
  buildLookupHandler,
  LookupDeps,
} from "../productos/lookupProductoGlobal";
import { Timestamp } from "firebase-admin/firestore";

const FIXED_NOW = Timestamp.fromMillis(1700000000000);

function makeFakeDb() {
  const store = new Map<string, Record<string, unknown>>();
  return {
    store,
    collection(name: string) {
      return {
        doc: (id: string) => ({
          get: async () => ({
            exists: store.has(`${name}/${id}`),
            data: () => store.get(`${name}/${id}`),
          }),
          set: async (data: Record<string, unknown>) => {
            store.set(`${name}/${id}`, data);
          },
        }),
        add: async (data: Record<string, unknown>) => {
          const id = `draft_${store.size + 1}`;
          store.set(`${name}/${id}`, data);
          return { id };
        },
      };
    },
  };
}

function makeDeps(overrides: Partial<LookupDeps> = {}): LookupDeps {
  const fakeDb = makeFakeDb();
  return {
    db: fakeDb as never,
    fetchFromOFF: async () => null,
    normalizer: {
      normalize: async () => ({
        nombre: "X",
        marca: null,
        categorias: ["otros"],
        confianza: 0.9,
        correcciones: [],
      }),
    },
    now: () => FIXED_NOW,
    ...overrides,
  };
}

describe("lookupProductoGlobal", () => {
  it("rechaza sin auth", async () => {
    const handler = buildLookupHandler(makeDeps());
    await expect(
      handler({ barcode: "123" }, undefined),
    ).rejects.toThrow(/unauthenticated/i);
  });

  it("retorna found cuando existe publicado en DB", async () => {
    const deps = makeDeps();
    (deps.db as never as ReturnType<typeof makeFakeDb>).store.set(
      "productos_globales/7802800000000",
      {
        barcode: "7802800000000",
        nombre: "Leche Soprole 1 L",
        marca: "Soprole",
        categorias: ["lacteos"],
        estado: "publicado",
        imagenUrl: null,
        nutricional: null,
        contribuidores: ["u1"],
        camposFaltantes: ["imagenUrl", "nutricional"],
        aportesPorCampo: {},
        ultimaActualizacion: FIXED_NOW,
        source: "user",
      },
    );
    const handler = buildLookupHandler(deps);
    const res = await handler({ barcode: "7802800000000" }, "u2");
    expect(res.status).toBe("found");
    if (res.status === "found") {
      expect(res.producto.nombre).toBe("Leche Soprole 1 L");
    }
  });

  it("cae a OFF cuando no existe en DB y persiste producto", async () => {
    const deps = makeDeps({
      fetchFromOFF: async () => ({
        barcode: "7802800006003",
        nombre: "Coca-Cola 1.5 L",
        marca: "Coca-Cola",
        categorias: [],
        imagenUrl: "https://img",
        nutricional: {
          energiaKcal: 42,
          proteinasG: 0,
          grasasG: 0,
          carbosG: 10.6,
          sodioMg: 10,
        },
      }),
    });
    const handler = buildLookupHandler(deps);
    const res = await handler({ barcode: "7802800006003" }, "u1");
    expect(res.status).toBe("found");
    const stored = (
      deps.db as never as ReturnType<typeof makeFakeDb>
    ).store.get("productos_globales/7802800006003");
    expect(stored).toBeDefined();
  });

  it("retorna not_found si DB vacía y OFF null", async () => {
    const handler = buildLookupHandler(makeDeps());
    const res = await handler({ barcode: "0000000000000" }, "u1");
    expect(res.status).toBe("not_found");
  });

  it("retorna pending_review si normalizer < 0.8", async () => {
    const deps = makeDeps({
      fetchFromOFF: async () => ({
        barcode: "123",
        nombre: "cosa dudosa",
        marca: null,
        categorias: [],
      }),
      normalizer: {
        normalize: async () => ({
          nombre: "Cosa Dudosa",
          marca: null,
          categorias: ["otros"],
          confianza: 0.5,
          correcciones: [],
        }),
      },
    });
    const handler = buildLookupHandler(deps);
    const res = await handler({ barcode: "123" }, "u1");
    expect(res.status).toBe("pending_review");
  });
});
