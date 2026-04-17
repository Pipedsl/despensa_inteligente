import type { Firestore } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import type { FlowClient } from "./flowClient";
import { buildFlowClient } from "./flowClient";
import { db as adminDb } from "../lib/admin";
import { logEvent } from "../lib/logger";

const FLOW_API_KEY = defineSecret("FLOW_API_KEY");
const FLOW_SECRET_KEY = defineSecret("FLOW_SECRET_KEY");
const FLOW_URL_RETURN_BASE = defineSecret("FLOW_URL_RETURN_BASE");
const FLOW_BASE_URL = defineSecret("FLOW_BASE_URL");

export interface CrearSuscripcionFlowDeps {
  db: Firestore;
  flow: FlowClient;
  urlReturnBase: string;
}

export interface CrearSuscripcionFlowResponse {
  url: string;
  token: string;
}

export function buildCrearSuscripcionFlowHandler(deps: CrearSuscripcionFlowDeps) {
  return async (uid: string | undefined): Promise<CrearSuscripcionFlowResponse> => {
    if (!uid) throw new HttpsError("unauthenticated", "No autenticado");

    const usuarioRef = deps.db.doc(`usuarios/${uid}`);
    const snap = await usuarioRef.get();
    if (!snap.exists) throw new HttpsError("not-found", "Usuario no existe");

    const data = snap.data() ?? {};
    const email = data.email as string | undefined;
    const nombre = (data.nombre as string | undefined) ?? email ?? uid;
    if (!email) throw new HttpsError("failed-precondition", "Usuario sin email");

    let customerId = data.flowCustomerId as string | undefined;
    if (!customerId) {
      const customer = await deps.flow.createCustomer({
        name: nombre,
        email,
        externalId: uid,
      });
      customerId = customer.customerId;
      await usuarioRef.update({ flowCustomerId: customerId });
      logEvent("flow_customer_created", { uid, customerId });
    }

    const register = await deps.flow.registerCustomerCard({
      customerId,
      url_return: `${deps.urlReturnBase}?uid=${uid}`,
    });

    logEvent("flow_register_initiated", { uid, customerId, token: register.token });

    return { url: register.url, token: register.token };
  };
}

export const crearSuscripcionFlow = onCall(
  {
    secrets: [FLOW_API_KEY, FLOW_SECRET_KEY, FLOW_URL_RETURN_BASE, FLOW_BASE_URL],
    enforceAppCheck: false,
  },
  async (req) => {
    const flow = buildFlowClient({
      apiKey: FLOW_API_KEY.value(),
      secretKey: FLOW_SECRET_KEY.value(),
      baseUrl: FLOW_BASE_URL.value(),
    });
    const handler = buildCrearSuscripcionFlowHandler({
      db: adminDb,
      flow,
      urlReturnBase: FLOW_URL_RETURN_BASE.value(),
    });
    return handler(req.auth?.uid);
  },
);
