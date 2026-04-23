import type { Firestore } from "firebase-admin/firestore";
import type Stripe from "stripe";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import type { CheckoutRequest, CheckoutResponse } from "../types";
import { db as adminDb } from "../lib/admin";
import { logEvent } from "../lib/logger";

export interface CrearCheckoutSessionDeps {
  db: Firestore;
  stripe: {
    sessions: {
      create: (params: Stripe.Checkout.SessionCreateParams) => Promise<Pick<Stripe.Checkout.Session, "url" | "id">>;
    };
  };
}

export function buildCrearCheckoutSessionHandler(deps: CrearCheckoutSessionDeps) {
  return async (
    data: CheckoutRequest,
    uid: string | undefined,
  ): Promise<CheckoutResponse> => {
    if (!uid) throw new HttpsError("unauthenticated", "No autenticado");

    const { priceId, successUrl, cancelUrl } = data;

    const usuarioSnap = await deps.db.doc(`usuarios/${uid}`).get();
    const usuarioData = usuarioSnap.data() ?? {};
    const email = usuarioData.email as string | undefined;
    const existingCustomerId = usuarioData.stripeCustomerId as string | undefined;

    const sessionParams: Stripe.Checkout.SessionCreateParams = {
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [{ price: priceId, quantity: 1 }],
      client_reference_id: uid,
      success_url: successUrl,
      cancel_url: cancelUrl,
      ...(existingCustomerId
        ? { customer: existingCustomerId }
        : email
          ? { customer_email: email }
          : {}),
    };

    const session = await deps.stripe.sessions.create(sessionParams);

    if (!session.url) {
      throw new HttpsError("internal", "Stripe no devolvió URL de checkout");
    }

    logEvent("checkout_session_created", { uid, sessionId: session.id, priceId });

    return { url: session.url };
  };
}

export const crearCheckoutSession = onCall(
  { secrets: ["STRIPE_SECRET_KEY"], enforceAppCheck: false },
  async (req) => {
    const Stripe = (await import("stripe")).default;
    const stripeClient = new Stripe(process.env.STRIPE_SECRET_KEY ?? "", {
      apiVersion: "2024-06-20",
    });
    const handler = buildCrearCheckoutSessionHandler({
      db: adminDb,
      stripe: stripeClient.checkout,
    });
    return handler(req.data as CheckoutRequest, req.auth?.uid);
  },
);
