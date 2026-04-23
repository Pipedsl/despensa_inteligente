// functions/src/__tests__/proponerProductoGlobal.test.ts
import { describe, it, expect } from "vitest";
import { buildProponerHandler, ProponerDeps } from "../productos/proponerProductoGlobal";
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
          const id = `d${store.size + 1}`;
          store.set(`${name}/${id}`, data);
          return {
            id,
            update: async (patch: Record<string, unknown>) => {
              store.set(`${name}/${id}`, {
                ...(store.get(`${name}/${id}`) ?? {}),
                ...patch,
              });
            },
          };
        },
      };
    },
  };
}

function makeDeps(overrides: Partial<ProponerDeps> = {}): ProponerDeps {
  return {
    db: makeFakeDb() as never,
    normalizer: {
      normalize: async () => ({
        nombre: "Leche Soprole 1 L",
        marca: "Soprole",
        categorias: ["lacteos"],
        confianza: 0.92,
        correcciones: ["capitalización"],
      }),
    },
    now: () => FIXED_NOW,
    ...overrides,
  };
}

describe("proponerProductoGlobal", () => {
  it("rechaza sin auth", async () => {
    const handler = buildProponerHandler(makeDeps());
    await expect(
      handler(
        { draft: { barcode: "1", nombre: "X" } },
        undefined,
      ),
    ).rejects.toThrow(/unauthenticated/i);
  });

  it("rechaza draft sin barcode", async () => {
    const handler = buildProponerHandler(makeDeps());
    await expect(
      handler({ draft: { barcode: "", nombre: "X" } }, "u1"),
    ).rejects.toThrow(/barcode/);
  });

  it("crea producto nuevo con confianza alta → publicado", async () => {
    const deps = makeDeps();
    const handler = buildProponerHandler(deps);
    const res = await handler(
      {
        draft: {
          barcode: "7802800000000",
          nombre: "leche soprole 1lt",
          marca: "soprole",
        },
      },
      "u1",
    );
    expect(res.status).toBe("found");
    const stored = (
      deps.db as never as ReturnType<typeof makeFakeDb>
    ).store.get("productos_globales/7802800000000") as {
      estado: string;
    };
    expect(stored.estado).toBe("publicado");
  });

  it("devuelve pending_review si normalizer < 0.8", async () => {
    const deps = makeDeps({
      normalizer: {
        normalize: async () => ({
          nombre: "Dudoso",
          marca: null,
          categorias: ["otros"],
          confianza: 0.5,
          correcciones: [],
        }),
      },
    });
    const handler = buildProponerHandler(deps);
    const res = await handler(
      { draft: { barcode: "1", nombre: "dudoso" } },
      "u1",
    );
    expect(res.status).toBe("pending_review");
  });

  it("merge progresivo: segundo usuario rellena imagenUrl", async () => {
    const deps = makeDeps();
    const fakeDb = deps.db as never as ReturnType<typeof makeFakeDb>;
    fakeDb.store.set("productos_globales/1", {
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
    });
    const handler = buildProponerHandler(deps);
    await handler(
      {
        draft: {
          barcode: "1",
          nombre: "Leche Soprole 1 L",
          marca: "Soprole",
          imagenUrl: "https://img",
        },
      },
      "u2",
    );
    const stored = fakeDb.store.get("productos_globales/1") as {
      imagenUrl: string | null;
      contribuidores: string[];
      camposFaltantes: string[];
    };
    expect(stored.imagenUrl).toBe("https://img");
    expect(stored.contribuidores).toEqual(["u1", "u2"]);
    expect(stored.camposFaltantes).not.toContain("imagenUrl");
  });

  it("acepta y persiste campos nutricionales extendidos (fibra, azúcares, grasas saturadas, porción)", async () => {
    const deps = makeDeps();
    const handler = buildProponerHandler(deps);
    await handler(
      {
        draft: {
          barcode: "7802811111111",
          nombre: "galletas integrales",
          marca: "marca",
          nutricional: {
            energiaKcal: 450,
            proteinasG: 8,
            grasasG: 15,
            carbosG: 65,
            sodioMg: 200,
            fibraG: 6,
            azucaresG: 12,
            grasasSaturadasG: 3,
            porcionG: 30,
          },
        },
      },
      "u1",
    );
    const stored = (
      deps.db as never as ReturnType<typeof makeFakeDb>
    ).store.get("productos_globales/7802811111111") as {
      nutricional: {
        fibraG: number | null;
        azucaresG: number | null;
        grasasSaturadasG: number | null;
        porcionG: number | null;
      };
    };
    expect(stored.nutricional.fibraG).toBe(6);
    expect(stored.nutricional.azucaresG).toBe(12);
    expect(stored.nutricional.grasasSaturadasG).toBe(3);
    expect(stored.nutricional.porcionG).toBe(30);
  });
});
