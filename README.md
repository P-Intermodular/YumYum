# YumYum

Aplicación Flutter para intercambio y venta local de comida casera.

## Configuración compartida

La app lee la configuración de Supabase mediante `--dart-define`.
El archivo `.env` es solo para desarrollo local y no debe versionarse.

```env
SUPABASE_URL=https://lqlekjlatkxurnnwtjgo.supabase.co
SUPABASE_ANON_KEY=tu_anon_key
```

`SUPABASE_ANON_KEY` es pública para el cliente y se usa solo en desarrollo.
No hay que subir `service_role`, tokens privados ni otras credenciales sensibles.

Si en algún momento hay que apuntar a otro proyecto de Supabase, se puede usar `.env.example` como plantilla.

## Asistente IA (Edge Function)

El botón flotante del asistente IA (`BotonIAGlobal`) llama a la Edge Function
`asistente-ia` desplegada en Supabase (`supabase/functions/asistente-ia/`).
La función habla con Gemini desde el servidor, así que la `GEMINI_API_KEY`
nunca se expone al cliente.

Configurar el secret (una sola vez por proyecto Supabase):

- **Dashboard**: Supabase → *Project Settings* → *Edge Functions* → *Secrets*
  → añade `GEMINI_API_KEY` con la clave de Google AI Studio.
- **CLI**: `supabase secrets set GEMINI_API_KEY=tu_clave`.

Para volver a desplegar la función tras cambios locales:

```bash
supabase functions deploy asistente-ia
```

## Puesta en marcha

1. Instala Flutter.
2. Desde la raíz del proyecto ejecuta `flutter pub get`.
3. Entra en la carpeta `scripts`.
4. Ejecuta el script `run_dev.ps1`.

Arranque rápido en Chrome:

```powershell
cd .\scripts
.\run_dev.ps1
```

El script lee el `.env` local del proyecto y pasa `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `APP_BASE_URL` a Flutter automáticamente.

## Build para Render

Para desplegar YumYum como sitio estático en Render, usa:

- **Build Command**: `bash ./scripts/build_web_from_env.sh`
- **Publish Directory**: `build/web`

Configura estas variables en **Render > Environment**:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `APP_BASE_URL` si necesitas fijar la URL pública de la web para redirects de autenticación

El script:

- usa primero las variables de entorno definidas en Render
- solo carga `.env` como fallback para builds locales
- descarga una versión fija de Flutter (`3.41.6`) si el entorno no la trae instalada
- ejecuta `flutter pub get`
- compila la web con los `--dart-define` necesarios para Supabase
