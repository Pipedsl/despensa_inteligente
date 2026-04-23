import type { GoogleGenerativeAI } from "@google/generative-ai";
import { z } from "zod";
import type { ProductoDraft, NormalizerResponse } from "../types";
import { CATEGORIAS } from "./taxonomy";
import { SYSTEM_PROMPT, buildUserPrompt } from "./normalizerPrompt";
import { NormalizerIA, NormalizerResponseSchema } from "./normalizerOpenAI";

export function createGeminiNormalizer(genAI: GoogleGenerativeAI): NormalizerIA {
  return {
    async normalize(draft: ProductoDraft): Promise<NormalizerResponse> {
      const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash",
        systemInstruction: SYSTEM_PROMPT,
        generationConfig: {
          responseMimeType: "application/json",
          temperature: 0,
          maxOutputTokens: 500,
        },
      });

      const result = await model.generateContent(buildUserPrompt(draft));
      const raw = result.response.text();

      let parsed: unknown;
      try {
        parsed = JSON.parse(raw);
      } catch {
        throw new Error(`normalizer devolvió JSON inválido: ${raw}`);
      }

      let validated: z.infer<typeof NormalizerResponseSchema>;
      try {
        validated = NormalizerResponseSchema.parse(parsed);
      } catch (err) {
        const rawParsed = parsed as Record<string, unknown>;
        if (
          Array.isArray(rawParsed?.categorias) &&
          rawParsed.categorias.some(
            (c) => !(CATEGORIAS as readonly string[]).includes(c as string),
          )
        ) {
          throw new Error(
            `normalizer devolvió categoría fuera de taxonomía: ${(rawParsed.categorias as string[]).join(", ")}`,
          );
        }
        throw err;
      }

      if (
        validated.categorias.some(
          (c) => !(CATEGORIAS as readonly string[]).includes(c),
        )
      ) {
        throw new Error(
          `normalizer devolvió categoría fuera de taxonomía: ${validated.categorias.join(", ")}`,
        );
      }

      return validated as NormalizerResponse;
    },
  };
}
