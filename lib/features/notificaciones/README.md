# Notificaciones

Bandeja de notificaciones internas del usuario con badge dinámico en el AppBar.

## Pantallas

- `notificaciones_screen.dart` — listado realtime de notificaciones del usuario. Al pulsar una, enruta a la pantalla correspondiente según `tipo` (chat, detalle de producto, detalle de transacción…).

## Providers

- `notificacion_providers.dart` — stream Realtime de las notificaciones del usuario, badge agregado (no leídas) y filtros client-side por las preferencias guardadas en `perfiles.preferencias_notificaciones`.

## Capas

- `data/dtos/notificacion_dto.dart` — normaliza el `payload` JSONB con las claves esperadas por tipo (`solicitud_id`, `producto_id`, `conversacion_id`, `transaccion_id`).
- `domain/entities/notificacion_model.dart` — modelo consumido por la UI.

## Backend

- Tabla `notificaciones` (`usuario_id`, `tipo`, `payload jsonb`, `leida_en`, `creado_en`).
- Las inserciones las disparan triggers/RPCs de negocio (al crear solicitud, aceptar, denegar, cancelar, etc.); el cliente nunca inserta directamente.
- Llegada en vivo por Supabase Realtime.
