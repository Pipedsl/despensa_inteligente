import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

export const healthcheck = onRequest((_request, response) => {
  logger.info("healthcheck invoked");
  response.json({
    ok: true,
    service: "despensa-inteligente-functions",
    timestamp: new Date().toISOString(),
  });
});

export { lookupProductoGlobal } from "./productos/lookupProductoGlobal";
export { proponerProductoGlobal } from "./productos/proponerProductoGlobal";
