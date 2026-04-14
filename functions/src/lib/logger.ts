// functions/src/lib/logger.ts
import * as logger from "firebase-functions/logger";

export function logEvent(
  event: string,
  payload: Record<string, unknown>,
): void {
  logger.info({ event, ...payload });
}
