module.exports = {
  root: true,
  env: { es2020: true, node: true },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "google",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json"],
    sourceType: "module",
  },
  ignorePatterns: ["/lib/**/*", "node_modules/**/*"],
  plugins: ["@typescript-eslint"],
  rules: {
    quotes: ["error", "double"],
    "import/no-unresolved": 0,
    indent: ["error", 2],
    "object-curly-spacing": ["error", "always"],
    "max-len": ["error", { code: 120 }],
    "require-jsdoc": 0,
    "valid-jsdoc": 0,
  },
};
