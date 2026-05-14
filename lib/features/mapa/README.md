# Mapa

Pestaña de mapa con los productos cercanos representados como marcadores.

## Pantallas

- `mapa_screen.dart` — `flutter_map` con tiles OpenStreetMap, marcadores agrupados por proximidad y bottom sheet de detalle al pulsar un marcador.

## Providers

- `mapa_providers.dart` — productos cercanos al centro del mapa (compartidos con el feed) y estado de la cámara/zoom.

## Backend

- Misma RPC que el feed: `obtener_productos_cercanos`.
- Las coordenadas que se muestran son las `latitud_publica` / `longitud_publica` deliberadamente difuminadas. Las exactas solo se entregan vía RPC `obtener_ubicacion_exacta_producto` cuando hay transacción aceptada.

## Notas

El primer render dependía antes de un zoom manual; el fix actual fuerza un `addPostFrameCallback` tras `onMapReady` para que el viewport se recalcule en el primer frame.
