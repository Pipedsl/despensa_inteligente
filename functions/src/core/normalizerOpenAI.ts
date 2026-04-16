import { z } from "zod";
import type { ProductoDraft, NormalizerResponse } from "../types";
import { CATEGORIAS } from "./taxonomy";

// Esquema de validación compartido entre implementaciones del normalizer
export const NormalizerResponseSchema = z.object({
  nombre: z.string().min(1),
  marca: z.string().nullable(),
  categorias: z
    .array(z.enum(CATEGORIAS as unknown as [string, ...string[]]))
    .min(1),
  confianza: z.number().min(0).max(1),
  correcciones: z.array(z.string()).max(5),
});

// Interfaz que todas las implementaciones del normalizer deben cumplir
export interface NormalizerIA {
  normalize(draft: ProductoDraft): Promise<NormalizerResponse>;
}
