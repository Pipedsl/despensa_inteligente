// functions/src/productos/lookupProductoGlobal.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { Timestamp } from "firebase-admin/firestore";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { db } from "../lib/admin";
import { logEvent } from "../lib/logger";
import {
  fetchOpenFoodFacts,
  HttpGet,
  defaultHttpGet,
} from "../core/openFoodFacts";
import { NormalizerIA } from "../core/normalizerOpenAI";
import { createGeminiNormalizer } from "../core/normalizerGemini";
import {
  mergeProductoGlobal,
  CONFIANZA_AUTO_MERGE,
} from "../core/mergeProducto";
import {
  ProductoDraft,
  ProductoGlobal,
  LookupResult,
} from "../types";

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

export interface LookupDeps {
  db: FirebaseFirestore.Firestore;
  fetchFromOFF: (barcode: string) => Promise<ProductoDraft | null>;
  normalizer: NormalizerIA;
  now: () => Timestamp;
}

export type LookupHandler = (
  data: { barcode: string },
  uid: string | undefined,
) => Promise<LookupResult>;

export function buildLookupHandler(deps: LookupDeps): LookupHandler {
  return async (data, uid) => {
    if (!uid) {
      throw new HttpsError("unauthenticated", "unauthenticated: Sign in required");
    }
    const barcode = (data?.barcode ?? "").trim();
    if (!barcode) {
      throw new HttpsError("invalid-argument", "barcode is required");
    }

    const docRef = deps.db.collection("productos_globales").doc(barcode);
    const snap = await docRef.get();
    if (snap.exists) {
      const producto = snap.data() as ProductoGlobal;
      if (producto.estado === "publicado") {
        logEvent("lookup.hit_db", { barcode, uid });
        return { status: "found", producto };
      }
    }

    const offDraft = await deps.fetchFromOFF(barcode);
    if (!offDraft) {
      logEvent("lookup.not_found", { barcode, uid });
      return { status: "not_found" };
    }

    // Draft de OFF → normalizar + merge
    const draftCol = deps.db.collection("productos_globales_drafts");
    const draftRef = await draftCol.add({
      barcode,
      input: offDraft,
      uid,
      source: "openfoodfacts",
      normalizerResult: null,
      createdAt: deps.now(),
    });

    const norm = await deps.normalizer.normalize(offDraft);
    const normalizedDraft: ProductoDraft = {
      ...offDraft,
      nombre: norm.nombre,
      marca: norm.marca,
      categorias: norm.categorias,
    };

    const merged = mergeProductoGlobal(null, normalizedDraft, {
      uid,
      confianza: norm.confianza,
      source: "openfoodfacts",
      now: deps.now,
    });
    await docRef.set(merged);

    logEvent("lookup.off_persisted", {
      barcode,
      uid,
      confianza: norm.confianza,
    });

    if (norm.confianza < CONFIANZA_AUTO_MERGE) {
      return {
        status: "pending_review",
        draftId: draftRef.id,
        sugerencia: norm,
      };
    }
    return { status: "found", producto: merged };
  };
}

export const lookupProductoGlobal = onCall(
  { secrets: [GEMINI_API_KEY], region: "us-central1" },
  async (request) => {
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
    const handler = buildLookupHandler({
      db,
      fetchFromOFF: (bc) => fetchOpenFoodFacts(bc, defaultHttpGet as HttpGet),
      normalizer: createGeminiNormalizer(genAI),
      now: () => Timestamp.now(),
    });
    return handler(request.data, request.auth?.uid);
  },
);
