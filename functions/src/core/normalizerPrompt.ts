// functions/src/core/normalizerPrompt.ts
import { CATEGORIAS } from "./taxonomy";
import { ProductoDraft } from "../types";

export const SYSTEM_PROMPT = `Eres un normalizador de productos de supermercado chilenos.
Recibirás un input con barcode, nombre, marca, categoría y opcionales nutricionales.
Tu trabajo:
1. Corregir typos y capitalización del nombre y la marca.
2. Expandir abreviaciones comunes: "lt" → "1 L", "kg" → "1 kg", "un" → "unidades".
3. Validar que la(s) categoría(s) pertenezcan estrictamente a esta taxonomía cerrada:
   ${CATEGORIAS.join(", ")}.
   Si el producto no encaja en ninguna, usa "otros".
4. Calcular una confianza entre 0 y 1 sobre qué tan seguro estás de que los datos
   corregidos reflejan el producto real. Menor a 0.8 si hay ambigüedad.
5. Listar las correcciones aplicadas en español, máximo 5 ítems.

Responde EXCLUSIVAMENTE con un objeto JSON válido (sin markdown, sin comentarios)
con esta forma exacta:
{
  "nombre": string,
  "marca": string | null,
  "categorias": string[],   // subset de la taxonomía
  "confianza": number,      // 0..1
  "correcciones": string[]
}`;

export function buildUserPrompt(draft: ProductoDraft): string {
  const parts: string[] = [];
  if (draft.barcode) parts.push(`barcode: ${draft.barcode}`);
  parts.push(`nombre: ${draft.nombre}`);
  if (draft.marca) parts.push(`marca: ${draft.marca}`);
  if (draft.categorias?.length) {
    parts.push(`categorias_propuestas: ${draft.categorias.join(", ")}`);
  }
  if (draft.nutricional) {
    parts.push(`nutricional: ${JSON.stringify(draft.nutricional)}`);
  }
  return parts.join("\n");
}
