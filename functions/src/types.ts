// functions/src/types.ts
import { Categoria } from "./core/taxonomy";

export interface Nutricional {
  energiaKcal: number | null;
  proteinasG: number | null;
  grasasG: number | null;
  carbosG: number | null;
  sodioMg: number | null;
}

export interface ProductoDraft {
  barcode: string | null;
  nombre: string;
  marca?: string | null;
  categorias?: string[];
  imagenUrl?: string | null;
  nutricional?: Nutricional | null;
}

export interface ProductoGlobal {
  barcode: string;
  nombre: string;
  marca: string | null;
  categorias: Categoria[];
  imagenUrl: string | null;
  nutricional: Nutricional | null;
  contribuidores: string[];
  camposFaltantes: string[];
  aportesPorCampo: Record<string, Record<string, number>>;
  ultimaActualizacion: FirebaseFirestore.Timestamp;
  source: "user" | "openfoodfacts" | "ia";
  estado: "pendiente_revision" | "publicado";
}

export interface NormalizerResponse {
  nombre: string;
  marca: string | null;
  categorias: Categoria[];
  confianza: number;
  correcciones: string[];
}

export type LookupResult =
  | { status: "found"; producto: ProductoGlobal }
  | { status: "pending_review"; draftId: string; sugerencia: NormalizerResponse }
  | { status: "not_found" };

// ──────────────────────────────── Fase 4 — Recetas ────────────────────────────────

export type PlanId = "free" | "pro";

export interface PlanConfig {
  id: PlanId;
  maxRecetasMes: number;     // 3 (free) | 50 (pro)
  modeloReceta: string;      // e.g., "gemini-2.0-flash"
  maxHogares: number;        // 1 | 3
  maxMiembrosHogar: number;  // 4 | -1 (ilimitado)
  maxProductos: number;      // 30 | 300
  historialLimite: number;   // 10 | -1 (completo)
  stripePriceId: string | null;
}

export interface AiUsage {
  month: string;     // "YYYY-MM"
  recetasUsadas: number;
}

export interface RecetaRequest {
  hogarId: string;
  preferencias?: string;
}

export interface RecetaContenido {
  titulo: string;
  pasos: string[];
  tiempo: string;
  porciones: number;
}

export interface Receta {
  id: string;
  generadaPor: string;
  fecha: FirebaseFirestore.Timestamp;
  ingredientesUsados: { nombre: string }[];
  contenido: RecetaContenido;
  modeloIa: string;
  tokensUsados: number;
  fromCache: boolean;
  hashIngredientes: string;
}

export type RecetaResponse =
  | { status: "ok"; receta: RecetaContenido; recetaId: string; fromCache: boolean; recetasRestantes: number }
  | { status: "plan_limit_exceeded"; recetasUsadas: number; maxRecetasMes: number }
  | { status: "despensa_vacia" };
