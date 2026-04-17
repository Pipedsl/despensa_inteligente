import { describe, it, expect } from "vitest";
import { buildPlanValidator } from "../recetas/planValidator";
import type { PlanConfig, AiUsage } from "../types";

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

const PRO_PLAN: PlanConfig = {
  id: "pro",
  maxRecetasMes: 50,
  modeloReceta: "gemini-2.5-flash",
  maxHogares: 3,
  maxMiembrosHogar: -1,
  maxProductos: 300,
  historialLimite: -1,
  stripePriceId: null,
};

function makeFakeDb(planId: "free" | "pro", usage: AiUsage | null) {
  return {
    doc: (path: string) => ({
      get: async () => {
        if (path.startsWith("usuarios/")) {
          return {
            exists: true,
            data: () => ({ plan: planId, aiUsage: usage }),
          };
        }
        if (path.startsWith("planes_config/")) {
          const plan = path.endsWith("free") ? FREE_PLAN : PRO_PLAN;
          return { exists: true, data: () => plan };
        }
        throw new Error("unexpected path: " + path);
      },
    }),
  };
}

describe("buildPlanValidator", () => {
  const now = new Date("2026-04-16T10:00:00Z");
  const currentMonth = "2026-04";

  it("ok cuando free no ha usado recetas este mes", async () => {
    const db = makeFakeDb("free", null);
    const validator = buildPlanValidator(db as never);
    const result = await validator("uid123", now);
    expect(result.ok).toBe(true);
    expect(result.plan!.modeloReceta).toBe("gemini-2.0-flash");
    expect(result.recetasRestantes).toBe(3);
  });

  it("ok cuando free tiene 2 de 3 usadas", async () => {
    const db = makeFakeDb("free", { month: currentMonth, recetasUsadas: 2 });
    const validator = buildPlanValidator(db as never);
    const result = await validator("uid123", now);
    expect(result.ok).toBe(true);
    expect(result.recetasRestantes).toBe(1);
  });

  it("blocked cuando free agotó las 3 recetas del mes", async () => {
    const db = makeFakeDb("free", { month: currentMonth, recetasUsadas: 3 });
    const validator = buildPlanValidator(db as never);
    const result = await validator("uid123", now);
    expect(result.ok).toBe(false);
    expect(result.recetasRestantes).toBe(0);
  });

  it("resetea contador si el mes cambió", async () => {
    const db = makeFakeDb("free", { month: "2026-03", recetasUsadas: 3 });
    const validator = buildPlanValidator(db as never);
    const result = await validator("uid123", now);
    expect(result.ok).toBe(true);
    expect(result.recetasRestantes).toBe(3);
  });

  it("pro con 49 recetas usadas sigue ok", async () => {
    const db = makeFakeDb("pro", { month: currentMonth, recetasUsadas: 49 });
    const validator = buildPlanValidator(db as never);
    const result = await validator("uid123", now);
    expect(result.ok).toBe(true);
    expect(result.recetasRestantes).toBe(1);
  });
});
