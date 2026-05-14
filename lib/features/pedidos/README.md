# Pedidos

Vista unificada de solicitudes enviadas/recibidas y transacciones (compras, ventas e intercambios) del usuario.

## Pantallas

- `pedidos_screen.dart` — tabs con los paneles de "Enviadas", "Recibidas" y "Cerradas". Cada tarjeta resume estado y permite acciones contextuales (aceptar/denegar/cancelar) según el rol del usuario.
- `detalle_transaccion_screen.dart` — detalle de una transacción concreta: participantes, productos, estado, historial y acciones disponibles (cancelar, completar, valorar).

## Controllers

- `transaccion_controller.dart` — cancelar (`cancelar_transaccion`) y completar (`completar_transaccion`) una transacción.

## Widgets

- `tarjeta_solicitud_oferta.dart`, `tarjeta_transaccion.dart` — tarjetas con la misma estética para ambos tipos de elementos.
- `insignia_valoracion_compacta.dart`, `titulo_seccion.dart` — adornos visuales.

## Providers

- `pedido_unificado_provider.dart` — combina solicitudes y transacciones del usuario en un único stream para alimentar los paneles.
- `panel_pedidos_provider.dart` — separación por estado (pendiente / aceptada / completada / cancelada).

## Backend

- Tablas `transacciones`, `solicitudes_oferta`, `productos`.
- RPCs: `aceptar_solicitud_oferta`, `denegar_solicitud_oferta`, `cancelar_solicitud_oferta`, `cancelar_transaccion`, `completar_transaccion`.
- Modelo unificado para ventas e intercambios: `tipo in ('venta', 'intercambio')` y participantes `solicitante_id` / `propietario_id`.
