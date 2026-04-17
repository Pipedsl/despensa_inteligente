import { describe, it, expect, vi } from "vitest";
import { buildStripeWebhookHandler } from "../stripe/webhook";
import type { Request } from "express";

function makeFakeReq(body: Buffer | string, signature: string): Partial<Request> {
  return {
    headers: { "stripe-signature": signature },
    rawBody: typeof body === "string" ? Buffer.from(body) : body,
  } as any;
}

function makeFakeRes() {
  const res: any = { _status: 200 };
  res.status = vi.fn().mockImplementation((s: number) => { res._status = s; return res; });
  res.json = vi.fn().mockReturnValue(res);
  res.send = vi.fn().mockReturnValue(res);
  return res;
}

function makeStripeEvent(type: string, data: Record<string, unknown>) {
  return { type, data: { object: data } };
}

function makeFakeStripeVerifier(
  event: ReturnType<typeof makeStripeEvent> | null = null,
  shouldThrow = false,
) {
  return {
    webhooks: {
      constructEvent: vi.fn().mockImplementation(() => {
        if (shouldThrow) throw new Error("Invalid signature");
        return event;
      }),
    },
  };
}

function makeFakeDb() {
  const docs: Record<string, any> = {};
  const updateMock = vi.fn().mockImplementation(async (path: string, data: any) => {
    docs[path] = { ...(docs[path] ?? {}), ...data };
  });
  return {
    doc: (path: string) => ({
      update: (data: any) => updateMock(path, data),
      get: async () => ({ exists: !!docs[path], data: () => docs[path] }),
    }),
    _docs: docs,
    _updateMock: updateMock,
  };
}

describe("buildStripeWebhookHandler", () => {
  const webhookSecret = "whsec_test_secret";

  it("responde 400 si la firma Stripe es inválida", async () => {
    const fakeStripe = makeFakeStripeVerifier(null, true);
    const fakeDb = makeFakeDb();
    const handler = buildStripeWebhookHandler({
      db: fakeDb as any,
      stripe: fakeStripe as any,
      webhookSecret,
    });
    const req = makeFakeReq(Buffer.from("{}"), "sig_invalida");
    const res = makeFakeRes();
    await handler(req as any, res as any);
    expect(res._status).toBe(400);
  });

  it("responde 200 y actualiza plan a 'pro' en checkout.session.completed", async () => {
    const event = makeStripeEvent("checkout.session.completed", {
      client_reference_id: "uid_usuario_1",
      customer: "cus_test_stripe_id",
      subscription: "sub_test_id",
    });
    const fakeStripe = makeFakeStripeVerifier(event);
    const fakeDb = makeFakeDb();
    const handler = buildStripeWebhookHandler({
      db: fakeDb as any,
      stripe: fakeStripe as any,
      webhookSecret,
    });
    const req = makeFakeReq(Buffer.from(JSON.stringify(event)), "sig_valida");
    const res = makeFakeRes();
    await handler(req as any, res as any);
    expect(res._status).toBe(200);
    expect(fakeDb._updateMock).toHaveBeenCalledWith(
      "usuarios/uid_usuario_1",
      expect.objectContaining({ plan: "pro" }),
    );
  });

  it("guarda stripeCustomerId y stripeSubscriptionId en checkout.session.completed", async () => {
    const event = makeStripeEvent("checkout.session.completed", {
      client_reference_id: "uid_usuario_2",
      customer: "cus_abc999",
      subscription: "sub_xyz111",
    });
    const fakeStripe = makeFakeStripeVerifier(event);
    const fakeDb = makeFakeDb();
    const handler = buildStripeWebhookHandler({
      db: fakeDb as any,
      stripe: fakeStripe as any,
      webhookSecret,
    });
    await handler(
      makeFakeReq(Buffer.from(JSON.stringify(event)), "sig_valida") as any,
      makeFakeRes() as any,
    );
    expect(fakeDb._updateMock).toHaveBeenCalledWith(
      "usuarios/uid_usuario_2",
      expect.objectContaining({
        stripeCustomerId: "cus_abc999",
        stripeSubscriptionId: "sub_xyz111",
      }),
    );
  });

  it("revierte plan a 'free' en checkout.session.expired", async () => {
    const event = makeStripeEvent("checkout.session.expired", {
      client_reference_id: "uid_usuario_3",
    });
    const fakeStripe = makeFakeStripeVerifier(event);
    const fakeDb = makeFakeDb();
    const handler = buildStripeWebhookHandler({
      db: fakeDb as any,
      stripe: fakeStripe as any,
      webhookSecret,
    });
    const res = makeFakeRes();
    await handler(
      makeFakeReq(Buffer.from(JSON.stringify(event)), "sig_valida") as any,
      res as any,
    );
    expect(res._status).toBe(200);
    expect(fakeDb._updateMock).toHaveBeenCalledWith(
      "usuarios/uid_usuario_3",
      expect.objectContaining({ plan: "free" }),
    );
  });

  it("revierte plan a 'free' en customer.subscription.deleted", async () => {
    const event = makeStripeEvent("customer.subscription.deleted", {
      customer: "cus_cancelado_99",
    });
    const fakeStripe = makeFakeStripeVerifier(event);
    const fakeDbWithQuery = {
      ...makeFakeDb(),
      collection: (_col: string) => ({
        where: (_field: string, _op: string, _val: string) => ({
          limit: (_n: number) => ({
            get: async () => ({
              empty: false,
              docs: [{ id: "uid_from_customer", data: () => ({}) }],
            }),
          }),
        }),
      }),
    };
    const handler = buildStripeWebhookHandler({
      db: fakeDbWithQuery as any,
      stripe: fakeStripe as any,
      webhookSecret,
    });
    const res = makeFakeRes();
    await handler(
      makeFakeReq(Buffer.from(JSON.stringify(event)), "sig_valida") as any,
      res as any,
    );
    expect(res._status).toBe(200);
    expect(fakeDbWithQuery._updateMock).toHaveBeenCalledWith(
      "usuarios/uid_from_customer",
      expect.objectContaining({ plan: "free" }),
    );
  });

  it("responde 200 para eventos desconocidos sin hacer nada", async () => {
    const event = makeStripeEvent("payment_intent.created", { id: "pi_test" });
    const fakeStripe = makeFakeStripeVerifier(event);
    const fakeDb = makeFakeDb();
    const handler = buildStripeWebhookHandler({
      db: fakeDb as any,
      stripe: fakeStripe as any,
      webhookSecret,
    });
    const res = makeFakeRes();
    await handler(
      makeFakeReq(Buffer.from(JSON.stringify(event)), "sig_valida") as any,
      res as any,
    );
    expect(res._status).toBe(200);
    expect(fakeDb._updateMock).not.toHaveBeenCalled();
  });
});
