import type { Firestore } from "firebase-admin/firestore";
import type Stripe from "stripe";
import { onRequest } from "firebase-functions/v2/https";
import type { Request, Response } from "express";
import { db as adminDb } from "../lib/admin";
import { logEvent } from "../lib/logger";

export interface StripeWebhookDeps {
  db: Firestore;
  stripe: Pick<Stripe, "webhooks">;
  webhookSecret: string;
}

export function buildStripeWebhookHandler(deps: StripeWebhookDeps) {
  return async (req: Request, res: Response): Promise<void> => {
    const sig = req.headers["stripe-signature"] as string | undefined;
    // Firebase Functions v2 exposes rawBody (Buffer) before any JSON parsing
    const rawBody: Buffer = (req as any).rawBody ?? Buffer.from(JSON.stringify(req.body));

    let event: Stripe.Event;
    try {
      event = deps.stripe.webhooks.constructEvent(
        rawBody,
        sig ?? "",
        deps.webhookSecret,
      ) as Stripe.Event;
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Webhook signature verification failed";
      logEvent("webhook_signature_invalid", { error: msg });
      res.status(400).send(`Webhook Error: ${msg}`);
      return;
    }

    try {
      switch (event.type) {
        case "checkout.session.completed": {
          const session = event.data.object as Stripe.Checkout.Session;
          const uid = session.client_reference_id;
          if (!uid) { logEvent("webhook_missing_uid", { sessionId: session.id }); break; }
          await deps.db.doc(`usuarios/${uid}`).update({
            plan: "pro",
            stripeCustomerId: session.customer as string,
            stripeSubscriptionId: session.subscription as string,
          });
          logEvent("plan_upgraded_to_pro", { uid, sessionId: session.id });
          break;
        }

        case "checkout.session.expired": {
          const session = event.data.object as Stripe.Checkout.Session;
          const uid = session.client_reference_id;
          if (!uid) break;
          await deps.db.doc(`usuarios/${uid}`).update({ plan: "free" });
          logEvent("checkout_session_expired", { uid });
          break;
        }

        case "customer.subscription.deleted": {
          const subscription = event.data.object as Stripe.Subscription;
          const customerId = subscription.customer as string;
          const snap = await deps.db
            .collection("usuarios")
            .where("stripeCustomerId", "==", customerId)
            .limit(1)
            .get();
          if (!snap.empty) {
            const uid = snap.docs[0].id;
            await deps.db.doc(`usuarios/${uid}`).update({ plan: "free" });
            logEvent("plan_downgraded_to_free", { uid, customerId });
          }
          break;
        }

        default:
          logEvent("webhook_unhandled_event", { type: event.type });
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Unknown error";
      logEvent("webhook_handler_error", { type: event.type, error: msg });
      res.status(500).send("Internal error processing webhook");
      return;
    }

    res.status(200).json({ received: true });
  };
}

export const stripeWebhook = onRequest(
  { secrets: ["STRIPE_SECRET_KEY", "STRIPE_WEBHOOK_SECRET"] },
  async (req, res) => {
    const Stripe = (await import("stripe")).default;
    const stripeClient = new Stripe(process.env.STRIPE_SECRET_KEY ?? "", {
      apiVersion: "2024-06-20",
    });
    const handler = buildStripeWebhookHandler({
      db: adminDb,
      stripe: stripeClient,
      webhookSecret: process.env.STRIPE_WEBHOOK_SECRET ?? "",
    });
    await handler(req as any, res as any);
  },
);
