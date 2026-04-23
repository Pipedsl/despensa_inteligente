import type { Firestore } from "firebase-admin/firestore";
import type { PlanConfig, AiUsage, PlanId } from "../types";

export interface PlanValidationResult {
  ok: boolean;
  plan: PlanConfig | null;
  recetasRestantes: number;
  recetasUsadas: number;
  maxRecetasMes: number;
}

export type PlanValidatorFn = (
  uid: string,
  now: Date,
) => Promise<PlanValidationResult>;

export function buildPlanValidator(db: Firestore): PlanValidatorFn {
  return async (uid, now) => {
    const usuarioSnap = await db.doc(`usuarios/${uid}`).get();
    const usuarioData = usuarioSnap.data() ?? {};
    const planId: PlanId = (usuarioData.plan as PlanId) ?? "free";

    const planSnap = await db.doc(`planes_config/${planId}`).get();
    const plan = planSnap.data() as PlanConfig;

    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    const rawUsage = usuarioData.aiUsage as AiUsage | null | undefined;
    const recetasUsadas =
      rawUsage && rawUsage.month === currentMonth ? rawUsage.recetasUsadas : 0;

    const recetasRestantes = Math.max(0, plan.maxRecetasMes - recetasUsadas);
    const ok = recetasRestantes > 0;

    return { ok, plan, recetasRestantes, recetasUsadas, maxRecetasMes: plan.maxRecetasMes };
  };
}
