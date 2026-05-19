// Edge Function del asistente IA de YumYum.
//
// Recibe el texto que el usuario teclea en el FAB del asistente y devuelve
// un JSON estructurado con la intencion detectada (publicar / buscar /
// desconocido) y los campos extraidos. La integracion con Gemini se hace
// aqui dentro para que la GEMINI_API_KEY no salga del servidor: el cliente
// Flutter solo habla con esta funcion via Supabase Functions.
//
// Para que funcione hay que configurar el secret GEMINI_API_KEY en
// Supabase (Dashboard -> Project Settings -> Edge Functions -> Secrets,
// o `supabase secrets set GEMINI_API_KEY=...` con el CLI).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_ENDPOINT =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const SYSTEM_PROMPT =
  `Eres el asistente de YumYum, una app de venta e intercambio local de comida casera entre vecinos.

Tu tarea: analizar la intencion del usuario y extraer datos estructurados.

Acciones posibles:
- "publicar": el usuario quiere publicar u ofrecer un producto.
- "buscar": el usuario quiere buscar productos o filtrar el feed.
- "desconocido": no se puede determinar.

Categorias validas: "primero", "segundo", "postre", "snack", "bebida", "panaderia", "otro".
Tipos validos: "venta", "intercambio".

Si un campo no se menciona, omitelo. El campo "resumen" siempre debe estar presente con una frase corta y amigable describiendo lo que entendiste. Responde SIEMPRE en espanol.`;

const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    accion: { type: "string", enum: ["publicar", "buscar", "desconocido"] },
    resumen: { type: "string" },
    nombre: { type: "string" },
    categoria: { type: "string" },
    tipo: { type: "string", enum: ["venta", "intercambio"] },
    precio: { type: "number" },
    descripcion: { type: "string" },
  },
  required: ["accion", "resumen"],
};

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Metodo no permitido" }, 405);
  }
  if (!GEMINI_API_KEY) {
    return jsonResponse(
      { error: "Falta GEMINI_API_KEY en el servidor" },
      500,
    );
  }

  let payload: { texto?: unknown; usuario?: unknown };
  try {
    payload = await req.json();
  } catch (_e) {
    return jsonResponse({ error: "JSON invalido en la solicitud" }, 400);
  }

  const texto = typeof payload.texto === "string" ? payload.texto.trim() : "";
  const usuarioId = typeof payload.usuario === "string"
    ? payload.usuario
    : null;
  if (!texto) {
    return jsonResponse(
      { error: "El campo 'texto' es obligatorio" },
      400,
    );
  }

  try {
    const geminiResponse = await fetch(
      `${GEMINI_ENDPOINT}?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
          contents: [{ parts: [{ text: texto }] }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: RESPONSE_SCHEMA,
          },
        }),
      },
    );

    if (!geminiResponse.ok) {
      const detalle = await geminiResponse.text();
      console.error(
        "Gemini upstream error:",
        geminiResponse.status,
        detalle,
      );
      return jsonResponse(
        { error: "El asistente no esta disponible ahora mismo" },
        502,
      );
    }

    const data = await geminiResponse.json();
    const rawText: string | undefined =
      data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!rawText) {
      return jsonResponse({ error: "Respuesta vacia del asistente" }, 502);
    }

    const parsed = JSON.parse(rawText);
    return jsonResponse({ ...parsed, usuarioId }, 200);
  } catch (err) {
    console.error("Error procesando solicitud:", err);
    return jsonResponse({ error: "Error procesando la solicitud" }, 500);
  }
});
