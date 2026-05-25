# Chat

Mensajería en tiempo real entre participantes de una solicitud/transacción.

## Pantallas

- `lista_chats_screen.dart` — bandeja de conversaciones con contador de no leídos por chat y enrutamiento al detalle.
- `chat_screen.dart` — pantalla de conversación; envía mensajes, marca los recibidos como leídos al entrar y muestra "está escribiendo…".

## Controllers / Providers

- `chat_controller.dart` — envío de mensajes y marcado masivo de leídos.
- `chat_providers.dart` — streams Realtime de mensajes por conversación y conteo agregado de no leídos.
- `typing_indicator_controller.dart` — broadcast del estado "escribiendo" vía canal Realtime (no se persiste).

## Backend

- Tablas `conversaciones` y `mensajes`.
- La conversación se crea al momento de aceptar una solicitud (RPC `aceptar_solicitud_oferta`), no en el registro inicial.
- Marcado de leído con GRANT escalpelo: la policy de UPDATE permite tocar mensajes ajenos, pero el GRANT está restringido a la columna `leido_en` (ver §7 de la documentación técnica).
- Mensajes y conversaciones llegan en vivo por Supabase Realtime.
