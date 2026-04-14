// functions/src/core/openFoodFacts.ts
import { ProductoDraft } from "../types";

export type HttpGet = (url: string) => Promise<unknown>;

export const defaultHttpGet: HttpGet = async (url) => {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`OFF http ${res.status}`);
  return res.json();
};

interface OffResponse {
  status: number;
  product?: {
    code?: string;
    product_name?: string;
    brands?: string;
    categories_tags?: string[];
    image_front_url?: string;
    nutriments?: Record<string, number>;
  };
}

export async function fetchOpenFoodFacts(
  barcode: string,
  httpGet: HttpGet = defaultHttpGet,
): Promise<ProductoDraft | null> {
  const url = `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(barcode)}.json`;
  let data: OffResponse;
  try {
    data = (await httpGet(url)) as OffResponse;
  } catch {
    return null;
  }
  if (data.status !== 1 || !data.product?.product_name) return null;
  const p = data.product;
  const nutr = p.nutriments ?? {};
  const sodioG = nutr["sodium_100g"];
  return {
    barcode,
    nombre: p.product_name ?? "",
    marca: p.brands ?? null,
    categorias: [],
    imagenUrl: p.image_front_url ?? null,
    nutricional: {
      energiaKcal: nutr["energy-kcal_100g"] ?? null,
      proteinasG: nutr["proteins_100g"] ?? null,
      grasasG: nutr["fat_100g"] ?? null,
      carbosG: nutr["carbohydrates_100g"] ?? null,
      sodioMg: typeof sodioG === "number" ? sodioG * 1000 : null,
    },
  };
}
