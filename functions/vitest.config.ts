import { defineConfig } from "vitest/config";
export default defineConfig({
  test: {
    include: ["src/**/*.test.ts"],
    exclude: ["src/__tests__/rules.test.ts", "src/__tests__/e2e.test.ts"],
    environment: "node",
  },
});
