import type OpenAI from "openai";
import { z } from "zod";
import { ProductoDraft, NormalizerResponse } from "../types";
import { CATEGORIAS } from "./taxonomy";
import { SYSTEM_PROMPT, buildUserPrompt } from "./normalizerPrompt";

export const NormalizerResponseSchema = z.object({
  nombre: z.string().min(1),
  marca: z.string().nullable(),
  categorias: z
    .array(z.enum(CATEGORIAS as unknown as [string, ...string[]]))
    .min(1),
  confianza: z.number().min(0).max(1),
  correcciones: z.array(z.string()).max(5),
});

export interface NormalizerIA {
  normalize(draft: ProductoDraft): Promise<NormalizerResponse>;
}

export function createOpenAINormalizer(client: OpenAI): NormalizerIA {
  return {
    async normalize(draft) {
      const completion = await client.chat.completions.create({
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        max_tokens: 500,
        temperature: 0,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: buildUserPrompt(draft) },
        ],
      });
      const raw = completion.choices[0]?.message?.content ?? "";
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
        // Check if the error is due to invalid enum values in categorias
        const raw_parsed = parsed as Record<string, unknown>;
        if (
          Array.isArray(raw_parsed?.categorias) &&
          raw_parsed.categorias.some(
            (c) => !(CATEGORIAS as readonly string[]).includes(c as string),
          )
        ) {
          throw new Error(
            `normalizer devolvió categoría fuera de taxonomía: ${(raw_parsed.categorias as string[]).join(", ")}`,
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
