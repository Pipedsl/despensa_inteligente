import { describe, it, expect, vi } from "vitest";
import { buildFlowRegisterReturnHandler } from "../flow/flowRegisterReturn";

function makeFakeReq(query: Record<string, string> = {}) {
  return {
    query,
    method: "GET",
    headers: {},
  } as any;
}

function makeFakeRes() {
  const res: any = { _status: 200, _redirected: null };
  res.status = vi.fn().mockImplementation((s: number) => {
    res._status = s;
    return res;
  });
  res.redirect = vi.fn().mockImplementation((url: string) => {
    res._redirected = url;
    return res;
  });
  res.send = vi.fn().mockReturnValue(res);
  return res;
}

function makeFakeFlow(overrides: Partial<any> = {}) {
  return {
    getRegisterStatus: vi.fn().mockResolvedValue({
      status: "1",
      customerId: "cus_abc",
      last4CardDigits: "1234",
    }),
    createSubscription: vi.fn().mockResolvedValue({
      subscriptionId: "sub_nueva_xyz",
      planId: "plan_pro",
      customerId: "cus_abc",
      status: 1,
    }),
    createCustomer: vi.fn(),
    registerCustomerCard: vi.fn(),
    getPaymentStatus: vi.fn(),
    ...overrides,
  };
}

function makeFakeDb() {
  const updates: Record<string, any> = {};
  const updateMock = vi.fn().mockImplementation(async (path: string, data: any) => {
    updates[path] = { ...(updates[path] ?? {}), ...data };
  });
  return {
    doc: (path: string) => ({
      update: (data: any) => updateMock(path, data),
      get: async () => ({ exists: true, data: () => updates[path] ?? {} }),
    }),
    _updateMock: updateMock,
    _updates: updates,
  };
}

describe("buildFlowRegisterReturnHandler", () => {
  const planId = "plan_pro_test";
  const successUrl = "https://app.example.com/upgrade-success";
  const errorUrl = "https://app.example.com/upgrade?error=1";

  it("responde 400 si falta uid o token en la query", async () => {
    const handler = buildFlowRegisterReturnHandler({
      db: makeFakeDb() as any,
      flow: makeFakeFlow() as any,
      planId,
      successUrl,
      errorUrl,
    });
    const res = makeFakeRes();
    await handler(makeFakeReq({}), res);
    expect(res._status).toBe(400);
  });

  it("redirige a errorUrl si el status de registro no es válido", async () => {
    const flow = makeFakeFlow({
      getRegisterStatus: vi.fn().mockResolvedValue({ status: "0", customerId: "cus_abc" }),
    });
    const handler = buildFlowRegisterReturnHandler({
      db: makeFakeDb() as any,
      flow: flow as any,
      planId,
      successUrl,
      errorUrl,
    });
    const res = makeFakeRes();
    await handler(makeFakeReq({ uid: "u1", token: "tok_bad" }), res);
    expect(res._redirected).toBe(errorUrl);
    expect(flow.createSubscription).not.toHaveBeenCalled();
  });

  it("crea suscripción y actualiza plan a 'pro' si el registro fue exitoso", async () => {
    const db = makeFakeDb();
    const flow = makeFakeFlow();
    const handler = buildFlowRegisterReturnHandler({
      db: db as any,
      flow: flow as any,
      planId,
      successUrl,
      errorUrl,
    });
    await handler(makeFakeReq({ uid: "uid_123", token: "tok_ok" }), makeFakeRes());
    expect(flow.createSubscription).toHaveBeenCalledWith({
      planId,
      customerId: "cus_abc",
    });
    expect(db._updateMock).toHaveBeenCalledWith(
      "usuarios/uid_123",
      expect.objectContaining({
        plan: "pro",
        flowSubscriptionId: "sub_nueva_xyz",
      }),
    );
  });

  it("redirige a successUrl después de activar la suscripción", async () => {
    const handler = buildFlowRegisterReturnHandler({
      db: makeFakeDb() as any,
      flow: makeFakeFlow() as any,
      planId,
      successUrl,
      errorUrl,
    });
    const res = makeFakeRes();
    await handler(makeFakeReq({ uid: "u1", token: "tok_ok" }), res);
    expect(res._redirected).toBe(successUrl);
  });

  it("redirige a errorUrl si createSubscription falla", async () => {
    const flow = makeFakeFlow({
      createSubscription: vi.fn().mockRejectedValue(new Error("Flow 500")),
    });
    const handler = buildFlowRegisterReturnHandler({
      db: makeFakeDb() as any,
      flow: flow as any,
      planId,
      successUrl,
      errorUrl,
    });
    const res = makeFakeRes();
    await handler(makeFakeReq({ uid: "u1", token: "tok_ok" }), res);
    expect(res._redirected).toBe(errorUrl);
  });
});
