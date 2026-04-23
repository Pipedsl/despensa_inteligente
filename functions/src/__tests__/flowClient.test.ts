import { describe, it, expect } from "vitest";
import { signFlowParams } from "../flow/flowClient";
import * as crypto from "crypto";

describe("signFlowParams", () => {
  it("firma params ordenados alfabéticamente con HMAC-SHA256", () => {
    const params = { apiKey: "test_key", email: "u@t.com", name: "Usuario" };
    const expected = crypto
      .createHmac("sha256", "sec")
      .update("apiKeytest_keyemailu@t.comnameUsuario")
      .digest("hex");
    expect(signFlowParams(params, "sec")).toBe(expected);
  });

  it("produce la misma firma independiente del orden de inserción", () => {
    const a = { b: "2", a: "1", c: "3" };
    const b = { c: "3", a: "1", b: "2" };
    expect(signFlowParams(a, "k")).toBe(signFlowParams(b, "k"));
  });

  it("excluye el param 's' de la firma si estuviera presente", () => {
    const sinS = { a: "1" };
    const conS = { a: "1", s: "sig_previa" };
    expect(signFlowParams(sinS, "k")).toBe(signFlowParams(conS, "k"));
  });

  it("firma params con claves con símbolos y números", () => {
    const params = { apiKey: "K", externalId: "uid_123", url_return: "https://x.com/r?a=1" };
    const sig = signFlowParams(params, "sec");
    expect(sig).toMatch(/^[0-9a-f]{64}$/);
  });
});
