import { describe, it, expect, vi } from "vitest";
import { buildCrearCheckoutSessionHandler } from "../stripe/checkout";

interface FakeStripeCheckout {
  sessions: {
    create: (params: Record<string, unknown>) => Promise<{ url: string | null }>;
  };
}

function makeFakeStripe(url = "https://checkout.stripe.com/pay/test_session"): FakeStripeCheckout {
  return {
    sessions: {
      create: vi.fn().mockResolvedValue({ url }),
    },
  };
}

function makeFakeDb(usuarioData: Record<string, unknown> = {}) {
  return {
    doc: (_path: string) => ({
      get: async () => ({ exists: true, data: () => usuarioData }),
      update: vi.fn().mockResolvedValue(undefined),
    }),
  };
}

describe("buildCrearCheckoutSessionHandler", () => {
  const baseRequest = {
    priceId: "price_test_abc123",
    successUrl: "https://app.example.com/success",
    cancelUrl: "https://app.example.com/cancel",
  };

  it("lanza unauthenticated si no hay uid", async () => {
    const handler = buildCrearCheckoutSessionHandler({
      db: makeFakeDb() as any,
      stripe: makeFakeStripe() as any,
    });
    await expect(handler(baseRequest, undefined)).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("crea sesión y devuelve url cuando usuario existe", async () => {
    const fakeStripe = makeFakeStripe();
    const handler = buildCrearCheckoutSessionHandler({
      db: makeFakeDb({ email: "user@test.com", plan: "free" }) as any,
      stripe: fakeStripe as any,
    });
    const result = await handler(baseRequest, "uid123");
    expect(result.url).toBe("https://checkout.stripe.com/pay/test_session");
    expect(fakeStripe.sessions.create).toHaveBeenCalledOnce();
  });

  it("pasa client_reference_id igual al uid", async () => {
    const fakeStripe = makeFakeStripe();
    const handler = buildCrearCheckoutSessionHandler({
      db: makeFakeDb({ email: "user@test.com" }) as any,
      stripe: fakeStripe as any,
    });
    await handler(baseRequest, "uid_especial_456");
    const llamada = (fakeStripe.sessions.create as ReturnType<typeof vi.fn>).mock.calls[0][0];
    expect(llamada.client_reference_id).toBe("uid_especial_456");
  });

  it("incluye priceId en los line_items", async () => {
    const fakeStripe = makeFakeStripe();
    const handler = buildCrearCheckoutSessionHandler({
      db: makeFakeDb({ email: "user@test.com" }) as any,
      stripe: fakeStripe as any,
    });
    await handler({ ...baseRequest, priceId: "price_pro_xyz" }, "uid1");
    const llamada = (fakeStripe.sessions.create as ReturnType<typeof vi.fn>).mock.calls[0][0];
    expect(llamada.line_items[0].price).toBe("price_pro_xyz");
  });

  it("lanza internal si Stripe devuelve url nula", async () => {
    const fakeStripe = makeFakeStripe();
    (fakeStripe.sessions.create as ReturnType<typeof vi.fn>).mockResolvedValue({ url: null });
    const handler = buildCrearCheckoutSessionHandler({
      db: makeFakeDb({ email: "user@test.com" }) as any,
      stripe: fakeStripe as any,
    });
    await expect(handler(baseRequest, "uid1")).rejects.toMatchObject({
      code: "internal",
    });
  });
});
