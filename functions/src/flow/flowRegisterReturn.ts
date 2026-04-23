import type { Firestore } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import type { Request, Response } from "express";
import type { FlowClient } from "./flowClient";
import { buildFlowClient } from "./flowClient";
import { db as adminDb } from "../lib/admin";
import { logEvent } from "../lib/logger";

const FLOW_API_KEY = defineSecret("FLOW_API_KEY");
const FLOW_SECRET_KEY = defineSecret("FLOW_SECRET_KEY");
const FLOW_BASE_URL = defineSecret("FLOW_BASE_URL");
const FLOW_PLAN_ID = defineSecret("FLOW_PLAN_ID");
const FLOW_SUCCESS_URL = defineSecret("FLOW_SUCCESS_URL");
const FLOW_ERROR_URL = defineSecret("FLOW_ERROR_URL");

export interface FlowRegisterReturnDeps {
  db: Firestore;
  flow: FlowClient;
  planId: string;
  successUrl: string;
  errorUrl: string;
}

export function buildFlowRegisterReturnHandler(deps: FlowRegisterReturnDeps) {
  return async (req: Request, res: Response): Promise<void> => {
    const uid = (req.query.uid as string | undefined)?.trim();
    const token = (req.query.token as string | undefined)?.trim();

    if (!uid || !token) {
      res.status(400).send("Missing uid or token");
      return;
    }

    try {
      const registerStatus = await deps.flow.getRegisterStatus(token);
      if (registerStatus.status !== "1") {
        logEvent("flow_register_invalid_status", { uid, token, status: registerStatus.status });
        res.redirect(deps.errorUrl);
        return;
      }

      const subscription = await deps.flow.createSubscription({
        planId: deps.planId,
        customerId: registerStatus.customerId,
      });

      await deps.db.doc(`usuarios/${uid}`).update({
        plan: "pro",
        flowSubscriptionId: subscription.subscriptionId,
        flowCustomerId: registerStatus.customerId,
      });

      logEvent("flow_subscription_created", {
        uid,
        customerId: registerStatus.customerId,
        subscriptionId: subscription.subscriptionId,
      });

      res.redirect(deps.successUrl);
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Unknown error";
      logEvent("flow_register_return_error", { uid, error: msg });
      res.redirect(deps.errorUrl);
    }
  };
}

export const flowRegisterReturn = onRequest(
  {
    secrets: [FLOW_API_KEY, FLOW_SECRET_KEY, FLOW_BASE_URL, FLOW_PLAN_ID, FLOW_SUCCESS_URL, FLOW_ERROR_URL],
  },
  async (req, res) => {
    const flow = buildFlowClient({
      apiKey: FLOW_API_KEY.value(),
      secretKey: FLOW_SECRET_KEY.value(),
      baseUrl: FLOW_BASE_URL.value(),
    });
    const handler = buildFlowRegisterReturnHandler({
      db: adminDb,
      flow,
      planId: FLOW_PLAN_ID.value(),
      successUrl: FLOW_SUCCESS_URL.value(),
      errorUrl: FLOW_ERROR_URL.value(),
    });
    await handler(req as any, res as any);
  },
);
