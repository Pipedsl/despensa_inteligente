// functions/src/__tests__/rules.test.ts
import { describe, it, beforeAll, afterAll } from "vitest";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  assertSucceeds,
  assertFails,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "node:fs";
import { join } from "node:path";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-despensa",
    firestore: {
      rules: readFileSync(
        join(__dirname, "..", "..", "..", "firestore.rules"),
        "utf-8",
      ),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterAll(async () => {
  if (env) await env.cleanup();
});

describe("productos_globales rules", () => {
  it("auth puede leer productos_globales", async () => {
    const ctx = env.authenticatedContext("u1");
    await assertSucceeds(
      ctx.firestore().collection("productos_globales").doc("1").get(),
    );
  });

  it("anon NO puede leer productos_globales", async () => {
    const ctx = env.unauthenticatedContext();
    await assertFails(
      ctx.firestore().collection("productos_globales").doc("1").get(),
    );
  });

  it("ningún cliente puede escribir productos_globales", async () => {
    const ctx = env.authenticatedContext("u1");
    await assertFails(
      ctx
        .firestore()
        .collection("productos_globales")
        .doc("1")
        .set({ nombre: "hack" }),
    );
  });

  it("ningún cliente puede escribir productos_globales_drafts", async () => {
    const ctx = env.authenticatedContext("u1");
    await assertFails(
      ctx
        .firestore()
        .collection("productos_globales_drafts")
        .doc("1")
        .set({ x: 1 }),
    );
  });
});
