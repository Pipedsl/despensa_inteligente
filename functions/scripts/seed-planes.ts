// Seed único de planes_config (free + pro) en Firestore producción.
// Ejecutar: npx ts-node scripts/seed-planes.ts  (o compilado: node lib/scripts/seed-planes.js)
// Requiere: GOOGLE_APPLICATION_CREDENTIALS apuntando al service account, o gcloud ADC.
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const PLANES = {
  free: {
    id: "free",
    maxRecetasMes: 3,
    modeloReceta: "gemini-2.0-flash",
    maxHogares: 1,
    maxMiembrosHogar: 4,
    maxProductos: 30,
    historialLimite: 10,
    stripePriceId: null as string | null,
  },
  pro: {
    id: "pro",
    maxRecetasMes: 50,
    modeloReceta: "gemini-2.5-flash",
    maxHogares: 3,
    maxMiembrosHogar: -1,
    maxProductos: 300,
    historialLimite: -1,
    stripePriceId: null as string | null,
  },
};

async function main() {
  initializeApp({
    credential: applicationDefault(),
    projectId: "despensa-inteligente-c1f9d",
  });
  const db = getFirestore();
  for (const [id, data] of Object.entries(PLANES)) {
    await db.collection("planes_config").doc(id).set(data);
    console.log(`✓ planes_config/${id} ← ${JSON.stringify(data)}`);
  }
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
