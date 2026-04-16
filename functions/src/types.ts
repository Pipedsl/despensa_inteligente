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
