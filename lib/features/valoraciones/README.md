# Valoraciones

Puntuación 1-5 sobre transacciones completadas, con recálculo automático de la media en `perfiles`.

## Pantallas

- `valorar_transaccion_screen.dart` — formulario de valoración (estrellas + comentario) al cerrar una transacción.

## Controllers

- `valoracion_controller.dart` — alta de la valoración asociada a una transacción completada.

## Capas

- `data/dtos/valoracion_dto.dart`, `domain/entities/valoracion_model.dart` — modelo de fila.
- `data/repositories/supabase_valoracion_repository.dart`, `domain/repositories/valoracion_repository.dart` — contrato y acceso.

## Backend

- Tabla `valoraciones` (`transaccion_id`, `valorador_id`, `valorado_id`, `puntuacion`, `comentario`, `producto_valorado_id`).
- Trigger `AFTER INSERT` recalcula `perfiles.valoracion_media` y `numero_valoraciones`. Los casos `AFTER DELETE` y `AFTER UPDATE` son deuda técnica documentada (§9-§10).
- Solo es valorable un usuario con el que existe una transacción `completada` no valorada previamente.
