// functions/src/__tests__/openFoodFacts.test.ts
import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { fetchOpenFoodFacts } from "../core/openFoodFacts";

function fixture(name: string) {
  return JSON.parse(
    readFileSync(join(__dirname, "fixtures", name), "utf-8"),
  );
}

describe("openFoodFacts", () => {
  it("mapea producto encontrado", async () => {
    const httpGet = async () => fixture("off-coca-cola-1500.json");
    const draft = await fetchOpenFoodFacts("7802800006003", httpGet);
    expect(draft).not.toBeNull();
    expect(draft!.nombre).toBe("Coca-Cola 1.5 L");
    expect(draft!.marca).toBe("Coca-Cola");
    expect(draft!.nutricional?.energiaKcal).toBe(42);
    expect(draft!.nutricional?.sodioMg).toBeCloseTo(10); // 0.01 g → 10 mg
  });

  it("retorna null cuando OFF no encuentra el producto", async () => {
    const httpGet = async () => fixture("off-empty.json");
    const draft = await fetchOpenFoodFacts("0000000000000", httpGet);
    expect(draft).toBeNull();
  });

  it("retorna null en error de red", async () => {
    const httpGet = async () => {
      throw new Error("network down");
    };
    const draft = await fetchOpenFoodFacts("123", httpGet);
    expect(draft).toBeNull();
  });
});
