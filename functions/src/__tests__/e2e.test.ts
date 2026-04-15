// functions/src/__tests__/e2e.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { buildLookupHandler } from "../productos/lookupProductoGlobal";
import { buildProponerHandler } from "../productos/proponerProductoGlobal";

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
}
if (!process.env.GCLOUD_PROJECT) {
  process.env.GCLOUD_PROJECT = "demo-despensa";
}

let db: FirebaseFirestore.Firestore;

beforeAll(() => {
  if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: "demo-despensa" });
  }
  db = admin.firestore();
});

afterAll(async () => {
  await Promise.all(admin.apps.map((app) => app?.delete()));
});

const now = () => Timestamp.fromMillis(1700000000000);

const goodNormalizer = {
  normalize: async () => ({
    nombre: "Leche Soprole 1 L",
    marca: "Soprole",
    categorias: ["lacteos"] as ["lacteos"],
    confianza: 0.92,
    correcciones: [] as string[],
  }),
};

describe("e2e productos globales", () => {
  it("lookup → not_found cuando no hay DB ni OFF", async () => {
    const handler = buildLookupHandler({
      db,
      fetchFromOFF: async () => null,
      normalizer: goodNormalizer,
      now,
    });
    const res = await handler({ barcode: "0000000000001" }, "u1");
    expect(res.status).toBe("not_found");
  });

  it("proponer crea nuevo, segundo proponer hace merge progresivo", async () => {
    const proponer = buildProponerHandler({
      db,
      normalizer: goodNormalizer,
      now,
    });
    const barcode = "7802800007777";

    const r1 = await proponer(
      {
        draft: {
          barcode,
          nombre: "leche soprole 1lt",
          marca: "soprole",
        },
      },
      "u1",
    );
    expect(r1.status).toBe("found");

    // Segundo usuario aporta imagen
    const r2 = await proponer(
      {
        draft: {
          barcode,
          nombre: "leche soprole 1lt",
          marca: "soprole",
          imagenUrl: "https://img/leche.jpg",
        },
      },
      "u2",
    );
    expect(r2.status).toBe("found");

    const snap = await db.collection("productos_globales").doc(barcode).get();
    const stored = snap.data() as { imagenUrl: string | null; contribuidores: string[] };
    expect(stored.imagenUrl).toBe("https://img/leche.jpg");
    expect(stored.contribuidores).toEqual(["u1", "u2"]);
  });

  it("lookup tras merge devuelve producto publicado", async () => {
    const lookup = buildLookupHandler({
      db,
      fetchFromOFF: async () => null,
      normalizer: goodNormalizer,
      now,
    });
    const res = await lookup({ barcode: "7802800007777" }, "u3");
    expect(res.status).toBe("found");
  });
});
