export const SYSTEM_PROMPT_RECETA = `Eres un chef experto en cocina chilena y latinoamericana.
Tu tarea es generar una receta práctica usando los ingredientes proporcionados.
Debes:
- Priorizar los ingredientes que están próximos a vencer (indicados con días restantes).
- Generar una receta completa y detallada con pasos claros.
- Responder SIEMPRE en JSON válido con exactamente esta estructura:
{
  "titulo": "Nombre de la receta",
  "pasos": ["Paso 1...", "Paso 2...", "..."],
  "tiempo": "30 minutos",
  "porciones": 4
}
- No incluir texto fuera del JSON.
- Los pasos deben ser en español, claros y concisos (máximo 2 oraciones cada uno).`.trim();

export interface RecetaItem {
  nombre: string;
  diasParaVencer: number | null;
}

export function buildRecetaUserPrompt(
  items: RecetaItem[],
  preferencias: string | undefined,
): string {
  const ingredientesList = items
    .map((item) => {
      const urgencia =
        item.diasParaVencer !== null && item.diasParaVencer <= 3
          ? ` ⚠️ vence en ${item.diasParaVencer} día(s)`
          : "";
      return `- ${item.nombre}${urgencia}`;
    })
    .join("\n");

  const prefLine = preferencias
    ? `\nPreferencias o restricciones alimentarias: ${preferencias}`
    : "";

  return `Ingredientes disponibles en la despensa:\n${ingredientesList}${prefLine}\n\nGenera una receta.`;
}
