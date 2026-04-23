import { describe, it, expect, vi } from "vitest";
import { buildFlowWebhookHandler } from "../flow/flowWebhook";

function makeFakeReq(body: Record<string, string>) {
  return { body, method: "POST", headers: {} } as any;
}

function makeFakeRes() {
  const res: any = { _status: 200 };
  res.status = vi.fn().mockImplementation((s: number) => {
    res._status = s;
    return res;
  });
  res.send = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  return res;
}

function makeFakeFlow(paymentStatus: any) {
  return {
    getPaymentStatus: vi.fn().mockResolvedValue(paymentStatus),
    createCustomer: vi.fn(),
    registerCustomerCard: vi.fn(),
    getRegisterStatus: vi.fn(),
    createSubscription: vi.fn(),
  };
}

function makeFakeDb(customerIdToUid: Record<string, string> = {}) {
  const updateMock = vi.fn().mockResolvedValue(undefined);
  return {
    doc: (path: string) => ({
      update: (data: any) => updateMock(path, data),
    }),
    collection: (_col: string) => ({
      where: (_field: string, _op: string, val: string) => ({
        limit: (_n: number) => ({
          get: async () => {
            const uid = customerIdToUid[val];
            if (!uid) return { empty: true, docs: [] };
            return {
              empty: false,
              docs: [{ id: uid, data: () => ({ flowCustomerId: val }) }],
            };
          },
        }),
      }),
    }),
    _updateMock: updateMock,
  };
}

describe("buildFlowWebhookHandler", () => {
  it("responde 400 si falta token", async () => {
    const handler = buildFlowWebhookHandler({
      db: makeFakeDb() as any,
      flow: makeFakeFlow({}) as any,
    });
    const res = makeFakeRes();
    await handler(makeFakeReq({}), res);
    expect(res._status).toBe(400);
  });

  it("responde 200 y loguea renovación en status=2 (pagado)", async () => {
    const flow = makeFakeFlow({
      status: 2,
      flowOrder: 12345,
      subject: "Suscripción mensual",
      amount: 2990,
      optional: JSON.stringify({ customerId: "cus_abc" }),
    });
    const db = makeFakeDb({ cus_abc: "uid_xyz" });
    const handler = buildFlowWebhookHandler({ db: db as any, flow: flow as any });
    const res = makeFakeRes();
    await handler(makeFakeReq({ token: "tok_paid" }), res);
    expect(res._status).toBe(200);
    expect(flow.getPaymentStatus).toHaveBeenCalledWith("tok_paid");
  });

  it("no cambia el plan si el pago fue exitoso (solo loguea)", async () => {
    const flow = makeFakeFlow({
      status: 2,
      flowOrder: 1,
      subject: "Renovación",
      amount: 2990,
      optional: JSON.stringify({ customerId: "cus_ok" }),
    });
    const db = makeFakeDb({ cus_ok: "uid_ok" });
    const handler = buildFlowWebhookHandler({ db: db as any, flow: flow as any });
    await handler(makeFakeReq({ token: "tok" }), makeFakeRes());
    expect(db._updateMock).not.toHaveBeenCalled();
  });

  it("downgrade a plan 'free' cuando status=3 (rechazado) y se puede mapear el customer", async () => {
    const flow = makeFakeFlow({
      status: 3,
      flowOrder: 99,
      subject: "Renovación fallida",
      amount: 2990,
      optional: JSON.stringify({ customerId: "cus_failed" }),
    });
    const db = makeFakeDb({ cus_failed: "uid_failed" });
    const handler = buildFlowWebhookHandler({ db: db as any, flow: flow as any });
    const res = makeFakeRes();
    await handler(makeFakeReq({ token: "tok_failed" }), res);
    expect(res._status).toBe(200);
    expect(db._updateMock).toHaveBeenCalledWith(
      "usuarios/uid_failed",
      expect.objectContaining({ plan: "free" }),
    );
  });

  it("responde 200 sin error si no se encuentra el customer en Firestore", async () => {
    const flow = makeFakeFlow({
      status: 3,
      flowOrder: 100,
      subject: "fallo",
      amount: 1,
      optional: JSON.stringify({ customerId: "cus_huerfano" }),
    });
    const db = makeFakeDb({});
    const handler = buildFlowWebhookHandler({ db: db as any, flow: flow as any });
    const res = makeFakeRes();
    await handler(makeFakeReq({ token: "tok_x" }), res);
    expect(res._status).toBe(200);
    expect(db._updateMock).not.toHaveBeenCalled();
  });

  it("responde 500 si getPaymentStatus falla (Flow reintenta)", async () => {
    const flow = {
      ...makeFakeFlow({}),
      getPaymentStatus: vi.fn().mockRejectedValue(new Error("Flow down")),
    };
    const handler = buildFlowWebhookHandler({
      db: makeFakeDb() as any,
      flow: flow as any,
    });
    const res = makeFakeRes();
    await handler(makeFakeReq({ token: "tok" }), res);
    expect(res._status).toBe(500);
  });
});
