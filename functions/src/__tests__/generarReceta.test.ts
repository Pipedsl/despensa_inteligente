import { describe, it, expect, vi } from "vitest";
import { buildGenerarRecetaHandler } from "../recetas/generarReceta";
import type { PlanConfig } from "../types";

const FREE_PLAN: PlanConfig = {
  id: "free",
  maxRecetasMes: 3,
  modeloReceta: "gemini-2.0-flash",
  maxHogares: 1,
  maxMiembrosHogar: 4,
  maxProductos: 30,
  historialLimite: 10,
  stripePriceId: null,
};

function makeFakeDb(despensaItems: any[], recetasExistentes: any[] = []) {
  const docs: Record<string, any> = {};
  return {
    doc: (path: string) => ({
      get: async () => {
        if (docs[path]) return { exists: true, data: () => docs[path] };
        return { exists: false, data: () => undefined };
      },
      set: async (data: any, opts?: any) => {
        docs[path] = opts?.merge ? { ...docs[path], ...data } : data;
      },
      update: async (data: any) => {
        docs[path] = { ...docs[path], ...data };
      },
      collection: (_sub: string) => ({
        add: async (data: any) => {
          const id = `receta_${Date.now()}`;
          docs[`${path}/${_sub}/${id}`] = { ...data, id };
          return { id };
        },
        where: () => ({
          orderBy: () => ({
            get: async () => ({
              docs: recetasExistentes.map((r) => ({ id: r.id, data: () => r })),
              empty: recetasExistentes.length === 0,
            }),
          }),
        }),
      }),
    }),
    collection: (_col: string) => ({
      where: () => ({
        where: () => ({
          orderBy: () => ({
            limit: () => ({
              get: async () => ({
                docs: despensaItems.map((item, i) => ({
                  id: `item_${i}`,
                  data: () => item,
                })),
              }),
            }),
          }),
        }),
      }),
    }),
  };
}

const FAKE_RECETA_CONTENIDO = {
  titulo: "Tortilla de papas",
  pasos: ["Pelar papas.", "Freír con aceite."],
  tiempo: "20 minutos",
  porciones: 2,
};

function makeFakeGenAI(response: any = FAKE_RECETA_CONTENIDO) {
  const generateContent = vi.fn().mockResolvedValue({
    response: {
      text: () => JSON.stringify(response),
      usageMetadata: { totalTokenCount: 500 },
    },
  });
  return {
    getGenerativeModel: vi.fn().mockReturnValue({ generateContent }),
    _generateContent: generateContent,
  };
}

const now = new Date("2026-04-16T10:00:00Z");

const despensaItems = [
  { nombre: "Leche", estado: "activo", fechaVencimiento: now.getTime() + 86400000 },
  { nombre: "Huevos", estado: "activo", fechaVencimiento: now.getTime() + 2 * 86400000 },
  { nombre: "Harina", estado: "activo", fechaVencimiento: null },
];

describe("buildGenerarRecetaHandler", () => {
  it("devuelve plan_limit_exceeded si cuota agotada", async () => {
    const validator = vi.fn().mockResolvedValue({
      ok: false,
      plan: FREE_PLAN,
      recetasRestantes: 0,
      recetasUsadas: 3,
      maxRecetasMes: 3,
    });
    const handler = buildGenerarRecetaHandler({
      db: makeFakeDb([]) as any,
      genAI: makeFakeGenAI() as any,
      planValidator: validator,
      now: () => now,
    });
    const result = await handler({ hogarId: "hogar1" }, "uid1");
    expect(result.status).toBe("plan_limit_exceeded");
  });

  it("devuelve despensa_vacia si no hay items activos", async () => {
    const validator = vi.fn().mockResolvedValue({
      ok: true,
      plan: FREE_PLAN,
      recetasRestantes: 3,
      recetasUsadas: 0,
      maxRecetasMes: 3,
    });
    const handler = buildGenerarRecetaHandler({
      db: makeFakeDb([]) as any,
      genAI: makeFakeGenAI() as any,
      planValidator: validator,
      now: () => now,
    });
    const result = await handler({ hogarId: "hogar1" }, "uid1");
    expect(result.status).toBe("despensa_vacia");
  });

  it("genera receta ok y llama a Gemini", async () => {
    const validator = vi.fn().mockResolvedValue({
      ok: true,
      plan: FREE_PLAN,
      recetasRestantes: 3,
      recetasUsadas: 0,
      maxRecetasMes: 3,
    });
    const fakeGenAI = makeFakeGenAI();
    const handler = buildGenerarRecetaHandler({
      db: makeFakeDb(despensaItems) as any,
      genAI: fakeGenAI as any,
      planValidator: validator,
      now: () => now,
    });
    const result = await handler({ hogarId: "hogar1" }, "uid1");
    expect(result.status).toBe("ok");
    if (result.status === "ok") {
      expect(result.receta.titulo).toBe("Tortilla de papas");
      expect(result.fromCache).toBe(false);
    }
    expect(fakeGenAI._generateContent).toHaveBeenCalledOnce();
  });

  it("retorna cache hit sin llamar a Gemini si hash coincide en <7 días", async () => {
    const { hashIngredientes } = await import("../recetas/recetaCache");
    const nombres = despensaItems.map((i) => i.nombre);
    const hash = hashIngredientes(nombres);

    const recetaCacheada = {
      id: "receta_cached",
      hashIngredientes: hash,
      fecha: { toDate: () => new Date(now.getTime() - 3 * 86400000) },
      contenido: FAKE_RECETA_CONTENIDO,
      fromCache: false,
      modeloIa: "gemini-2.0-flash",
      tokensUsados: 500,
      generadaPor: "uid1",
      ingredientesUsados: nombres.map((n) => ({ nombre: n })),
    };

    const validator = vi.fn().mockResolvedValue({
      ok: true,
      plan: FREE_PLAN,
      recetasRestantes: 3,
      recetasUsadas: 0,
      maxRecetasMes: 3,
    });
    const fakeGenAI = makeFakeGenAI();
    const handler = buildGenerarRecetaHandler({
      db: makeFakeDb(despensaItems, [recetaCacheada]) as any,
      genAI: fakeGenAI as any,
      planValidator: validator,
      now: () => now,
    });
    const result = await handler({ hogarId: "hogar1" }, "uid1");
    expect(result.status).toBe("ok");
    if (result.status === "ok") {
      expect(result.fromCache).toBe(true);
    }
    expect(fakeGenAI._generateContent).not.toHaveBeenCalled();
  });
});
