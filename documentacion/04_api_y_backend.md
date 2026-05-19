# 04 — API y Backend

> Anterior: [`03_base_de_datos.md`](./03_base_de_datos.md)  |  Siguiente: [`05_flujos_de_negocio.md`](./05_flujos_de_negocio.md)

---

## No hay servidor intermedio

Las llamadas van directamente de Flutter a Supabase, protegidas por RLS, GRANTs columnares y RPCs. Solo el asistente IA usa un backend Node externo.

---

## RPCs (funciones PL/pgSQL)

Se invocan desde Flutter con `supabase.rpc('nombre', params: {...})`. Garantizan atomicidad.

### Perfil

| RPC | Acceso | Qué hace |
|-----|--------|---------|
| `obtener_mi_perfil` | Propio usuario | Devuelve perfil completo incluidos campos privados (`email`, `preferencias`, coordenadas) y `pedidos_completados` |
| `obtener_perfil_publico(p_usuario_id)` | Cualquier autenticado | Devuelve shape público de otro usuario. Corre en `security definer` para calcular `pedidos_completados` |

### Productos

| RPC | Acceso | Qué hace |
|-----|--------|---------|
| `obtener_productos_cercanos(lat, lng, radio_km, limite=50)` | Cualquier autenticado | **Motor del feed/mapa.** Filtra productos `disponibles` dentro del radio con `cube`+`earthdistance`+GiST. Nunca revela coordenadas exactas |
| `obtener_ubicacion_exacta_producto(producto_id)` | Propietario O participante de transacción `aceptada`/`completada` | Devuelve coordenadas exactas |
| `eliminar_producto(p_producto_id)` | Solo el propietario | Sin actividad → DELETE real (devuelve `true`, cliente limpia Storage). Con actividad → soft delete a `cancelado` (devuelve `false`) |

### Solicitudes y transacciones

| RPC | Acceso | Qué hace |
|-----|--------|---------|
| `crear_solicitud_oferta(...)` | Cualquier autenticado (no el propietario) | Crea solicitud + conversación + notificación **atómicamente** |
| `cancelar_solicitud_oferta` | Solo el solicitante (si `pendiente`) | Cancela la solicitud |
| `aceptar_solicitud_oferta` | Solo el propietario | Genera transacción, decrementa raciones, pasa a `agotado` si llega a 0, auto-deniega solicitudes excedentes, notifica al solicitante |
| `denegar_solicitud_oferta` | Solo el propietario | Pasa a `denegada` |
| `cancelar_transaccion` | Cualquier participante (si `aceptada`) | Cancela, restituye raciones, vuelve a `disponible` si estaba `agotado`, notifica a la contraparte |
| `completar_transaccion` | Cualquier participante (si `aceptada`) | Pasa a `completada`. El stock no cambia (ya se descontó al aceptar) |

---

## Triggers

| Trigger | Cuándo | Qué hace |
|---------|--------|---------|
| `crear_perfil_usuario` | AFTER INSERT en `auth.users` | Crea el registro en `public.perfiles` |
| `sincronizar_email_perfil` | AFTER UPDATE email en `auth.users` | Propaga el nuevo email a `perfiles` |
| `recalcular_valoracion_perfil` | AFTER INSERT en `valoraciones` | Recalcula `valoracion_media` y `numero_valoraciones` del valorado |
| `actualizar_ultimo_mensaje_conversacion` | AFTER INSERT en `mensajes` | Actualiza `ultimo_mensaje_en` para ordenar la lista de chats |
| `validar_transicion_estado_producto` | BEFORE UPDATE en `productos` | Desde `authenticated` solo permite `disponible → cancelado`. Las RPCs lo evitan con `security definer` |
| `*_establecer_actualizado_en` | BEFORE UPDATE en `productos`/`perfiles` | Sincroniza `actualizado_en` automáticamente |

---

## Storage

| Bucket | Lectura | Escritura | Uso |
|--------|---------|-----------|-----|
| `imagenes-productos` | Pública | Solo en `/{uuid_usuario}/` propio | Fotos de platos (máx. 5) |
| `avatares` | Pública | Solo en `/{uuid_usuario}/` propio (INSERT + UPDATE) | Foto de perfil |

> ⚠️ Al subir un nuevo avatar, el blob anterior queda huérfano en el bucket — no hay limpieza automática.

---

## Realtime — canales activos

| Canal | Filtro | Para qué |
|-------|--------|---------|
| `public.mensajes` | `conversacion_id` | Mensajes nuevos en el chat abierto |
| `public.notificaciones` | `usuario_id = auth.uid()` | Badge del AppBar y centro de notificaciones |
| `public.favoritos` | `usuario_id = auth.uid()` | Set de IDs guardados sincronizado |

---

## Asistente IA (servicio externo)

- **Endpoint:** `POST http://localhost:3000/api/procesar-parte-ia` (`http://10.0.2.2:3000` en emuladores Android)
- **Body:** `{ texto, usuario, rol: 'USER' }`
- **Respuesta:** `{ accion: 'publicar' | 'buscar', ...datos }`
- **Estado actual:** la respuesta solo se imprime en consola — el cableado al intent está pendiente.
- Si el servidor no está levantado → SnackBar de error, el resto de la app no se ve afectado.
