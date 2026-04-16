// functions/src/core/taxonomy.ts
export const CATEGORIAS = [
  "lacteos",
  "bebidas",
  "snacks",
  "panaderia",
  "carnes",
  "frutas_verduras",
  "congelados",
  "abarrotes",
  "limpieza",
  "higiene",
  "bebes",
  "mascotas",
  "otros",
] as const;

export type Categoria = (typeof CATEGORIAS)[number];

export function isValidCategoria(value: string): value is Categoria {
  return (CATEGORIAS as readonly string[]).includes(value);
}
