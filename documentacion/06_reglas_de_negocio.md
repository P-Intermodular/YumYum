# 06 — Reglas de negocio

> Anterior: [`05_flujos_de_negocio.md`](./05_flujos_de_negocio.md)  |  Siguiente: [`07_estado_y_deuda_tecnica.md`](./07_estado_y_deuda_tecnica.md)

---

Las reglas críticas se validan en **PostgreSQL**, no en Flutter. CHECKs, RLS, GRANTs y RPCs garantizan que aunque el cliente sea manipulado, la BD rechace operaciones inválidas.

---

## 1. Creación de solicitudes — `crear_solicitud_oferta`

| Condición | Si no se cumple |
|-----------|----------------|
| Producto en `disponible` con suficientes raciones | Excepción SQL |
| `solicitante_id ≠ propietario_id` | Excepción SQL |
| `tipo_solicitud` coincide con `tipo_oferta` del producto | Excepción SQL |
| `cantidad ≥ 1` | CHECK en tabla |
| Venta → `producto_ofrecido_id` y `cantidad_ofrecida` son NULL | CHECK en tabla |
| Intercambio → ambos NOT NULL, producto ofrecido del solicitante, disponible, con stock | Excepción SQL |
| No existe solicitud `pendiente` duplicada (mismo usuario + producto) | UNIQUE parcial |

---

## 2. Aceptación de solicitudes — `aceptar_solicitud_oferta`

Solo el **propietario**. La solicitud debe estar `pendiente`.
Los productos deben seguir `disponibles` con las raciones requeridas (FOR UPDATE bloquea concurrencia).

**Si se cumple → automáticamente:**
1. INSERT en `transacciones` (estado `aceptada`)
2. `raciones_disponibles` decrementadas; si llegan a 0 → producto pasa a `agotado`
3. Solicitudes pendientes que ya no caben en el stock → `auto_denegada` + notificaciones
4. Notificación al solicitante con `transaccion_id` + `conversacion_id`

---

## 3. Cancelar / Denegar solicitudes

| Acción | Quién | Condición |
|--------|-------|-----------|
| Cancelar | Solo `solicitante_id` | Estado `pendiente` |
| Denegar | Solo `propietario_id` | Estado `pendiente` |

---

## 4. Cancelar transacción — `cancelar_transaccion`

Solo participantes. Transacción debe estar `aceptada`.

**Efectos:** estado → `cancelada`; raciones restituidas; si producto estaba `agotado` y recupera stock → vuelve a `disponible`; notificación a la contraparte.

---

## 5. Completar transacción — `completar_transaccion`

Solo participantes. Transacción debe estar `aceptada`.

**Efectos:** estado → `completada`, `completado_en = now()`. El stock **no cambia**. Se habilita la valoración.

> ⚠️ El completado es **unilateral** — cualquiera puede marcarlo sin confirmación del otro.

---

## 6. Eliminar producto — `eliminar_producto`

Solo el propietario.

| Situación | Efecto | Retorna |
|-----------|--------|---------|
| Sin actividad asociada | DELETE real (CASCADE limpia imágenes y favoritos) | `true` → cliente limpia Storage |
| Con actividad asociada | Soft delete (`estado = 'cancelado'`) | `false` → blobs se conservan |

---

## 7. Restricción de estados en productos

Trigger `validar_transicion_estado_producto`: desde `authenticated`, solo se permite `disponible → cancelado`.
Las RPCs evitan el trigger corriendo con `security definer`.

---

## 8. Ubicación exacta

RPC `obtener_ubicacion_exacta_producto`: solo accesible si eres el **propietario** O participas en una transacción `aceptada`/`completada` que involucra ese producto.

---

## 9. Mensajería

| Regla | Mecanismo |
|-------|-----------|
| Solo participantes envían mensajes | RLS |
| Contenido no puede estar vacío (ni solo espacios) | CHECK `length(trim(contenido)) > 0` |
| Solo el otro participante puede marcar como leído | RLS: caller ≠ remitente |
| Al actualizar, solo se puede tocar `leido_en` | GRANT columnar |

---

## 10. Valoraciones

| Condición | Mecanismo |
|-----------|-----------|
| Transacción `completada` | RLS |
| Caller debe ser participante | RLS |
| `valorador_id ≠ valorado_id` | CHECK |
| Puntuación entre 1 y 5 | CHECK |
| Una sola valoración por transacción y valorador | UNIQUE |

Trigger `recalcular_valoracion_perfil` → actualiza `valoracion_media` y `numero_valoraciones` del valorado.

---

## 11. Favoritos

Sin UPDATE: el toggle es siempre DELETE + INSERT. PK compuesta `(usuario_id, producto_id)` evita duplicados. Solo el propio usuario puede tocar sus favoritos (RLS).

---

## Máquinas de estados

### `productos`
```
disponible ──[raciones=0 al aceptar]──► agotado
           ──[propietario cancela]────► cancelado
agotado    ──[raciones restituidas]───► disponible
```
> `completado` y `reservado` existen en el CHECK pero ningún flujo activo los usa.

### `solicitudes_oferta`
```
pendiente ──[propietario acepta]────► aceptada
          ──[propietario deniega]───► denegada
          ──[solicitante cancela]───► cancelada
          ──[stock insuficiente]────► auto_denegada
```

### `transacciones`
```
aceptada ──[cualquier participante]──► completada
         ──[cualquier participante]──► cancelada
```
> `pendiente` y `reportada` existen en el CHECK pero no los usa ningún flujo activo.
