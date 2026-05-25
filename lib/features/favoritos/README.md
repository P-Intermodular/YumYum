# Favoritos

Productos guardados por el usuario para consultarlos desde "Guardados".

## Pantallas

- `guardados_screen.dart` — listado de productos marcados como favoritos, con la misma tarjeta visual del feed.

## Widgets

- `tarjeta_plato_guardado.dart` — variante de la tarjeta para esta pantalla.

## Controllers / Providers

- `favorito_controller.dart` — toggle añadir/quitar favorito desde la tarjeta o el detalle de producto.
- `favorito_providers.dart` — `Set<String>` de ids favoritos (consultas rápidas con `contains`) y listado completo agregado con datos del producto. Ambos se actualizan en vivo vía stream Realtime.

## Backend

- Tabla `favoritos` (`usuario_id`, `producto_id`, `creado_en`).
- Restricción de unicidad por par (usuario, producto).
- Las consultas agregadas hacen JOIN con `productos` para devolver tarjetas completas en una sola llamada.
