// Edge Function del asistente IA de YumYum.
//
// Recibe la consulta del usuario, la ubicacion aproximada (lat/lon) y el
// id del usuario autenticado. Llama a Gemini con una "tool" disponible
// (`buscar_productos_cercanos`); cuando Gemini decide invocarla, esta
// funcion ejecuta la RPC `obtener_productos_cercanos` contra Supabase
// usando el JWT del propio usuario (respeta RLS) y se la devuelve al
// modelo, que compone una respuesta natural mencionando los productos
// reales encontrados.
//
// Salida al cliente:
// {
//   respuesta: string,                  // texto conversacional listo para UI
//   accion: 'buscar' | 'publicar' | 'info' | 'ninguna',
//   productos: Array<{                 // si Gemini busco, top resultados
//     id, titulo, descripcion, tipo, precio, categoria,
//     distancia_km, propietario_nombre, propietario_avatar,
//     imagen_principal
//   }>,
//   prefilled_publicacion?: {           // si el usuario quiere publicar
//     titulo?, descripcion?, categoria?, tipo?, precio?
//   }
// }
//
// La GEMINI_API_KEY se configura como secret de Supabase
// (Dashboard -> Project Settings -> Edge Functions -> Secrets).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const GEMINI_MODEL = "gemini-2.5-flash-lite";
const GEMINI_ENDPOINT =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const CATEGORIAS_VALIDAS = [
  "primero",
  "segundo",
  "postre",
  "snack",
  "bebida",
  "panaderia",
  "otro",
] as const;
const TIPOS_VALIDOS = ["venta", "intercambio"] as const;

const BASE_PROMPT =
  `Eres el asistente conversacional de YumYum, una app de venta e intercambio local de comida casera entre vecinos.

CAPACIDADES:
- Recomendar platos cercanos que el usuario podria comer ahora.
- Ayudar a planificar comidas usando lo que esta disponible cerca.
- Guiar al usuario para publicar su propio plato.
- Responder dudas basicas sobre como funciona la app.

REGLAS:
- Cuando el usuario quiera "comer algo", "buscar", "que hay cerca", "planificar comidas" o expresiones similares, INVOCA la herramienta "buscar_productos_cercanos" con los filtros que mejor encajen con su intencion. Despues, en tu respuesta final, menciona productos concretos por su nombre y la distancia (formato "a 400 m" o "a 1,2 km").
- Cuando el usuario quiera publicar/ofrecer un plato propio, NO llames a la herramienta: explicale brevemente que va a abrirse el formulario de publicar.
- Si la consulta es saludo, ayuda general o algo que no requiere productos cercanos, responde directamente sin llamar a la herramienta.
- Responde SIEMPRE en espanol, en tono cercano (de tu) y maximo 4 frases. No inventes platos: usa solo los que devuelva la herramienta.
- Si el usuario declara alergenos en su perfil, JAMAS recomiendes platos que los contengan. Tampoco propongas publicar recetas con alergenos del usuario sin avisarle.
- Si el usuario tiene un nombre conocido, usalo de vez en cuando para personalizar (no en todas las frases).
- Mantienes la conversacion: si el usuario sigue la charla, usa el historial previo para no perder contexto (filtros aplicados, productos ya mencionados...).
- Sinonimos y aproximaciones: la herramienta te devuelve los platos cercanos que cumplen los filtros duros (categoria, tipo, precio), no filtra por palabras clave. Tu trabajo es elegir los que mejor encajen semanticamente con la consulta del usuario, AUNQUE el nombre no coincida exactamente. Si pide "bizcocho" y solo hay "tarta de zanahoria", recomiendala explicando que es un bizcocho. Si pide "kebab" y no hay, propon parecidos (durum, shawarma, doner) si los ves en la lista. Cuando hagas una aproximacion, avisalo: "no he encontrado X exacto, pero tienes Y que encaja porque...". Solo di que no hay nada si de verdad NADA de la lista se parece.
- Categorias validas: ${CATEGORIAS_VALIDAS.join(", ")}. Tipos validos: ${TIPOS_VALIDOS.join(", ")}.`;

interface PerfilUsuario {
  nombre: string | null;
  ciudad: string | null;
  alergenos: string[];
  bio: string | null;
}

function construirSystemPrompt(perfil: PerfilUsuario | null): string {
  if (!perfil) return BASE_PROMPT;
  const partes: string[] = [];
  if (perfil.nombre) partes.push(`Nombre del usuario: ${perfil.nombre}.`);
  if (perfil.ciudad) partes.push(`Ciudad declarada: ${perfil.ciudad}.`);
  if (perfil.alergenos.length > 0) {
    partes.push(
      `Alergenos del usuario (debes evitarlos en toda recomendacion): ${
        perfil.alergenos.join(", ")
      }.`,
    );
  }
  if (perfil.bio) {
    partes.push(`Bio del usuario (tonelo en cuenta para personalizar): "${perfil.bio}".`);
  }
  if (partes.length === 0) return BASE_PROMPT;
  return `${BASE_PROMPT}\n\nCONTEXTO DEL USUARIO:\n- ${partes.join("\n- ")}`;
}

const TOOLS = [
  {
    functionDeclarations: [
      {
        name: "buscar_productos_cercanos",
        description:
          "Devuelve los platos disponibles cerca del usuario que cumplen los filtros duros (categoria, tipo, precio). No filtra por palabras clave: tu mismo seleccionas en la respuesta los que encajen semanticamente con lo que pide el usuario. Usalo cuando el usuario quiera comer, buscar o planificar comidas.",
        parameters: {
          type: "object",
          properties: {
            consulta: {
              type: "string",
              description:
                "Palabras clave libres (ej: 'kebab', 'tortilla vegana'). Solo para registro/logging: el servidor NO filtra por este campo.",
            },
            categoria: {
              type: "string",
              enum: CATEGORIAS_VALIDAS,
              description: "Filtra por categoria si el usuario la menciona.",
            },
            tipo: {
              type: "string",
              enum: TIPOS_VALIDOS,
              description:
                "Filtra por tipo de oferta si el usuario lo especifica (venta o intercambio).",
            },
            max_precio: {
              type: "number",
              description: "Precio maximo en euros si el usuario lo menciona.",
            },
          },
          required: [],
        },
      },
    ],
  },
];

const FINAL_RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    respuesta: { type: "string" },
    accion: {
      type: "string",
      enum: ["buscar", "publicar", "info", "ninguna"],
    },
    prefilled_publicacion: {
      type: "object",
      properties: {
        titulo: { type: "string" },
        descripcion: { type: "string" },
        categoria: { type: "string", enum: CATEGORIAS_VALIDAS },
        tipo: { type: "string", enum: TIPOS_VALIDOS },
        precio: { type: "number" },
      },
    },
  },
  required: ["respuesta", "accion"],
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

interface ProductoRpc {
  id: string;
  titulo: string;
  descripcion: string | null;
  tipo_oferta: string;
  precio: number | null;
  categoria: string | null;
  alergenos: string[] | null;
  etiquetas: string[] | null;
  sin_alergenos_declarados: boolean | null;
  distancia_km: number | null;
  perfiles: { nombre?: string; url_avatar?: string | null } | null;
  imagenes_producto:
    | Array<{ url_publica: string; posicion: number }>
    | null;
}

interface ProductoSalida {
  id: string;
  titulo: string;
  descripcion: string | null;
  tipo: string;
  precio: number | null;
  categoria: string | null;
  distancia_km: number | null;
  propietario_nombre: string | null;
  propietario_avatar: string | null;
  imagen_principal: string | null;
}

function aProductoSalida(p: ProductoRpc): ProductoSalida {
  const imagenes = p.imagenes_producto ?? [];
  const principal = imagenes.length > 0
    ? imagenes.sort((a, b) => a.posicion - b.posicion)[0].url_publica
    : null;
  return {
    id: p.id,
    titulo: p.titulo,
    descripcion: p.descripcion,
    tipo: p.tipo_oferta,
    precio: p.precio,
    categoria: p.categoria,
    distancia_km: p.distancia_km,
    propietario_nombre: p.perfiles?.nombre ?? null,
    propietario_avatar: p.perfiles?.url_avatar ?? null,
    imagen_principal: principal,
  };
}

interface FiltrosBusqueda {
  consulta?: string;
  categoria?: string;
  tipo?: string;
  max_precio?: number;
}

interface MensajeChat {
  rol: "user" | "assistant";
  texto: string;
}

/// Normaliza el payload de entrada a una lista de mensajes. Acepta tanto
/// el formato legacy `{ texto: "..." }` (lo envuelve como un unico turno
/// del usuario) como el nuevo `{ mensajes: [{ rol, texto }, ...] }`.
function normalizarHistorial(payload: {
  texto?: unknown;
  mensajes?: unknown;
}): MensajeChat[] {
  const fuente = Array.isArray(payload.mensajes) ? payload.mensajes : null;
  if (fuente) {
    const limpio: MensajeChat[] = [];
    for (const item of fuente) {
      if (item === null || typeof item !== "object") continue;
      const rolRaw = (item as Record<string, unknown>).rol;
      const textoRaw = (item as Record<string, unknown>).texto;
      if (typeof textoRaw !== "string") continue;
      const texto = textoRaw.trim();
      if (!texto) continue;
      const rol = rolRaw === "assistant" ? "assistant" : "user";
      limpio.push({ rol, texto });
    }
    return limpio;
  }
  if (typeof payload.texto === "string" && payload.texto.trim()) {
    return [{ rol: "user", texto: payload.texto.trim() }];
  }
  return [];
}

/// Filtra solo por criterios DUROS (categoria, tipo, max_precio). La
/// busqueda por palabras clave intencionalmente NO se aplica aqui: que
/// Gemini decida en la respuesta natural cuales son relevantes
/// semanticamente. Asi una peticion de "bizcocho" puede acabar
/// recomendando "tarta de zanahoria" aunque ningun campo contenga la
/// palabra exacta.
function filtrarProductos(
  productos: ProductoRpc[],
  filtros: FiltrosBusqueda,
): ProductoRpc[] {
  return productos.filter((p) => {
    if (filtros.categoria && p.categoria !== filtros.categoria) return false;
    if (filtros.tipo && p.tipo_oferta !== filtros.tipo) return false;
    if (
      filtros.max_precio !== undefined &&
      p.precio !== null &&
      p.precio > filtros.max_precio
    ) {
      return false;
    }
    return true;
  });
}

async function cargarPerfilUsuario(
  authHeader: string,
): Promise<PerfilUsuario | null> {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) return null;
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });
    const { data: user } = await supabase.auth.getUser();
    const uid = user?.user?.id;
    if (!uid) return null;
    const { data, error } = await supabase
      .from("perfiles")
      .select("nombre, ciudad, alergenos, bio")
      .eq("id", uid)
      .maybeSingle();
    if (error || !data) return null;
    const alergenosRaw = (data as Record<string, unknown>).alergenos;
    const alergenos = Array.isArray(alergenosRaw)
      ? alergenosRaw.filter((a): a is string => typeof a === "string")
      : [];
    return {
      nombre: typeof data.nombre === "string" ? data.nombre : null,
      ciudad: typeof data.ciudad === "string" ? data.ciudad : null,
      alergenos,
      bio: typeof (data as Record<string, unknown>).bio === "string"
        ? ((data as Record<string, unknown>).bio as string)
        : null,
    };
  } catch (err) {
    console.error("cargarPerfilUsuario fallo:", err);
    return null;
  }
}

async function ejecutarBusqueda(
  authHeader: string,
  latitud: number,
  longitud: number,
  filtros: FiltrosBusqueda,
): Promise<{ productos: ProductoRpc[]; error?: string }> {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return { productos: [], error: "Configuracion de Supabase incompleta." };
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const { data, error } = await supabase.rpc(
    "obtener_productos_cercanos",
    {
      p_latitud: latitud,
      p_longitud: longitud,
      p_radio_km: 10,
      p_limite: 30,
    },
  );

  if (error) {
    console.error("RPC obtener_productos_cercanos error:", error);
    return { productos: [], error: error.message };
  }

  const todos = (data ?? []) as ProductoRpc[];
  // Mandamos hasta 8 a Gemini para que tenga margen de eleccion semantica
  // sin disparar el coste de tokens.
  const filtrados = filtrarProductos(todos, filtros).slice(0, 8);
  return { productos: filtrados };
}

function resumirParaModelo(productos: ProductoRpc[]): string {
  if (productos.length === 0) {
    return "No se han encontrado platos cercanos que coincidan con los filtros.";
  }
  return productos
    .map((p, i) => {
      const distancia = p.distancia_km !== null
        ? p.distancia_km < 1
          ? `${Math.round(p.distancia_km * 1000)} m`
          : `${p.distancia_km.toFixed(1).replace(".", ",")} km`
        : "distancia desconocida";
      const precio = p.precio !== null ? `${p.precio} EUR` : "sin precio";
      const propietario = p.perfiles?.nombre ?? "anonimo";
      const descripcion = (p.descripcion ?? "").slice(0, 120);
      return `${i + 1}. ${p.titulo} - ${p.tipo_oferta} - ${precio} - ${distancia} - de ${propietario}. ${descripcion}`;
    })
    .join("\n");
}

interface GeminiPart {
  text?: string;
  functionCall?: { name: string; args: Record<string, unknown> };
  functionResponse?: { name: string; response: Record<string, unknown> };
}

interface GeminiCandidate {
  content?: { role?: string; parts?: GeminiPart[] };
  finishReason?: string;
}

interface GeminiResponse {
  candidates?: GeminiCandidate[];
}

async function llamarGemini(
  contents: Array<{ role: string; parts: GeminiPart[] }>,
  opciones: { withTools: boolean; withSchema: boolean; systemPrompt: string },
): Promise<GeminiResponse> {
  const body: Record<string, unknown> = {
    systemInstruction: { parts: [{ text: opciones.systemPrompt }] },
    contents,
  };
  if (opciones.withTools) {
    body.tools = TOOLS;
  }
  if (opciones.withSchema) {
    body.generationConfig = {
      responseMimeType: "application/json",
      responseSchema: FINAL_RESPONSE_SCHEMA,
    };
  }

  const response = await fetch(
    `${GEMINI_ENDPOINT}?key=${GEMINI_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
  );

  if (!response.ok) {
    const detalle = await response.text();
    console.error("Gemini upstream error:", response.status, detalle);
    throw new Error(`Gemini fallo con status ${response.status}`);
  }
  return (await response.json()) as GeminiResponse;
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

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) {
    return jsonResponse({ error: "Falta token de autenticacion." }, 401);
  }

  let payload: {
    texto?: unknown;
    mensajes?: unknown;
    usuario?: unknown;
    ubicacion?: { latitud?: unknown; longitud?: unknown };
  };
  try {
    payload = await req.json();
  } catch (_e) {
    return jsonResponse({ error: "JSON invalido en la solicitud" }, 400);
  }

  // Soporta dos formatos: legacy `{ texto }` y nuevo `{ mensajes: [...] }`
  // con historial para multi-turno.
  const mensajes = normalizarHistorial(payload);
  if (mensajes.length === 0) {
    return jsonResponse(
      { error: "Falta historial de mensajes en la solicitud" },
      400,
    );
  }
  const latitud = typeof payload.ubicacion?.latitud === "number"
    ? payload.ubicacion.latitud
    : null;
  const longitud = typeof payload.ubicacion?.longitud === "number"
    ? payload.ubicacion.longitud
    : null;

  try {
    // Cargamos el perfil para personalizar el prompt (nombre, alergenos,
    // ciudad, bio). Si falla, seguimos con el prompt base.
    const perfil = await cargarPerfilUsuario(authHeader);
    const systemPrompt = construirSystemPrompt(perfil);

    // Reconstruimos el historial completo para Gemini: cada mensaje del
    // usuario con role "user" y cada respuesta previa del asistente con
    // role "model".
    const contents: Array<{ role: string; parts: GeminiPart[] }> = mensajes
      .map((m) => ({
        role: m.rol === "user" ? "user" : "model",
        parts: [{ text: m.texto }],
      }));

    const primera = await llamarGemini(contents, {
      withTools: true,
      withSchema: false,
      systemPrompt,
    });
    const partsPrimera = primera.candidates?.[0]?.content?.parts ?? [];
    const llamada = partsPrimera.find((p) => p.functionCall)?.functionCall;

    let productosSalida: ProductoSalida[] = [];

    if (llamada && llamada.name === "buscar_productos_cercanos") {
      if (latitud === null || longitud === null) {
        // No tenemos ubicacion pero Gemini quiere buscar. Damos una
        // respuesta honesta sin llamar a la RPC.
        return jsonResponse({
          respuesta:
            "Necesito conocer tu ubicacion para buscar platos cercanos. Activa la ubicacion en la app y vuelve a preguntarme.",
          accion: "info",
          productos: [],
        }, 200);
      }

      const filtros: FiltrosBusqueda = {
        consulta: typeof llamada.args.consulta === "string"
          ? llamada.args.consulta
          : undefined,
        categoria: typeof llamada.args.categoria === "string"
          ? llamada.args.categoria
          : undefined,
        tipo: typeof llamada.args.tipo === "string"
          ? llamada.args.tipo
          : undefined,
        max_precio: typeof llamada.args.max_precio === "number"
          ? llamada.args.max_precio
          : undefined,
      };

      const { productos, error } = await ejecutarBusqueda(
        authHeader,
        latitud,
        longitud,
        filtros,
      );
      if (error) {
        return jsonResponse(
          { error: `No pude consultar los platos cercanos: ${error}` },
          502,
        );
      }
      productosSalida = productos.map(aProductoSalida);

      // Turno 2: devolvemos el resultado de la tool a Gemini y le pedimos
      // la respuesta final en formato estructurado.
      contents.push({
        role: "model",
        parts: [{ functionCall: llamada }],
      });
      contents.push({
        role: "user",
        parts: [
          {
            functionResponse: {
              name: "buscar_productos_cercanos",
              response: {
                listado_resumen: resumirParaModelo(productos),
                total_resultados: productos.length,
              },
            },
          },
        ],
      });

      const segunda = await llamarGemini(contents, {
        withTools: false,
        withSchema: true,
        systemPrompt,
      });
      const partsSegunda = segunda.candidates?.[0]?.content?.parts ?? [];
      const textoFinal = partsSegunda.map((p) => p.text ?? "").join("");
      if (!textoFinal) {
        return jsonResponse(
          { error: "Respuesta vacia del asistente." },
          502,
        );
      }
      const parsed = JSON.parse(textoFinal);
      return jsonResponse({
        ...parsed,
        productos: productosSalida,
      }, 200);
    }

    // Camino sin tool: Gemini no quiso buscar. Re-llamamos pidiendo
    // formato estructurado (publicar / info / ninguna), conservando el
    // historial para que la accion final tenga contexto multi-turno.
    const textoLibre = partsPrimera.map((p) => p.text ?? "").join("");

    const contentsEstructurada: Array<{ role: string; parts: GeminiPart[] }> = [
      ...contents,
      {
        role: "user",
        parts: [
          {
            text:
              `Redacta la respuesta final al usuario manteniendo este tono y contenido aproximado: "${textoLibre}". ` +
              `Marca "accion" como "publicar" si el usuario quiere publicar/ofrecer un plato, "info" si es ayuda general, ` +
              `o "ninguna" en cualquier otro caso. Si la accion es "publicar", rellena "prefilled_publicacion" con los datos que el usuario haya dado (titulo, descripcion, categoria, tipo, precio).`,
          },
        ],
      },
    ];
    const segundaSinTool = await llamarGemini(contentsEstructurada, {
      withTools: false,
      withSchema: true,
      systemPrompt,
    });
    const partsFinal = segundaSinTool.candidates?.[0]?.content?.parts ?? [];
    const textoFinal = partsFinal.map((p) => p.text ?? "").join("");
    if (!textoFinal) {
      return jsonResponse({ error: "Respuesta vacia del asistente." }, 502);
    }
    const parsed = JSON.parse(textoFinal);
    return jsonResponse({
      ...parsed,
      productos: [],
    }, 200);
  } catch (err) {
    const detalle = err instanceof Error ? `${err.name}: ${err.message}` : String(err);
    console.error("Error procesando solicitud:", detalle, err);
    return jsonResponse(
      {
        error: "Error procesando la solicitud",
        detalle,
      },
      500,
    );
  }
});
