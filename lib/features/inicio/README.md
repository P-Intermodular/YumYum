# Inicio

Pestaña principal: feed de productos cercanos con buscador, filtros y FAB del asistente IA.

## Pantallas

- `inicio_screen.dart` — feed scrolleable con header, buscador, chips de categoría, hero de producto destacado, lista de tarjetas (`FilaPlato`), FAB del asistente IA y FAB "volver arriba".

## Widgets

- `cabecera_inicio.dart`, `buscador_feed.dart`, `chips_categoria.dart` — controles del header.
- `hero_plato.dart`, `fila_plato.dart` — tarjetas del feed.
- `filtros_feed_bottom_sheet.dart` — bottom sheet con filtros avanzados (categoría, etiquetas dietéticas, alérgenos a excluir, radio, orden, tipo de oferta).
- `seccion_titulo.dart` — separadores tipográficos.

## Providers

- `feed_filtros_providers.dart` — estado de todos los filtros del feed (`autoDispose.family`) y derivados con la lista filtrada. Se invalida en bloque cuando cambia la ubicación o el usuario.

## Backend

- RPC `obtener_productos_cercanos(p_lat, p_lon, p_radio_km, p_limit)` — devuelve productos `disponible` ordenados por distancia con el shape común del feed más `distancia_km`.
- Si el usuario deniega permisos o el GPS falla, se hace fallback al catálogo completo sin proximidad.
- Tabla `productos` (filtrado client-side por categoría, alérgenos del perfil, etc.).
