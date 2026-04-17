import type { Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";
import type { GoogleGenerativeAI } from "@google/generative-ai";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import type { RecetaRequest, RecetaResponse, RecetaContenido } from "../types";
import type { PlanValidatorFn } from "./planValidator";
import { buildPlanValidator } from "./planValidator";
import { SYSTEM_PROMPT_RECETA, buildRecetaUserPrompt } from "./recetaPrompt";
import { hashIngredientes } from "./recetaCache";
import { db as adminDb } from "../lib/admin";
import { logEvent } from "../lib/logger";

export interface GenerarRecetaDeps {
  db: Firestore;
  genAI: GoogleGenerativeAI;
  planValidator: PlanValidatorFn;
  now: () => Date;
}

const CACHE_MAX_DAYS = 7;
const TOP_ITEMS = 10;

export function buildGenerarRecetaHandler(deps: GenerarRecetaDeps) {
  return async (
    data: RecetaRequest,
    uid: string | undefined,
  ): Promise<RecetaResponse> => {
    if (!uid) throw new HttpsError("unauthenticated", "No autenticado");
    const { hogarId, preferencias } = data;
    const now = deps.now();

    // 1. Verificar rate limit
    const validacion = await deps.planValidator(uid, now);
    if (!validacion.ok) {
      return {
        status: "plan_limit_exceeded",
        recetasUsadas: validacion.recetasUsadas,
        maxRecetasMes: validacion.maxRecetasMes,
      };
    }

    // 2. Leer despensa — items activos ordenados por fechaVencimiento
    const despensaSnap = await deps.db
      .collection(`hogares/${hogarId}/despensa`)
      .where("estado", "==", "activo")
      .where("agregadoPor", "!=", "")
      .orderBy("agregadoPor")
      .limit(100)
      .get();

    const todosItems = despensaSnap.docs
      .map((d) => {
        const item = d.data();
        const fv = item.fechaVencimiento;
        const fechaVencimiento = fv
          ? new Date(typeof fv === "number" ? fv : fv.toDate())
          : null;
        return { nombre: item.nombre as string, fechaVencimiento };
      })
      .filter((i) => i.nombre);

    if (todosItems.length === 0) return { status: "despensa_vacia" };

    const ordenados = [...todosItems].sort((a, b) => {
      if (!a.fechaVencimiento && !b.fechaVencimiento) return 0;
      if (!a.fechaVencimiento) return 1;
      if (!b.fechaVencimiento) return -1;
      return a.fechaVencimiento.getTime() - b.fechaVencimiento.getTime();
    });
    const top = ordenados.slice(0, TOP_ITEMS);
    const nombres = top.map((i) => i.nombre);
    const hash = hashIngredientes(nombres);

    // 3. Buscar en cache (<7 días, mismo hash)
    const recetasSnap = await deps.db
      .doc(`hogares/${hogarId}`)
      .collection("recetas")
      .where("hashIngredientes", "==", hash)
      .orderBy("fecha", "desc")
      .get();

    if (!recetasSnap.empty) {
      const ultima = recetasSnap.docs[0];
      const fechaReceta: Date = ultima.data().fecha?.toDate?.() ?? new Date(0);
      const diffDays = (now.getTime() - fechaReceta.getTime()) / 86400000;
      if (diffDays < CACHE_MAX_DAYS) {
        return {
          status: "ok",
          receta: ultima.data().contenido as RecetaContenido,
          recetaId: ultima.id,
          fromCache: true,
          recetasRestantes: validacion.recetasRestantes,
        };
      }
    }

    // 4. Llamar a Gemini
    const itemsParaPrompt = top.map((i) => ({
      nombre: i.nombre,
      diasParaVencer: i.fechaVencimiento
        ? Math.ceil((i.fechaVencimiento.getTime() - now.getTime()) / 86400000)
        : null,
    }));

    const model = deps.genAI.getGenerativeModel({
      model: validacion.plan!.modeloReceta,
      systemInstruction: SYSTEM_PROMPT_RECETA,
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.7,
        maxOutputTokens: 800,
      } as any,
    });

    const geminiResult = await model.generateContent(
      buildRecetaUserPrompt(itemsParaPrompt, preferencias),
    );

    const raw = geminiResult.response.text();
    const contenido = JSON.parse(raw) as RecetaContenido;
    const tokensUsados =
      (geminiResult.response as any).usageMetadata?.totalTokenCount ?? 0;
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

    // 5. Persistir receta + actualizar aiUsage
    const recetaRef = await deps.db
      .doc(`hogares/${hogarId}`)
      .collection("recetas")
      .add({
        generadaPor: uid,
        fecha: now,
        ingredientesUsados: nombres.map((n) => ({ nombre: n })),
        contenido,
        modeloIa: validacion.plan!.modeloReceta,
        tokensUsados,
        fromCache: false,
        hashIngredientes: hash,
      });

    await deps.db.doc(`usuarios/${uid}`).update({
      "aiUsage.month": currentMonth,
      "aiUsage.recetasUsadas": FieldValue.increment(1),
    });

    logEvent("receta_generada", {
      uid,
      hogarId,
      recetaId: recetaRef.id,
      modelo: validacion.plan!.modeloReceta,
      tokensUsados,
    });

    return {
      status: "ok",
      receta: contenido,
      recetaId: recetaRef.id,
      fromCache: false,
      recetasRestantes: validacion.recetasRestantes - 1,
    };
  };
}

export const generarReceta = onCall(
  { secrets: ["GEMINI_API_KEY"], enforceAppCheck: false },
  async (req) => {
    const { GoogleGenerativeAI } = await import("@google/generative-ai");
    const genAIClient = new GoogleGenerativeAI(
      process.env.GEMINI_API_KEY ?? "",
    );
    const handler = buildGenerarRecetaHandler({
      db: adminDb,
      genAI: genAIClient,
      planValidator: buildPlanValidator(adminDb),
      now: () => new Date(),
    });
    return handler(req.data as RecetaRequest, req.auth?.uid);
  },
);
