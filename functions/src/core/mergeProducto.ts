// functions/src/core/mergeProducto.ts
import { Timestamp } from "firebase-admin/firestore";
import {
  ProductoDraft,
  ProductoGlobal,
  Nutricional,
} from "../types";
import { Categoria } from "./taxonomy";

export const CONFIANZA_AUTO_MERGE = 0.8;
export const MAYORIA_OVERRIDE = 3;

export interface MergeContext {
  uid: string;
  confianza: number;
  source: "user" | "openfoodfacts" | "ia";
  now: () => Timestamp;
}

export function nowFactoryForTests(ts: Timestamp) {
  return () => ts;
}

const NUTR_KEYS: (keyof Nutricional)[] = [
  "energiaKcal",
  "proteinasG",
  "grasasG",
  "carbosG",
  "sodioMg",
  "fibraG",
  "azucaresG",
  "grasasSaturadasG",
  "porcionG",
];

function calcCamposFaltantes(p: {
  marca: string | null;
  imagenUrl: string | null;
  nutricional: Nutricional | null;
}): string[] {
  const out: string[] = [];
  if (p.marca === null) out.push("marca");
  if (p.imagenUrl === null) out.push("imagenUrl");
  if (p.nutricional === null) {
    out.push("nutricional");
  } else {
    for (const k of NUTR_KEYS) {
      if (p.nutricional[k] === null) out.push(`nutricional.${k}`);
    }
  }
  return out;
}

function tryOverwrite<T>(
  campo: string,
  current: T,
  incoming: T,
  aportes: Record<string, Record<string, number>>,
): T {
  if (current === incoming) return current;
  const key = String(incoming);
  const bucket = aportes[campo] ?? {};
  bucket[key] = (bucket[key] ?? 0) + 1;
  aportes[campo] = bucket;
  if (bucket[key] >= MAYORIA_OVERRIDE) return incoming;
  return current;
}

export function mergeProductoGlobal(
  existing: ProductoGlobal | null,
  incoming: ProductoDraft,
  ctx: MergeContext,
): ProductoGlobal {
  const now = ctx.now();
  if (existing === null) {
    if (!incoming.barcode) {
      throw new Error("merge: incoming draft requires barcode on create");
    }
    const producto: ProductoGlobal = {
      barcode: incoming.barcode,
      nombre: incoming.nombre,
      marca: incoming.marca ?? null,
      categorias: (incoming.categorias ?? ["otros"]) as Categoria[],
      imagenUrl: incoming.imagenUrl ?? null,
      nutricional: incoming.nutricional ?? null,
      contribuidores: [ctx.uid],
      camposFaltantes: [],
      aportesPorCampo: {},
      ultimaActualizacion: now,
      source: ctx.source,
      estado:
        ctx.confianza >= CONFIANZA_AUTO_MERGE
          ? "publicado"
          : "pendiente_revision",
    };
    producto.camposFaltantes = calcCamposFaltantes(producto);
    return producto;
  }

  // Clone mutable accumulator
  const aportes: Record<string, Record<string, number>> = JSON.parse(
    JSON.stringify(existing.aportesPorCampo),
  );

  const nombre = tryOverwrite("nombre", existing.nombre, incoming.nombre, aportes);
  const marca =
    existing.marca === null
      ? (incoming.marca ?? null)
      : incoming.marca && incoming.marca !== existing.marca
        ? tryOverwrite("marca", existing.marca, incoming.marca, aportes)
        : existing.marca;

  const imagenUrl =
    existing.imagenUrl === null
      ? (incoming.imagenUrl ?? null)
      : existing.imagenUrl;

  // Nutricional: merge por campo
  let nutricional: Nutricional | null;
  if (existing.nutricional === null && incoming.nutricional) {
    nutricional = incoming.nutricional;
  } else if (existing.nutricional && incoming.nutricional) {
    nutricional = { ...existing.nutricional };
    for (const k of NUTR_KEYS) {
      const incomingValue = incoming.nutricional[k];
      if ((nutricional[k] ?? null) === null && incomingValue != null) {
        nutricional[k] = incomingValue;
      }
    }
  } else {
    nutricional = existing.nutricional;
  }

  const contribuidores = existing.contribuidores.includes(ctx.uid)
    ? existing.contribuidores
    : [...existing.contribuidores, ctx.uid];

  const merged: ProductoGlobal = {
    ...existing,
    nombre,
    marca,
    imagenUrl,
    nutricional,
    contribuidores,
    aportesPorCampo: aportes,
    ultimaActualizacion: now,
  };
  merged.camposFaltantes = calcCamposFaltantes(merged);
  return merged;
}
