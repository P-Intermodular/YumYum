# Divergencias Frente Al Diseno Documental

Este documento recoge las decisiones tomadas al implementar el backend de YumYum con Supabase. El objetivo es mantener la intencion funcional de los diagramas del TFG, pero adaptarla a un backend seguro, transaccional y mantenible.

## Decisiones

- `usuario.password`: no se implementa en una tabla publica. Las credenciales quedan gestionadas por Supabase Auth.
- `Usuario`: se divide en `auth.users` para autenticacion y `perfiles` para datos publicos de perfil.
- `PerfilCocinero.certificacionSanitaria`: se implementa como `perfiles.certificacion_sanitaria`.
- `PerfilComprador.preferencias`: se implementa como `perfiles.preferencias`.
- Roles comprador/cocinero/intercambiador: se modelan como capacidades del usuario, no como roles exclusivos. Cualquier usuario puede comprar, publicar o intercambiar.
- Moderacion: se implementa con `perfiles.es_moderador`.
- Valoracion binaria: se implementa como puntuacion de 1 a 5 para coincidir con la UI actual y permitir media agregada en perfiles.
- `Pedido` y `LineaPedido`: se simplifican a una transaccion de un producto por MVP mediante `transacciones`.
- `Intercambio` e `IntercambioPlato`: se simplifican a intercambio 1 a 1 por MVP mediante `transacciones.producto_ofrecido_id`.
- `Mensaje`: se vincula a `conversaciones` para soportar chat en tiempo real con Supabase Realtime.
- `reportes.objetivo_id`: se mantiene polimorfico para MVP. Es una limitacion aceptada para evitar tablas de reporte separadas por entidad.
- Ubicacion exacta: no se expone en lecturas publicas de productos. Solo se consulta mediante `obtener_ubicacion_exacta_producto` cuando hay una transaccion aceptada o completada.
- Busqueda por proximidad: se realiza en PostgreSQL mediante las extensiones `cube` y `earthdistance`, un indice GIST parcial sobre productos disponibles y la RPC `obtener_productos_cercanos`. El cliente elige radio en pasos discretos (1, 3, 5, 10, 25, 50 km; por defecto 10 km). Si el usuario deniega permiso o el GPS no responde, el feed hace fallback al catalogo completo sin proximidad.

## Glosario Backend

### Tablas

- `perfiles`: datos publicos y configurables del usuario autenticado.
- `productos`: ofertas publicadas por los usuarios, con venta o intercambio.
- `imagenes_producto`: imagenes asociadas a un producto y almacenadas en Supabase Storage.
- `solicitudes_oferta`: peticiones de compra o intercambio antes de cerrar una transaccion.
- `transacciones`: ventas e intercambios aceptados, unificados en una sola tabla.
- `conversaciones`: chat asociado a una solicitud de oferta.
- `mensajes`: mensajes enviados dentro de una conversacion.
- `valoraciones`: puntuaciones de 1 a 5 sobre transacciones completadas.
- `reportes`: reportes de producto, perfil o mensaje.
- `notificaciones`: avisos internos generados por acciones relevantes del sistema.

### Columnas Principales

- `propietario_id`: usuario propietario de un producto.
- `solicitante_id`: usuario que crea una solicitud.
- `comprador_id` y `vendedor_id`: participantes de una transaccion o conversacion.
- `tipo_oferta`, `tipo_solicitud` y `tipo`: distinguen `venta` e `intercambio`.
- `producto_ofrecido_id`: producto propuesto por el solicitante en un intercambio.
- `producto_valorado_id`: producto concreto al que se asocia una valoracion cuando aplica.
- `latitud_publica` y `longitud_publica`: ubicacion aproximada visible en feed y mapa.
- `latitud_exacta` y `longitud_exacta`: ubicacion protegida para participantes aceptados.
- `valoracion_media` y `numero_valoraciones`: agregados derivados de `valoraciones`.
- `certificacion_sanitaria`: dato opcional del perfil cocinero.
- `creado_en`, `actualizado_en`, `respondido_en`, `completado_en`, `leido_en`: trazabilidad temporal.

### RPCs

- `crear_solicitud_oferta`: crea solicitud, conversacion y notificacion inicial.
- `aceptar_solicitud_oferta`: acepta atomicamente una solicitud, reserva productos, crea transaccion y auto-deniega competidoras.
- `denegar_solicitud_oferta`: registra una denegacion manual.
- `completar_transaccion`: marca la transaccion y sus productos como completados.
- `obtener_ubicacion_exacta_producto`: devuelve ubicacion exacta solo a usuarios autorizados.
- `obtener_productos_cercanos`: lista productos disponibles dentro de un radio en kilometros desde la ubicacion indicada, ordenados por distancia y con el mismo shape que el feed general mas `distancia_km`.

### Buckets

- `imagenes-productos`: imagenes publicas de ofertas.
- `avatares`: imagenes publicas de perfil.

### Estados Y Valores De Dominio

- Tipos de oferta, solicitud y transaccion: `venta`, `intercambio`.
- Productos: `disponible`, `reservado`, `completado`, `cancelado`.
- Solicitudes: `pendiente`, `aceptada`, `denegada`, `auto_denegada`, `cancelada`.
- Transacciones: `pendiente`, `aceptada`, `completada`, `cancelada`, `reportada`.
- Reportes: `abierta`, `en_revision`, `resuelta`, `descartada`.

## Equivalencias Con Los Diagramas Del TFG

- `Usuario` se corresponde con `auth.users` mas `perfiles`.
- `PerfilCocinero` se representa con los campos opcionales de `perfiles`, especialmente `certificacion_sanitaria`.
- `PerfilComprador` se representa con `perfiles.preferencias`.
- `Plato` u oferta publicada se corresponde con `productos`.
- `Pedido` se corresponde con una fila de `transacciones` de tipo `venta`.
- `IntercambioPlato` se corresponde con una fila de `transacciones` de tipo `intercambio`.
- `Mensaje` se corresponde con `mensajes`, agrupados por `conversaciones`.
- Los reportes de moderacion se corresponden con `reportes`.

## Motivo General

El diseno documental describe el dominio de negocio. La implementacion Supabase introduce ajustes para:

- evitar almacenar contrasenas fuera del proveedor de autenticacion;
- preservar historico con soft delete;
- impedir estados inconsistentes con RPCs atomicas;
- proteger datos con Row Level Security;
- reducir complejidad del MVP sin cerrar futuras ampliaciones.
