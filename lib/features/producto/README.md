# Producto

Publicación, edición, eliminación y detalle de los productos (ofertas).

## Pantallas

- `publicar_producto_screen.dart` — formulario en pasos para publicar una nueva oferta (datos básicos, fotos, ubicación, raciones, etiquetas dietéticas/alérgenos, tipo de oferta).
- `detalle_producto_screen.dart` — vista completa de un producto: carrusel, perfil del propietario, métricas, FAB de contacto/solicitud y, si el usuario es propietario, opciones de editar/eliminar.

## Controllers

- `publicar_producto_controller.dart` — orquesta validación, subida de imágenes al bucket `imagenes-productos` y creación del producto.
- `datos_publicacion_producto.dart` — `StateNotifier` con el estado del formulario por pasos.
- `contacto_producto_controller.dart` — punto de entrada para solicitar compra o intercambio desde la pantalla de detalle.

## Widgets

- `carrusel_imagenes.dart` — galería del detalle.
- `contacto_bottom_sheet.dart` — bottom sheet para elegir raciones y producto a ofrecer en intercambios.
- `selector_radio_busqueda.dart` — chips de radio (1/3/5/10/25/50 km) reutilizado por filtros.

## Providers

- `producto_providers.dart` — provider familia por id, listados por propietario, etc.
- `ubicacion_exacta_provider.dart` — consulta la RPC protegida cuando el usuario tiene derecho a ver la ubicación exacta.

## Backend

- Tablas `productos`, `imagenes_producto`.
- Bucket Storage `imagenes-productos` (público, con políticas RLS para crear y borrar).
- RPCs: `crear_solicitud_oferta`, `eliminar_producto`, `obtener_ubicacion_exacta_producto`.
- Estados de producto: `disponible`, `reservado` (vestigial), `completado`, `cancelado`. Cambios manuales bloqueados desde cliente por trigger `BEFORE UPDATE`.
