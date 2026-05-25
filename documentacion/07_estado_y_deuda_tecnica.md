# 07 — Estado actual y deuda técnica

> Anterior: [`06_reglas_de_negocio.md`](./06_reglas_de_negocio.md)

---

## ¿Qué está implementado?

### ✅ Completo

- Auth completo: registro con consentimiento legal, login, PKCE, recuperación de contraseña
- Publicación, edición y eliminación de platos
- Feed y mapa con búsqueda por proximidad + filtros (categoría, etiquetas, alérgenos, tipo, orden)
- Solicitudes con raciones e intercambios
- Transacciones: aceptación, cancelación y completado con stock decremental
- Chat en tiempo real con cómputo de mensajes no leídos
- Notificaciones Realtime con badge dinámico, enrutamiento contextual y filtro por preferencias
- Valoraciones con trigger de recálculo de media
- Favoritos con stream Realtime y pantalla "Guardados"
- Perfil: visualización, edición, avatar, perfil público ajeno
- Ajustes: temas (Huerto Moderno / Mesa de Barrio), preferencias de notificaciones
- Legal/RGPD: banner de cookies, checkbox de consentimiento en registro, 6 páginas legales públicas
- **Asistente IA:** Edge Function `asistente-ia` (Deno + TypeScript) integrada con Google Gemini, function calling contra `obtener_productos_cercanos`, fallback en cascada entre 6 modelos, anti-alucinación y UI multi-turno con chips navegables
- Todas las migraciones, RLS, triggers y RPCs desplegadas

### 🔄 Incompleto

- **Prefill del formulario de publicación desde la IA:** la Edge Function ya devuelve `prefilled_publicacion` (título, categoría, tipo, precio) y el botón "Empezar a publicar" navega a `/publicar`, pero los datos no se inyectan todavía en `PublicarProductoController`.
- **Mensajes de error:** algunos errores de Supabase llegan crudos a la UI sin normalizar.
- **Pulido visual:** algunas pantallas secundarias pendientes de refinamiento.

### ❌ No implementado

- Paginación del feed (solo muestra los 50 productos más cercanos)
- Pagos digitales (las ventas se pagan en mano)
- Despliegue en tiendas móviles (App Store / Google Play)

---

## Deuda técnica

### 🔴 Alta — hay que resolver antes de escalar

**1. Sin paginación del feed**
`obtener_productos_cercanos` no tiene `offset` ni cursor. Con volumen real de datos, la app solo mostrará los 50 más cercanos.
→ Añadir offset/cursor a la RPC + scroll infinito en el feed.

**2. Borrado de cuentas bloqueado / datos de terceros destruidos**
- Si el usuario tiene transacciones completadas → la FK RESTRICT bloquea el borrado. No hay flujo de baja implementado.
- Si no tiene transacciones → CASCADE en `solicitudes_oferta`, `conversaciones` y `mensajes` destruye el historial de chat de la contraparte.
- CASCADE en `mensajes.remitente_id` elimina todos los mensajes del usuario borrado de las conversaciones ajenas.
- CASCADE en `valoraciones` elimina la valoración, pero `valoracion_media` del perfil restante queda desactualizada hasta que recibe otra valoración.

→ Implementar bajas lógicas: columna `borrado_en`, anonimización de datos en lugar de DELETE físico.

**3. Completado unilateral de transacciones**
Cualquier participante puede marcar como `completada` sin confirmación del otro.
→ Confirmación mutua: dos columnas `completado_por_solicitante_en` / `completado_por_propietario_en`.

---

### 🟡 Media — mejoras antes de producción real

**4. Posible fuga de privacidad de perfil**
`ciudad`, `bio`, `alergenos` y `preferencias_notificaciones` son accesibles via SELECT directo por cualquier usuario autenticado, aunque la migración base los pensó como privados. Decisión pendiente: ¿aceptarlo o revertir los GRANTs?

**5. Estados fantasma en CHECKs**
- `transacciones`: `pendiente` y `reportada` declarados pero nunca asignados.
- `productos`: `reservado` declarado pero ya no usado.
→ Eliminarlos del CHECK o implementar los flujos que los justifiquen.

**6. `certificacion_sanitaria` sin validación**
Texto libre en una plataforma de alimentos. Cualquiera puede escribir lo que quiera.
→ Flujo de moderación con revisión manual e insignia validada.

**7. Imágenes sin compresión ni limpieza**
- No hay compresión antes del upload → imágenes pesadas en el feed.
- El avatar anterior queda huérfano en Storage al subir uno nuevo.
→ `flutter_image_compress` antes del upload. Eliminar blob anterior al actualizar avatar.

**8. Prefill del formulario de publicación desde el asistente IA**
La Edge Function ya devuelve `prefilled_publicacion` con los campos detectados (`titulo`, `descripcion`, `categoria`, `tipo`, `precio`), pero no se inyectan en `PublicarProductoController` al abrir el formulario.
→ Crear un `borradorAsistenteProvider` transitorio que el formulario lea al construirse para pre-rellenar los campos.

---

### 🟢 Baja — hardening menor para producción

| Ajuste | Descripción |
|--------|-------------|
| Policy SELECT `imagenes_producto` | Alinear con visibilidad del producto |
| CHECK en `notificaciones.tipo` | Acotar el dominio de tipos |
| Triggers de valoraciones para DELETE/UPDATE | Recalcular media si se borra o modifica una valoración |
| Auditar `ref.keepAlive()` en Riverpod | Documentar los keepAlive intencionados |
| Hardening Auth | Activar "Leaked password protection", mover extensiones al schema `extensions` |

---

## Referencia rápida — archivos a tocar

| Tarea | Archivos |
|-------|---------|
| Nueva pantalla | `features/<feature>/screens/`, `core/constants/rutas_app.dart`, `core/router/app_router.dart` |
| Nueva RPC | `supabase/migrations/<timestamp>.sql`, `core/constants/supabase_names.dart`, `domain/repositories/`, `data/repositories/` |
| Cambiar validaciones de BD | Nueva migración en `supabase/migrations/` |
| Widget global nuevo | `core/widgets/` |
| Cambiar tema visual | `core/theme/app_theme.dart`, `core/theme/yum_colors.dart` |
| Invalidar providers tras acción compartida | `core/providers_refresher.dart` |
| Test de migración SQL | `test/supabase/` |
