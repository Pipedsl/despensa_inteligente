import type { Firestore } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import type { Request, Response } from "express";
import type { FlowClient, FlowPaymentStatus } from "./flowClient";
import { buildFlowClient } from "./flowClient";
import { db as adminDb } from "../lib/admin";
import { logEvent } from "../lib/logger";

const FLOW_API_KEY = defineSecret("FLOW_API_KEY");
const FLOW_SECRET_KEY = defineSecret("FLOW_SECRET_KEY");
const FLOW_BASE_URL = defineSecret("FLOW_BASE_URL");

export interface FlowWebhookDeps {
  db: Firestore;
  flow: FlowClient;
}

function extractCustomerIdFromPayment(payment: FlowPaymentStatus): string | null {
  if (!payment.optional) return null;
  try {
    const parsed = JSON.parse(payment.optional) as { customerId?: string };
    return parsed.customerId ?? null;
  } catch {
    return null;
  }
}

export function buildFlowWebhookHandler(deps: FlowWebhookDeps) {
  return async (req: Request, res: Response): Promise<void> => {
    const token = (req.body?.token as string | undefined)?.trim();
    if (!token) {
      res.status(400).send("Missing token");
      return;
    }

    try {
      const payment = await deps.flow.getPaymentStatus(token);

      const customerId = extractCustomerIdFromPayment(payment);

      if (payment.status === 2) {
        logEvent("flow_payment_success", {
          flowOrder: payment.flowOrder,
          customerId,
          amount: payment.amount,
        });
        res.status(200).json({ received: true });
        return;
      }

      if (payment.status === 3 || payment.status === 4) {
        if (!customerId) {
          logEvent("flow_payment_failed_no_customer", { flowOrder: payment.flowOrder });
          res.status(200).json({ received: true });
          return;
        }
        const snap = await deps.db
          .collection("usuarios")
          .where("flowCustomerId", "==", customerId)
          .limit(1)
          .get();
        if (snap.empty) {
          logEvent("flow_payment_failed_uid_not_found", { customerId, flowOrder: payment.flowOrder });
          res.status(200).json({ received: true });
          return;
        }
        const uid = snap.docs[0].id;
        await deps.db.doc(`usuarios/${uid}`).update({ plan: "free" });
        logEvent("flow_plan_downgraded_to_free", { uid, customerId, flowOrder: payment.flowOrder });
        res.status(200).json({ received: true });
        return;
      }

      logEvent("flow_webhook_unhandled_status", { status: payment.status, flowOrder: payment.flowOrder });
      res.status(200).json({ received: true });
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Unknown error";
      logEvent("flow_webhook_error", { error: msg });
      res.status(500).send("Error processing webhook");
    }
  };
}

export const flowWebhook = onRequest(
  { secrets: [FLOW_API_KEY, FLOW_SECRET_KEY, FLOW_BASE_URL] },
  async (req, res) => {
    const flow = buildFlowClient({
      apiKey: FLOW_API_KEY.value(),
      secretKey: FLOW_SECRET_KEY.value(),
      baseUrl: FLOW_BASE_URL.value(),
    });
    const handler = buildFlowWebhookHandler({ db: adminDb, flow });
    await handler(req as any, res as any);
  },
);
