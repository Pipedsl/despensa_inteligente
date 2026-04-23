// functions/src/productos/proponerProductoGlobal.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { Timestamp } from "firebase-admin/firestore";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { z } from "zod";
import { db } from "../lib/admin";
import { logEvent } from "../lib/logger";
import { NormalizerIA } from "../core/normalizerOpenAI";
import { createGeminiNormalizer } from "../core/normalizerGemini";
import { mergeProductoGlobal, CONFIANZA_AUTO_MERGE } from "../core/mergeProducto";
import { ProductoDraft, ProductoGlobal, LookupResult } from "../types";

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

const DraftSchema = z.object({
  barcode: z.string().min(1),
  nombre: z.string().min(1),
  marca: z.string().nullable().optional(),
  categorias: z.array(z.string()).optional(),
  imagenUrl: z.string().nullable().optional(),
  nutricional: z
    .object({
      energiaKcal: z.number().nullable(),
      proteinasG: z.number().nullable(),
      grasasG: z.number().nullable(),
      carbosG: z.number().nullable(),
      sodioMg: z.number().nullable(),
    })
    .nullable()
    .optional(),
});

export interface ProponerDeps {
  db: FirebaseFirestore.Firestore;
  normalizer: NormalizerIA;
  now: () => Timestamp;
}

export type ProponerHandler = (
  data: { draft: ProductoDraft },
  uid: string | undefined,
) => Promise<LookupResult>;

export function buildProponerHandler(deps: ProponerDeps): ProponerHandler {
  return async (data, uid) => {
    if (!uid) {
      throw new HttpsError("unauthenticated", "unauthenticated: Sign in required");
    }
    const parsed = DraftSchema.safeParse(data?.draft);
    if (!parsed.success) {
      throw new HttpsError(
        "invalid-argument",
        `draft inválido: ${parsed.error.message}`,
      );
    }
    const draft = parsed.data as ProductoDraft;
    const barcode = draft.barcode!;

    const draftRef = await deps.db
      .collection("productos_globales_drafts")
      .add({
        barcode,
        input: draft,
        uid,
        source: "user",
        normalizerResult: null,
        createdAt: deps.now(),
      });

    const norm = await deps.normalizer.normalize(draft);
    await (draftRef as unknown as { update: (p: Record<string, unknown>) => Promise<void> })
      .update({ normalizerResult: norm });

    const normalizedDraft: ProductoDraft = {
      ...draft,
      nombre: norm.nombre,
      marca: norm.marca,
      categorias: norm.categorias,
    };

    const docRef = deps.db.collection("productos_globales").doc(barcode);
    const snap = await docRef.get();
    const existing = snap.exists ? (snap.data() as ProductoGlobal) : null;

    const merged = mergeProductoGlobal(existing, normalizedDraft, {
      uid,
      confianza: norm.confianza,
      source: "user",
      now: deps.now,
    });
    await docRef.set(merged);

    logEvent("propose.persisted", {
      barcode,
      uid,
      confianza: norm.confianza,
      new: existing === null,
    });

    if (norm.confianza < CONFIANZA_AUTO_MERGE) {
      return { status: "pending_review", draftId: draftRef.id, sugerencia: norm };
    }
    return { status: "found", producto: merged };
  };
}

export const proponerProductoGlobal = onCall(
  { secrets: [GEMINI_API_KEY], region: "us-central1" },
  async (request) => {
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
    const handler = buildProponerHandler({
      db,
      normalizer: createGeminiNormalizer(genAI),
      now: () => Timestamp.now(),
    });
    return handler(request.data, request.auth?.uid);
  },
);
