# Solicitudes

Creación y gestión de solicitudes de oferta (compras e intercambios pendientes de aceptación).

## Controllers

- `solicitud_oferta_controller.dart` — alta de solicitud (`crear_solicitud_oferta`) y cancelación por parte del solicitante (`cancelar_solicitud_oferta`). La aceptación/denegación la hace el propietario desde `features/pedidos`.

## Capas

- `data/dtos/solicitud_oferta_dto.dart` — DTO de la tabla.
- `domain/entities/solicitud_oferta_model.dart` y `solicitud_oferta_creada_model.dart` — modelos consumidos por la UI.
- `domain/entities/resultado_aceptacion_solicitud_model.dart` — payload devuelto por la RPC de aceptación (incluye id de la transacción creada y posibles auto-denegaciones).

## Backend

- Tabla `solicitudes_oferta` (`producto_id`, `solicitante_id`, `tipo`, `raciones`, `producto_ofrecido_id` en intercambios, `estado`).
- Estados: `pendiente`, `aceptada`, `denegada`, `auto_denegada`, `cancelada`.
- Índice único parcial impide solicitudes pendientes duplicadas por (producto, solicitante).
- RPCs: `crear_solicitud_oferta`, `aceptar_solicitud_oferta`, `denegar_solicitud_oferta`, `cancelar_solicitud_oferta`.
- La RPC de aceptación crea atómicamente la transacción, decrementa raciones y auto-deniega solicitudes competidoras que ya no caben.
