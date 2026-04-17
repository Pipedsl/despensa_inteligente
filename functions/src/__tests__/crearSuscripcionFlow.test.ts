import { describe, it, expect, vi } from "vitest";
import { buildCrearSuscripcionFlowHandler } from "../flow/crearSuscripcionFlow";

function makeFakeFlow(overrides: Partial<any> = {}) {
  return {
    createCustomer: vi.fn().mockResolvedValue({
      customerId: "cus_new_123",
      email: "u@t.com",
      name: "Usuario",
      externalId: "uid_test",
      status: "1",
    }),
    registerCustomerCard: vi.fn().mockResolvedValue({
      url: "https://sandbox.flow.cl/register/XYZ",
      token: "tok_register_123",
    }),
    getRegisterStatus: vi.fn(),
    createSubscription: vi.fn(),
    getPaymentStatus: vi.fn(),
    ...overrides,
  };
}

function makeFakeDb(usuarioData: Record<string, any> = { email: "u@t.com", nombre: "Usuario" }) {
  const updateMock = vi.fn().mockResolvedValue(undefined);
  return {
    doc: (_path: string) => ({
      get: async () => ({ exists: true, data: () => usuarioData }),
      update: updateMock,
    }),
    _updateMock: updateMock,
  };
}

describe("buildCrearSuscripcionFlowHandler", () => {
  const urlReturnBase = "https://fn.example.com/flowRegisterReturn";

  it("lanza unauthenticated si no hay uid", async () => {
    const handler = buildCrearSuscripcionFlowHandler({
      db: makeFakeDb() as any,
      flow: makeFakeFlow() as any,
      urlReturnBase,
    });
    await expect(handler(undefined)).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("crea customer si el usuario no tiene flowCustomerId y lo guarda", async () => {
    const flow = makeFakeFlow();
    const db = makeFakeDb({ email: "u@t.com", nombre: "Usuario" });
    const handler = buildCrearSuscripcionFlowHandler({
      db: db as any,
      flow: flow as any,
      urlReturnBase,
    });
    await handler("uid_abc");
    expect(flow.createCustomer).toHaveBeenCalledWith({
      name: "Usuario",
      email: "u@t.com",
      externalId: "uid_abc",
    });
    expect(db._updateMock).toHaveBeenCalledWith(
      expect.objectContaining({ flowCustomerId: "cus_new_123" }),
    );
  });

  it("reusa flowCustomerId existente sin crear otro customer", async () => {
    const flow = makeFakeFlow();
    const db = makeFakeDb({
      email: "u@t.com",
      nombre: "Usuario",
      flowCustomerId: "cus_existente",
    });
    const handler = buildCrearSuscripcionFlowHandler({
      db: db as any,
      flow: flow as any,
      urlReturnBase,
    });
    await handler("uid_abc");
    expect(flow.createCustomer).not.toHaveBeenCalled();
    expect(flow.registerCustomerCard).toHaveBeenCalledWith({
      customerId: "cus_existente",
      url_return: `${urlReturnBase}?uid=uid_abc`,
    });
  });

  it("devuelve url + token al cliente", async () => {
    const handler = buildCrearSuscripcionFlowHandler({
      db: makeFakeDb() as any,
      flow: makeFakeFlow() as any,
      urlReturnBase,
    });
    const result = await handler("uid_abc");
    expect(result).toEqual({
      url: "https://sandbox.flow.cl/register/XYZ",
      token: "tok_register_123",
    });
  });

  it("pasa url_return con uid como query param", async () => {
    const flow = makeFakeFlow();
    const handler = buildCrearSuscripcionFlowHandler({
      db: makeFakeDb() as any,
      flow: flow as any,
      urlReturnBase,
    });
    await handler("uid_especial_456");
    expect(flow.registerCustomerCard).toHaveBeenCalledWith(
      expect.objectContaining({ url_return: `${urlReturnBase}?uid=uid_especial_456` }),
    );
  });

  it("lanza not-found si el usuario no existe en Firestore", async () => {
    const db = {
      doc: (_p: string) => ({
        get: async () => ({ exists: false, data: () => undefined }),
        update: vi.fn(),
      }),
    };
    const handler = buildCrearSuscripcionFlowHandler({
      db: db as any,
      flow: makeFakeFlow() as any,
      urlReturnBase,
    });
    await expect(handler("uid_abc")).rejects.toMatchObject({ code: "not-found" });
  });
});
