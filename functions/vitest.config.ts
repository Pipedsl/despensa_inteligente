import { defineConfig } from "vitest/config";
export default defineConfig({
  test: {
    include: ["src/**/*.test.ts"],
    exclude: ["src/__tests__/rules.test.ts"],
    environment: "node",
  },
});
