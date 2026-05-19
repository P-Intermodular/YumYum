# 05 — Flujos principales

> Anterior: [`04_api_y_backend.md`](./04_api_y_backend.md)  |  Siguiente: [`06_reglas_de_negocio.md`](./06_reglas_de_negocio.md)

---

## 1. Registro y creación de perfil

```
Usuario rellena formulario (nombre, email, contraseña)
  + checkbox "Acepto Términos y Privacidad" (obligatorio)
        │ checkbox sin marcar → error en cliente, no llama a Supabase
        ▼
Supabase Auth registra → asigna UUID en auth.users
        ▼
Trigger crear_perfil_usuario → INSERT en public.perfiles (mismo UUID)
        ▼
GoRouter redirige a /inicio
```
**Error:** email ya existe → error de validación de Auth.

---

## 2. Publicación de un plato

```
Formulario: título, descripción, tipo (venta/intercambio), precio (si venta),
  categoría (obligatoria), etiquetas, declaración de alérgenos,
  raciones totales/disponibles, hasta 5 imágenes, ubicación en mapa
        ▼
Sube imágenes a Storage (bucket imagenes-productos, carpeta /{uuid}/)
        ▼
INSERT en productos (estado: 'disponible')
  + INSERT en imagenes_producto (posiciones 0..4)
        ▼
ref.refrescarCatalogo() → invalida providers de feed, mapa y perfil
```
**CHECKs que bloquean la inserción:** venta sin precio, sin declaración de alérgenos, categoría inválida, `raciones_disponibles > raciones_totales`.

---

## 3. Búsqueda por proximidad (Feed y Mapa)

```
Obtiene coordenadas: GPS del dispositivo → ubicación predeterminada → fallback
        ▼
RPC obtener_productos_cercanos(lat, lng, radio_km, limite=50)
  → Filtra productos disponibles con cube+earthdistance+GiST
  → Devuelve: producto + propietario + imágenes + distancia calculada (nunca coordenadas exactas)
        ▼
feedFiltradoProvider aplica filtros locales:
  búsqueda textual, categoría, etiquetas (AND), alérgenos excluidos (OR),
  tipo de oferta, orden (cercanos/recientes/valorados)
```

---

## 4. Solicitud de compra/intercambio

```
Solicitante selecciona: cantidad de raciones + [intercambio] producto propio + cantidad ofrecida
        ▼
RPC crear_solicitud_oferta(producto_id, tipo, producto_ofrecido_id?, mensaje, cantidad, cantidad_ofrecida?)
  Valida atómicamente:
    ✓ Producto disponible con suficientes raciones
    ✓ Solicitante ≠ propietario
    ✓ tipo_solicitud coincide con tipo_oferta del producto
    ✓ No existe solicitud pendiente del mismo usuario para el mismo producto
    ✓ [intercambio] producto ofrecido es del solicitante, disponible, con stock suficiente
        ▼
INSERT atómico: solicitud_oferta + conversacion + notificacion al propietario
```
**Errores:** stock insuficiente por concurrencia → RPC aborta; duplicado pendiente → UNIQUE parcial.

---

## 5. Aceptación y cierre de transacción

```
Propietario pulsa "Aceptar" en PedidosScreen
        ▼
RPC aceptar_solicitud_oferta(solicitud_id)
  FOR UPDATE bloquea productos (exclusividad)
  Decrementa raciones_disponibles
  Si llegan a 0 → estado producto = 'agotado'
  INSERT en transacciones (estado: 'aceptada')
  Solicitudes pendientes que ya no caben → 'auto_denegada' + notificaciones
  Notificación al solicitante con transaccion_id + conversacion_id
        ▼
Ambas partes pueden consultar coordenadas exactas del producto
        ▼
[Intercambio físico]
        ▼
Cualquier participante pulsa "Completar"
  RPC completar_transaccion → estado = 'completada', completado_en = now()
  (el stock NO cambia — ya se descontó al aceptar)
  Se habilita la valoración para ambas partes
```

**Cancelar una transacción aceptada:**
```
RPC cancelar_transaccion → estado = 'cancelada'
  Raciones restituidas; si producto estaba 'agotado' → vuelve a 'disponible'
  Notificación a la contraparte
```

---

## 6. Chat en tiempo real

```
Al entrar al listado de chats:
  Carga conversaciones + calcula mensajes_no_leidos (leido_en IS NULL y remitente ≠ yo)
        ▼
Al abrir una conversación:
  Suscripción Realtime a mensajes WHERE conversacion_id = X
  Mensajes nuevos llegan en streaming
        ▼
Al visualizar mensajes ajenos no leídos:
  UPDATE mensajes SET leido_en = now()
  RLS: caller debe ser participante y NO el remitente
  GRANT columnar: solo se puede modificar leido_en
        ▼
Al enviar un mensaje:
  INSERT en mensajes
  Trigger actualiza ultimo_mensaje_en en la conversación
```

---

## 7. Valoraciones

```
Prerrequisito: transacción en estado 'completada'
        ▼
INSERT en valoraciones (puntuación 1-5, comentario opcional)
  RLS verifica: participante de la transacción, transacción completada, valorador ≠ valorado
  UNIQUE (transaccion_id, valorador_id) previene doble valoración
        ▼
Trigger recalcular_valoracion_perfil:
  Actualiza valoracion_media y numero_valoraciones del valorado en perfiles
```

---

## 8. Notificaciones Realtime

```
Al iniciar sesión:
  Suscripción Realtime a notificaciones WHERE usuario_id = auth.uid()
        ▼
Al llegar notificación:
  Filtra por preferencias del usuario (pedidos/mensajes/valoraciones)
  Suma al badge del AppBar si la categoría está activa
        ▼
Al abrir /notificaciones:
  marcarTodasLeidas(usuarioId) → UPDATE leido_en = now() en todas las no leídas de una vez
        ▼
Al pulsar notificación → routing por tipo:
  solicitud_creada/denegada/auto_denegada/cancelada → pedidoPorSolicitud(solicitud_id)
  solicitud_aceptada/transaccion_cancelada          → transaccionDetalle(transaccion_id)
  Fallback: transaccion_id → solicitud_id → producto_id
```

---

## 9. Favoritos

```
Al arrancar: stream Realtime favoritos → mantiene Set<String> de IDs en memoria
  Tarjetas y detalle consultan el set para mostrar icono lleno/vacío
        ▼
Al pulsar toggle: anadir (INSERT) o quitar (DELETE) — nunca UPDATE
        ▼
Pantalla /guardados: consulta con embed productos!inner → lista completa de platos guardados
```
Si el plato es eliminado → `ON DELETE CASCADE` lo retira automáticamente del stream.

---

## 10. Edición de perfil y avatar

```
Carga datos via RPC obtener_mi_perfil (necesaria para campos privados)
        ▼
[Si hay imagen nueva] → upload a avatares/{uuid}/, URL → url_avatar
        ▼
UPDATE sobre perfiles
  RLS: solo propio registro (id = auth.uid())
  GRANT columnar: nombre, url_avatar, ciudad, bio, preferencias, alergenos,
    preferencias_notificaciones, certificacion_sanitaria, latitud/longitud_predeterminada
```

---

## 11. Edición y eliminación de plato

**Edición:**
```
UPDATE sobre productos
  GRANT: solo categoria, etiquetas, alergenos, sin_alergenos_declarados, raciones
Si se quitan imágenes → DELETE imagenes_producto + limpieza Storage
Si se añaden → upload Storage + INSERT imagenes_producto
```

**Eliminación:**
```
RPC eliminar_producto:
  Sin actividad → DELETE real → devuelve true → cliente limpia Storage
  Con actividad → estado='cancelado' (soft delete) → devuelve false
```

---

## 12. Ajustes y tema

- **Cambiar tema:** `TemaController.seleccionar` → persiste en SharedPreferences → reconstruye `MaterialApp.router` → sincroniza `meta theme-color` en web.
- **Cambiar contraseña:** envía email de recuperación reutilizando el flujo PKCE.
- **Preferencias notificaciones:** UI optimista → UPDATE en `perfiles.preferencias_notificaciones` → revierte si falla la red.

---

## 13. Asistente IA

```
Usuario pulsa FAB BotonIAGlobal → bottom sheet con campo de texto
        ▼
POST http://localhost:3000/api/procesar-parte-ia
  { texto, usuario, rol: 'USER' }
        ▼
Respuesta { accion, ...datos } → actualmente solo debugPrint
⚠️ El cableado de navegación al intent está PENDIENTE
```
