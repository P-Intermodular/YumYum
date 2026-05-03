# Documentación Técnica — YumYum

## 1. Visión general
YumYum es una aplicación móvil y web diseñada para facilitar la venta e intercambio local de comida casera. Actúa como un mercado de proximidad donde los usuarios pueden publicar sus elaboraciones ("ofertas" que pueden ser para venta o intercambio) y negociar directamente a través de un chat en tiempo real integrado. El valor principal de la aplicación reside en conectar vecinos para reducir el desperdicio de comida, fomentar la economía local y facilitar transacciones basadas en la cercanía geográfica, garantizando la privacidad de las ubicaciones exactas hasta que se cierra un acuerdo mutuo.

## 2. Stack tecnológico
El proyecto sigue una arquitectura moderna centrada en el desarrollo multiplataforma y un backend Serverless/BaaS (Backend as a Service):

*   **Frontend:**
    *   **Flutter (SDK >=3.3.0):** Framework elegido por su capacidad de compilar para iOS, Android y Web desde una única base de código.
    *   **Riverpod:** Gestor de estado reactivo. Permite inyección de dependencias segura, manejo simplificado del estado asíncrono (datos que vienen de red) y un bajo acoplamiento.
    *   **GoRouter:** Sistema de enrutamiento declarativo para gestionar la navegación compleja (ShellRoutes con BottomNavigationBar) y las redirecciones de autenticación de forma reactiva.
    *   **Flutter Map & LatLong2:** Librerías para renderizar los mapas interactivos con un enfoque *open-source* (sin dependencia estricta inicial de Google Maps SDK comercial).
*   **Backend & Base de Datos:**
    *   **Supabase (PostgreSQL):** Elegido como BaaS. Provee base de datos relacional potente, autenticación delegada, control de acceso a nivel de fila (RLS), almacenamiento de archivos (Storage) y notificaciones en tiempo real vía WebSockets (Realtime).
*   **Infraestructura:**
    *   El frontend web está preparado para despliegue como sitio estático en **Render** mediante scripts de CI automatizados.

## 3. Arquitectura general
La arquitectura global sigue el paradigma **Feature-First** (por funcionalidades) en el frontend y un enfoque **"Thick Database"** en el backend.

**Capas del Frontend (`lib/`):**
*   **Core (`lib/core/`):** Utilidades transversales, configuración de Supabase, enrutador, manejo de errores, proveedores de ubicación y temas visuales.
*   **Features (`lib/features/`):** Módulos aislados (auth, producto, solicitudes, mapa, etc.). Dentro de cada módulo se sigue una variación de Clean Architecture adaptada a Riverpod:
    *   *Domain:* Modelos y entidades puras de Dart (`ProductoModel`, `UsuarioModel`).
    *   *Data:* Repositorios (y opcionalmente DTOs) que encapsulan las llamadas a Supabase.
    *   *Controllers/Providers:* Notificadores de Riverpod que contienen la lógica de negocio y manejan el estado (e.g. `PublicarProductoController`).
    *   *Screens/Widgets:* La capa de interfaz de usuario puramente declarativa y reactiva a los Providers.

**Capas del Backend (Supabase):**
*   **Autenticación:** Gestionada por el módulo GoTrue de Supabase.
*   **Capa de Acceso y Reglas (RLS):** Las consultas pasan primero por las políticas de PostgreSQL, asegurando que un usuario solo lee/escribe lo que le corresponde.
*   **Lógica Transaccional:** Se apoya fuertemente en Procedimientos Almacenados (RPCs) de PL/pgSQL para garantizar atomicidad y evitar inconsistencias sin tener que montar una API Node/Python intermedia.

## 4. Modelo de datos
El modelo relacional está diseñado en PostgreSQL e implementa múltiples constricciones (CHECKs), disparadores (Triggers) de integridad e índices estratégicos (obtenidos de las migraciones SQL) para optimizar el rendimiento y prevenir estados anómalos. A continuación, se detalla el esquema consolidado:

### `public.perfiles`
Extiende `auth.users` de Supabase. Almacena datos públicos y preferencias.
*   **Columnas:**
    *   `id` UUID (PK)
    *   `nombre` TEXT (NOT NULL)
    *   `email` TEXT (NOT NULL, UNIQUE)
    *   `url_avatar` TEXT (NOT NULL, DEFAULT '')
    *   `ciudad` TEXT
    *   `preferencias` TEXT[] (NOT NULL, DEFAULT '{}')
    *   `certificacion_sanitaria` TEXT
    *   `es_moderador` BOOLEAN (NOT NULL, DEFAULT false)
    *   `valoracion_media` NUMERIC(3, 2) (NOT NULL, DEFAULT 0)
    *   `numero_valoraciones` INTEGER (NOT NULL, DEFAULT 0)
    *   `latitud_predeterminada` NUMERIC(9, 6)
    *   `longitud_predeterminada` NUMERIC(9, 6)
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
    *   `actualizado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
*   **Relaciones:** FK `id` references `auth.users(id)` ON DELETE CASCADE.

### `public.productos`
Las ofertas publicadas en la plataforma.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `propietario_id` UUID (NOT NULL)
    *   `titulo` TEXT (NOT NULL)
    *   `descripcion` TEXT (NOT NULL)
    *   `tipo_oferta` TEXT (NOT NULL)
    *   `precio` NUMERIC(10, 2)
    *   `estado` TEXT (NOT NULL, DEFAULT 'disponible')
    *   `latitud_publica` NUMERIC(9, 6) (NOT NULL)
    *   `longitud_publica` NUMERIC(9, 6) (NOT NULL)
    *   `latitud_exacta` NUMERIC(9, 6)
    *   `longitud_exacta` NUMERIC(9, 6)
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
    *   `actualizado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
*   **Constraints:**
    *   CHECK `tipo_oferta` in ('venta', 'intercambio')
    *   CHECK `estado` in ('disponible', 'reservado', 'completado', 'cancelado')
    *   CHECK: Si es 'venta', `precio` >= 0 y NOT NULL. Si es 'intercambio', `precio` is NULL.
*   **Relaciones:** FK `propietario_id` references `public.perfiles(id)` ON DELETE RESTRICT.
*   **Índices:**
    *   `productos_estado_creado_en_idx` (estado, creado_en DESC)
    *   `productos_propietario_estado_idx` (propietario_id, estado)
    *   `productos_ubicacion_idx` (Índice GiST usando `earthdistance` cuando estado = 'disponible')

### `public.imagenes_producto`
Fotos asociadas a un producto.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `producto_id` UUID (NOT NULL)
    *   `ruta_storage` TEXT (NOT NULL)
    *   `url_publica` TEXT (NOT NULL)
    *   `posicion` INTEGER (NOT NULL, DEFAULT 0)
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
*   **Constraints:** UNIQUE (`producto_id`, `posicion`)
*   **Relaciones:** FK `producto_id` references `public.productos(id)` ON DELETE CASCADE.
*   **Índices:** `imagenes_producto_producto_posicion_idx` (producto_id, posicion)

### `public.solicitudes_oferta`
Peticiones de compra/intercambio iniciadas por un usuario.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `producto_id` UUID (NOT NULL)
    *   `solicitante_id` UUID (NOT NULL)
    *   `propietario_id` UUID (NOT NULL)
    *   `tipo_solicitud` TEXT (NOT NULL)
    *   `producto_ofrecido_id` UUID
    *   `mensaje` TEXT
    *   `estado` TEXT (NOT NULL, DEFAULT 'pendiente')
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
    *   `respondido_en` TIMESTAMPTZ
*   **Constraints:**
    *   CHECK `tipo_solicitud` in ('venta', 'intercambio')
    *   CHECK `estado` in ('pendiente', 'aceptada', 'denegada', 'auto_denegada', 'cancelada')
    *   CHECK `solicitante_id` <> `propietario_id`
    *   CHECK: si es venta `producto_ofrecido_id` is NULL; si es intercambio, NOT NULL.
*   **Relaciones:**
    *   FK `producto_id` references `public.productos(id)` ON DELETE RESTRICT
    *   FK `solicitante_id` references `public.perfiles(id)` ON DELETE CASCADE
    *   FK `propietario_id` references `public.perfiles(id)` ON DELETE CASCADE
    *   FK `producto_ofrecido_id` references `public.productos(id)` ON DELETE RESTRICT
*   **Índices:**
    *   `solicitudes_oferta_propietario_estado_creado_en_idx` (propietario_id, estado, creado_en DESC)
    *   `solicitudes_oferta_solicitante_estado_creado_en_idx` (solicitante_id, estado, creado_en DESC)
    *   `solicitudes_oferta_producto_estado_idx` (producto_id, estado)
    *   `solicitudes_oferta_producto_ofrecido_estado_idx` (producto_ofrecido_id, estado)
    *   UNIQUE parcial `solicitudes_oferta_pendiente_unica_idx` en (producto_id, solicitante_id) WHERE estado = 'pendiente' (bloquea duplicados).

### `public.transacciones`
Cierre de un acuerdo entre dos partes.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `solicitud_id` UUID (NOT NULL, UNIQUE)
    *   `tipo` TEXT (NOT NULL)
    *   `producto_id` UUID (NOT NULL)
    *   `producto_ofrecido_id` UUID
    *   `solicitante_id` UUID (NOT NULL)
    *   `propietario_id` UUID (NOT NULL)
    *   `total` NUMERIC(10, 2)
    *   `estado` TEXT (NOT NULL, DEFAULT 'aceptada')
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
    *   `completado_en` TIMESTAMPTZ
*   **Constraints:**
    *   CHECK `tipo` in ('venta', 'intercambio')
    *   CHECK `estado` in ('pendiente', 'aceptada', 'completada', 'cancelada', 'reportada')
    *   CHECK `transacciones_participantes_distintos_check` (`solicitante_id` <> `propietario_id`)
    *   CHECK: si es venta `total` is NOT NULL y `producto_ofrecido_id` is NULL; si intercambio `total` is NULL.
*   **Relaciones:**
    *   FK `solicitud_id` references `public.solicitudes_oferta(id)` ON DELETE RESTRICT
    *   FK `producto_id` references `public.productos(id)` ON DELETE RESTRICT
    *   FK `producto_ofrecido_id` references `public.productos(id)` ON DELETE RESTRICT
    *   FK `solicitante_id` references `public.perfiles(id)` ON DELETE RESTRICT
    *   FK `propietario_id` references `public.perfiles(id)` ON DELETE RESTRICT
*   **Índices:**
    *   `transacciones_solicitante_estado_creado_en_idx` (solicitante_id, estado, creado_en DESC)
    *   `transacciones_propietario_estado_creado_en_idx` (propietario_id, estado, creado_en DESC)
    *   `transacciones_producto_idx` (producto_id)
    *   `transacciones_producto_ofrecido_idx` (producto_ofrecido_id)

### `public.conversaciones`
Sala de chat ligada a una solicitud o transacción en proceso.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `solicitud_id` UUID (NOT NULL, UNIQUE)
    *   `producto_id` UUID (NOT NULL)
    *   `solicitante_id` UUID (NOT NULL)
    *   `propietario_id` UUID (NOT NULL)
    *   `ultimo_mensaje_en` TIMESTAMPTZ
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
*   **Constraints:**
    *   CHECK `conversaciones_participantes_distintos_check` (`solicitante_id` <> `propietario_id`)
*   **Relaciones:**
    *   FK `solicitud_id` references `public.solicitudes_oferta(id)` ON DELETE CASCADE
    *   FK `producto_id` references `public.productos(id)` ON DELETE RESTRICT
    *   FK `solicitante_id` references `public.perfiles(id)` ON DELETE CASCADE
    *   FK `propietario_id` references `public.perfiles(id)` ON DELETE CASCADE
*   **Índices:**
    *   `conversaciones_solicitud_idx` (solicitud_id)
    *   `conversaciones_solicitante_idx` (solicitante_id)
    *   `conversaciones_propietario_idx` (propietario_id)
    *   `conversaciones_producto_idx` (producto_id)

### `public.mensajes`
Mensajes individuales ligados a una conversación.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `conversacion_id` UUID (NOT NULL)
    *   `remitente_id` UUID (NOT NULL)
    *   `contenido` TEXT (NOT NULL)
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
    *   `leido_en` TIMESTAMPTZ
*   **Constraints:** CHECK `length(trim(contenido)) > 0`
*   **Relaciones:**
    *   FK `conversacion_id` references `public.conversaciones(id)` ON DELETE CASCADE
    *   FK `remitente_id` references `public.perfiles(id)` ON DELETE CASCADE
*   **Índices:**
    *   `mensajes_conversacion_creado_en_idx` (conversacion_id, creado_en DESC)
    *   `mensajes_remitente_idx` (remitente_id)

### `public.valoraciones`
Puntuaciones emitidas tras completarse una transacción.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `transaccion_id` UUID (NOT NULL)
    *   `valorador_id` UUID (NOT NULL)
    *   `valorado_id` UUID (NOT NULL)
    *   `producto_valorado_id` UUID
    *   `puntuacion` INTEGER (NOT NULL)
    *   `comentario` TEXT
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
*   **Constraints:**
    *   CHECK `puntuacion` between 1 and 5
    *   CHECK `valorador_id` <> `valorado_id`
    *   UNIQUE (`transaccion_id`, `valorador_id`)
*   **Relaciones:**
    *   FK `transaccion_id` references `public.transacciones(id)` ON DELETE CASCADE
    *   FK `valorador_id` references `public.perfiles(id)` ON DELETE CASCADE
    *   FK `valorado_id` references `public.perfiles(id)` ON DELETE CASCADE
    *   FK `producto_valorado_id` references `public.productos(id)` ON DELETE RESTRICT
*   **Índices:**
    *   `valoraciones_valorado_creado_en_idx` (valorado_id, creado_en DESC)
    *   `valoraciones_producto_valorado_idx` (producto_valorado_id)
    *   `valoraciones_valorador_idx` (valorador_id)

### `public.reportes`
Sistema de moderación polimórfico.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `reportante_id` UUID (NOT NULL)
    *   `tipo_objetivo` TEXT (NOT NULL)
    *   `objetivo_id` UUID (NOT NULL)
    *   `motivo` TEXT (NOT NULL)
    *   `estado` TEXT (NOT NULL, DEFAULT 'abierta')
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
    *   `resuelto_en` TIMESTAMPTZ
*   **Constraints:**
    *   CHECK `tipo_objetivo` in ('producto', 'perfil', 'mensaje')
    *   CHECK `estado` in ('abierta', 'en_revision', 'resuelta', 'descartada')
*   **Relaciones:** FK `reportante_id` references `public.perfiles(id)` ON DELETE CASCADE
*   **Índices:** `reportes_reportante_idx` (reportante_id)

### `public.notificaciones`
Alertas generadas por el sistema.
*   **Columnas:**
    *   `id` UUID (PK, DEFAULT gen_random_uuid())
    *   `usuario_id` UUID (NOT NULL)
    *   `tipo` TEXT (NOT NULL)
    *   `titulo` TEXT (NOT NULL)
    *   `contenido` TEXT (NOT NULL)
    *   `datos` JSONB (NOT NULL, DEFAULT '{}'::jsonb)
    *   `leido_en` TIMESTAMPTZ
    *   `creado_en` TIMESTAMPTZ (NOT NULL, DEFAULT now())
*   **Relaciones:** FK `usuario_id` references `public.perfiles(id)` ON DELETE CASCADE
*   **Índices:** `notificaciones_no_leidas_usuario_creado_en_idx` (usuario_id, creado_en DESC) WHERE `leido_en` is NULL

*Decisiones de diseño destacables:* 
*   **Soft Delete ausente pero suplido por "Estados":** En lugar de borrar registros físicos, entidades clave como productos, solicitudes y transacciones dependen fuertemente de una máquina de estados (`disponible`, `cancelado`, `auto_denegada`, `completada`). No obstante, en `perfiles` hay un `ON DELETE CASCADE` desde `auth.users` que es peligroso financieramente.
*   **Cálculo Espacial en BD:** Se evitan sistemas GIS pesados usando las extensiones nativas `cube` y `earthdistance` de PostgreSQL para calcular proximidad directamente.

## 5. Endpoints de la API
Como no hay un backend REST tradicional intermedio, la "API" son las llamadas directas a las tablas protegidas por RLS, apoyadas por funciones RPC para operaciones complejas.

**RPCs (Endpoints transaccionales personalizados):**
*   `POST /rpc/obtener_mi_perfil`: (Auth requerido). Devuelve los datos completos del perfil del usuario autenticado, incluyendo los campos privados (`email`, `latitud_predeterminada`, `longitud_predeterminada`) que la RLS de la tabla `perfiles` no expone vía consulta directa. Es el único punto de acceso del cliente a su información privada.
*   `POST /rpc/crear_solicitud_oferta`: (Auth requerido). Crea una solicitud, inicia un chat y lanza una notificación atómicamente. Recibe `producto_id`, `tipo_solicitud` y un posible `producto_ofrecido_id`.
*   `POST /rpc/cancelar_solicitud_oferta`: (Solo Solicitante). Cancela una solicitud que sigue en estado pendiente.
*   `POST /rpc/aceptar_solicitud_oferta`: (Solo Propietario). Acepta la petición, genera la `transaccion` final, reserva los productos, y *deniega automáticamente* al resto de competidores.
*   `POST /rpc/denegar_solicitud_oferta`: (Solo Propietario). Actualiza la solicitud a estado "denegada".
*   `POST /rpc/cancelar_transaccion`: (Cualquier Participante). Cancela una transacción aceptada y devuelve los productos a estado disponible.
*   `POST /rpc/completar_transaccion`: (Comprador o Vendedor). Marca la transacción como concluida, habilitando la capacidad de valorar al otro usuario.
*   `POST /rpc/obtener_ubicacion_exacta_producto`: (Comprador o Vendedor con transacción aceptada). Devuelve las coordenadas reales, puenteando el nivel de privacidad inicial.
*   `POST /rpc/obtener_productos_cercanos`: (Auth requerido). Motor principal de búsqueda. Recibe origen (lat, lng), un radio en km y un límite. Devuelve productos y sus dueños transformando distancias al vuelo.

**Triggers de base de datos relevantes:**
*   `crear_perfil_usuario` sobre `auth.users` (AFTER INSERT): inserta el registro espejo en `public.perfiles`.
*   `sincronizar_email_perfil` sobre `auth.users` (AFTER UPDATE OF email): propaga cambios de email al perfil público.
*   `recalcular_valoracion_perfil` sobre `public.valoraciones` (AFTER INSERT): recalcula `valoracion_media` y `numero_valoraciones` del usuario valorado.
*   `actualizar_ultimo_mensaje_conversacion` sobre `public.mensajes` (AFTER INSERT): actualiza `ultimo_mensaje_en` en la conversación correspondiente para que el listado de chats se ordene por actividad reciente.
*   `validar_transicion_estado_producto` sobre `public.productos` (BEFORE UPDATE): impide al cliente forzar manualmente estados internos (`reservado`, `completado`); solo permite la transición `disponible` → `cancelado` desde rol `authenticated`.

**Buckets de Storage:**
*   `imagenes-productos` (público en lectura): aloja las fotos de los productos. La escritura está restringida por RLS de `storage.objects` a la carpeta cuyo primer segmento coincide con el UUID del usuario.
*   `avatares` (público en lectura): aloja la foto de perfil del usuario. Misma política de carpeta por UUID; soporta INSERT y UPDATE para sobreescribir el avatar al editar el perfil.

## 6. Flujos principales

1.  **Registro y Autenticación:** El usuario se registra. Supabase emite un webhook interno de Auth que dispara el trigger `crear_perfil_usuario` para poblar la tabla pública `perfiles` con su nombre o prefijo de email.
2.  **Publicación de un Plato:** El usuario rellena los datos del producto (tipo, precio opcional, ubicación) y sube imágenes. La app inserta las imágenes a Supabase Storage y el registro principal a la tabla `productos` con estado "disponible".
3.  **Exploración del Feed (Búsqueda):** La pantalla principal y el mapa ejecutan `obtener_productos_cercanos`, usando las coordenadas del GPS del dispositivo y un radio configurable.
4.  **Negociación e Intercambio:**
    *   *Solicitud:* Usuario B encuentra un plato del Usuario A y envía una solicitud de compra/intercambio.
    *   *Chat:* Se abre una `conversación` en tiempo real.
    *   *Aceptación:* Usuario A pulsa "Aceptar". El backend transacciona: aprueba la solicitud, deniega otras, y aparta el inventario. Se revela la dirección exacta a Usuario B.
    *   *Cierre:* Tras el intercambio físico, un usuario marca la transacción como completada.
5.  **Feedback:** Se habilita la inserción de un registro en `valoraciones`. Un trigger asíncrono (`recalcular_valoracion_perfil`) re-calcula la media del usuario instantáneamente.

## 7. Decisiones técnicas relevantes
*   **Delegación de complejidad en PostgreSQL:** En lugar de crear un backend intermedio que verifique la atomicidad al crear transacciones, esta se asegura usando lógica PL/pgSQL (`SELECT ... FOR UPDATE`, manejo estricto de bloqueos en `aceptar_solicitud_oferta`). Esto reduce los puntos de falla pero acopla el sistema al motor de BD.
*   **Polimorfismo en Notificaciones y Reportes:** La tabla `reportes` tiene un `objetivo_id` UUID genérico y un `tipo_objetivo` (producto, perfil, mensaje). Es una solución de compromiso temporal, aceptada para un MVP para no multiplicar tablas.
*   **Separación de Coordenadas:** Existiendo un alto riesgo para los usuarios (que operan desde sus casas), almacenar `latitud_publica` intencionadamente "difuminada" y usar `latitud_exacta` protegida por RLS es una decisión de privacidad de diseño brillante.
*   **Privacidad de perfiles vía GRANT por columna + RPC:** La tabla `perfiles` aplica un patrón "RLS + GRANTs columnares" en lugar de una RLS amplia: se hace `revoke all` y luego `grant select (columnas_publicas)` a `authenticated`, dejando fuera del SELECT directo los campos sensibles (email, ubicación predeterminada). Para que el propio usuario pueda leer su perfil completo se expone la RPC `obtener_mi_perfil` (`security definer`). Esto evita filtraciones accidentales si una consulta del cliente no aplica el filtro `id = auth.uid()`.
*   **Marcar mensajes como leídos con GRANT escalpelo:** La policy de UPDATE sobre `mensajes` deja a un participante actualizar los mensajes ajenos de su conversación, pero el GRANT está restringido a la columna `leido_en` (`grant update (leido_en) on public.mensajes to authenticated`). Así, aunque la RLS permita la fila, PostgreSQL bloquea cualquier intento de alterar `contenido` o `remitente_id` antes incluso de evaluar la policy. La RLS controla *qué filas*, los GRANT controlan *qué columnas*; ambos son necesarios.

## 8. Estado actual del proyecto
*   **Implementado:** Arquitectura base de Flutter lista con Riverpod y GoRouter. Flujos de Auth, publicación, búsqueda por proximidad, solicitudes, transacciones y valoraciones cableados de extremo a extremo. Chat en tiempo real con cómputo de mensajes no leídos por conversación y marcado automático al entrar. Centro de notificaciones realtime suscrito a la tabla `notificaciones` vía Supabase Stream, con badge dinámico en el AppBar y enrutamiento contextual al chat/producto/pedido relacionado al pulsar la notificación. Edición de perfil con subida de avatar al bucket `avatares`. En el backend, las migraciones, RLS, triggers y RPCs están desplegadas y sincronizadas con remoto, aunque persisten algunos problemas de diseño relacional (ver sección 9).
*   **En Progreso / Estructurado:** Pulido visual de algunas pantallas y refinamiento de mensajes de error normalizados desde Supabase hacia la UI.
*   **Pendiente:** Despliegues continuos para las tiendas móviles, implementación de pasarelas de pago digitales si se desea escalar las "ventas" más allá del efectivo en mano, y pulido general de UI/UX a nivel granular.

## 9. Carencias y puntos de mejora
*   **Deuda técnica en Paginación:** El endpoint principal `obtener_productos_cercanos` recibe un parámetro de `limite` (limit = 50 por defecto), pero carece de un parámetro `offset` o soporte de paginación basada en cursor (Keyset pagination). A medida que crezca el volumen de productos, la app solo mostrará los 50 más cercanos, pero no permitirá "cargar más".
*   **Escalabilidad de Imágenes:** Actualmente, se suben fotos directamente a Supabase Storage y se obtienen las URLs estáticas. No hay evidencia de uso de compresión previa al subido (desde Flutter) o de un redimensionador dinámico (Image Transformation) en la descarga. Las imágenes muy pesadas lastrarán el consumo de datos móviles y la UI de los feeds (ListView).
*   **Riesgo y cascada destructiva en Auth (`ON DELETE CASCADE`):** 
    * Existe un conflicto de diseño entre el `ON DELETE CASCADE` de `perfiles` y el `ON DELETE RESTRICT` de `transacciones`. Si un usuario con transacciones completadas elimina su cuenta, el borrado fallará por restricción de Foreign Key, y no hay un flujo para bajas lógicas.
    * En contraste, las tablas `solicitudes_oferta` y `conversaciones` tienen `ON DELETE CASCADE` tanto para `solicitante_id` como para `propietario_id`. Si cualquiera de los dos elimina su cuenta (y no tiene transacciones completadas que lo bloqueen), la solicitud y la conversación entera se destruyen, eliminando el historial de chat para la contraparte.
    * En la tabla `mensajes`, `remitente_id` tiene `ON DELETE CASCADE`, por lo que todos los mensajes de un usuario borrado desaparecerán de las conversaciones de la otra persona.
    * En `valoraciones`, si el `valorador_id` o el `valorado_id` se eliminan, la valoración desaparece por `ON DELETE CASCADE`. Sin embargo, esto provoca una desincronización de los datos cacheados, ya que la `valoracion_media` y `numero_valoraciones` en `perfiles` del usuario restante no se actualizarán de forma retroactiva hasta que no reciba una nueva valoración que dispare el trigger.
*   **Estados fantasma en Transacciones:** 
    * El estado `pendiente` aparece en el `CHECK` de transacciones, pero nunca se utiliza en ningún flujo ni en la creación (las transacciones siempre nacen en estado `aceptada` desde la RPC).
    * El estado `reportada` existe en el esquema, pero no hay ninguna RPC, trigger ni flujo de moderación que cambie una transacción a este estado.
*   **Integridad en Reportes polimórficos:** La tabla `reportes` carece de integridad referencial dura (Foreign Keys) en su columna `objetivo_id` al utilizar un modelo polimórfico según el `tipo_objetivo`.
*   **Campo sin estructurar en Perfiles:** El campo `certificacion_sanitaria` es texto libre sin validación ni vinculación a un flujo de moderación, lo que representa un riesgo de fiabilidad en una plataforma de intercambio de alimentos.
*   **Cierre unilateral de transacciones:** La RPC `completar_transaccion` permite a cualquiera de los dos usuarios marcar unilateralmente la transacción como completada. Al carecer de un mecanismo de confirmación mutua, existe riesgo de manipulación de estado.
*   **Inconsistencia en Avatares:** El campo `url_avatar` en `perfiles` se gestiona como texto plano, sin una tabla que referencie los objetos de Storage o garantice la consistencia, a diferencia del sistema estructurado que sí tienen las `imagenes_producto`.

## 10. Recomendaciones
1.  **Añadir paginación al feed geográfico (Prioridad Alta):** Modificar la RPC `obtener_productos_cercanos` para recibir un offset o un ID de último producto visualizado, permitiendo un `ScrollController` infinito en el frontend (Riverpod Infinite Scroll).
2.  **Protección contable y Bajas Lógicas (Prioridad Alta):** Eliminar el borrado físico (`CASCADE`) de la tabla `perfiles` respecto a `auth.users`. Implementar un flujo de baja lógica mediante una columna `borrado_en: timestamptz` y procesos de anonimización de datos para mantener la integridad de las transacciones históricas y el historial de chat de las contrapartes sin bloquear la eliminación de cuentas.
3.  **Confirmación mutua en transacciones (Prioridad Alta):** Modificar la lógica de negocio para que `completar_transaccion` requiera la confirmación de ambas partes, previniendo cierres unilaterales prematuros o fraudulentos.
4.  **Saneamiento de la máquina de estados (Prioridad Media):** Eliminar del `CHECK` de `transacciones` los estados "fantasma" (`pendiente`, `reportada`) o, alternativamente, implementar los flujos de moderación y reservas previas que justifiquen su existencia.
5.  **Estructuración de validaciones sanitarias (Prioridad Media):** Refactorizar `certificacion_sanitaria` hacia un sistema de verificación con revisión manual, integrando el rol de `es_moderador` para otorgar insignias validadas, en lugar de permitir texto libre.
6.  **Compresión de Archivos y Storage (Prioridad Media):** Implementar la librería `flutter_image_compress` antes de enviar binarios a Storage. Normalizar la gestión del avatar de usuario implementando una tabla `imagenes_perfil` o asegurando que `url_avatar` siga las reglas de firmado de Storage.
7.  **Sistema de pagos (A futuro):** Definir si YumYum actuará como *escrow* o seguirá el modelo del MVP asumiendo la entrega física monetaria. Integrar Stripe Connect sería el siguiente paso lógico.

## 11. Reglas de negocio clave

A continuación se listan las reglas de negocio explícitas identificadas en las restricciones (CHECKs), disparadores (Triggers) y procedimientos almacenados (RPCs) de la base de datos:

1. **Creación de Solicitudes de Oferta**
   * **Entidades afectadas:** `productos`, `solicitudes_oferta`
   * **Condiciones:**
     * El producto solicitado debe estar en estado `disponible`.
     * El solicitante no puede ser el propietario del producto.
     * El tipo de solicitud debe coincidir con el `tipo_oferta` del producto.
     * Si la solicitud es de `venta`, no se debe incluir un `producto_ofrecido_id`.
     * Si la solicitud es de `intercambio`, el solicitante debe incluir obligatoriamente un `producto_ofrecido_id`. Este producto ofrecido debe pertenecer al solicitante, estar `disponible` y ser del tipo `intercambio`.
     * Un usuario no puede tener más de una solicitud en estado `pendiente` para el mismo producto simultáneamente.
   * **Consecuencia si no se cumple:** La solicitud es denegada y se lanza una excepción SQL que aborta la operación con un mensaje descriptivo para el cliente.

2. **Aceptación de Solicitudes**
   * **Entidades afectadas:** `solicitudes_oferta`, `productos`, `transacciones`, `conversaciones`
   * **Condiciones:**
     * Solo el propietario del producto solicitado puede aceptar la solicitud.
     * La solicitud debe encontrarse previamente en estado `pendiente`.
     * Los productos involucrados (solicitado y, si aplica, ofrecido) deben seguir existiendo y estar en estado `disponible`.
   * **Consecuencia (Si se cumple):** Se genera un registro en `transacciones` en estado `aceptada`. Los productos cambian a estado `reservado`. Automáticamente, cualquier otra solicitud `pendiente` que compitiera por los mismos productos se marca como `auto_denegada`.
   * **Consecuencia si no se cumple:** Se lanza una excepción SQL bloqueando la aceptación.

3. **Cancelación y Denegación de Solicitudes**
   * **Entidades afectadas:** `solicitudes_oferta`
   * **Condiciones:**
     * Para **cancelar**: Solo el creador de la solicitud (`solicitante_id`) puede cancelarla, y solo si sigue `pendiente`.
     * Para **denegar**: Solo el dueño del producto (`propietario_id`) puede denegarla, y solo si sigue `pendiente`.
   * **Consecuencia si no se cumple:** Se lanza una excepción impidiendo la alteración de estado.

4. **Cancelación de Transacciones Aceptadas**
   * **Entidades afectadas:** `transacciones`, `productos`
   * **Condiciones:**
     * Solo los participantes involucrados (`solicitante_id` o `propietario_id`) pueden cancelar una transacción.
     * La transacción debe encontrarse en estado `aceptada`.
   * **Consecuencia (Si se cumple):** La transacción pasa a `cancelada` y los productos implicados regresan del estado `reservado` a `disponible`. Se envía una notificación a la contraparte.
   * **Consecuencia si no se cumple:** Excepción SQL impidiendo la cancelación.

5. **Finalización de Transacciones**
   * **Entidades afectadas:** `transacciones`, `productos`
   * **Condiciones:**
     * Solo los participantes pueden marcarla como completada.
     * La transacción debe encontrarse en estado `aceptada`.
   * **Consecuencia (Si se cumple):** La transacción pasa a `completada` y los productos implicados cambian a `completado`, saliendo definitivamente del mercado.
   * **Consecuencia si no se cumple:** Se lanza una excepción.

6. **Restricción de Modificación de Estados en Productos**
   * **Entidades afectadas:** `productos`
   * **Condiciones:**
     * Desde el cliente (autenticado), la única transición de estado permitida manualmente es de `disponible` a `cancelado`.
   * **Consecuencia si no se cumple:** Un trigger bloquea cualquier intento del frontend de forzar manualmente los estados `reservado` o `completado` (que son exclusivos de la máquina de estados de las RPCs), lanzando una excepción.

7. **Privacidad de la Ubicación Exacta**
   * **Entidades afectadas:** `productos`, `transacciones`
   * **Condiciones:**
     * La `latitud_exacta` y `longitud_exacta` están protegidas. Para consultarlas mediante la RPC `obtener_ubicacion_exacta_producto`, el usuario debe ser el propietario del producto O participar en una transacción (`aceptada` o `completada`) que lo involucre.
   * **Consecuencia si no se cumple:** Se deniega el acceso a las coordenadas devolviendo un error de falta de disponibilidad.

8. **Restricciones de Mensajería**
   * **Entidades afectadas:** `mensajes`, `conversaciones`
   * **Condiciones:**
     * El remitente del mensaje debe formar parte de la `conversación`.
     * El contenido del mensaje no puede estar vacío (se valida longitud tras aplicar TRIM).
   * **Consecuencia si no se cumple:** La inserción del mensaje es rechazada por violación de política RLS o por restricción `CHECK`.

9. **Emisión de Valoraciones**
   * **Entidades afectadas:** `valoraciones`, `transacciones`, `perfiles`
   * **Condiciones:**
     * La transacción a valorar debe estar en estado `completada`.
     * El valorador debe ser uno de los participantes y no puede valorarse a sí mismo.
     * La puntuación debe ser un número entero entre 1 y 5.
     * Solo se puede emitir una única valoración por transacción y por valorador (Restricción UNIQUE).
   * **Consecuencia (Si se cumple):** Se inserta la valoración y un trigger asíncrono recalcula inmediatamente la puntuación media en el perfil del usuario valorado.
   * **Consecuencia si no se cumple:** La operación es bloqueada por PostgreSQL.

10. **Sincronización de Identidad**
    * **Entidades afectadas:** `auth.users`, `perfiles`
    * **Condiciones:**
      * Si un usuario cambia su correo electrónico desde el sistema de autenticación nativo de Supabase, debe reflejarse en su perfil público.
    * **Consecuencia:** Un trigger sobre la tabla interna `auth.users` propaga cualquier cambio de email directamente a la tabla `perfiles` de manera automática y transparente.

## 12. Flujos principales detallados

### 12.1. Registro y Creación de Perfil
*   **Actores implicados:** Usuario Anónimo, Sistema (Supabase Auth y Base de datos).
*   **Precondiciones:** El usuario no debe estar registrado con el email proporcionado.
*   **Pasos:**
    1.  El usuario introduce su email y contraseña o utiliza un proveedor OAuth (como Google/Apple).
    2.  El sistema (Supabase Auth) registra al usuario y le asigna un UUID en `auth.users`.
    3.  El sistema dispara el trigger interno `crear_perfil_usuario` al detectar la inserción en `auth.users`.
    4.  El trigger inserta automáticamente un registro en `public.perfiles` con el mismo UUID, el email y el nombre (extrayéndolo de los metadatos o generándolo a partir del email).
*   **Excepciones / Casos de error:**
    *   Si el email ya existe, Supabase Auth devuelve un error de validación.

### 12.2. Publicación de un Plato (Oferta)
*   **Actores implicados:** Usuario Autenticado (Propietario), Sistema.
*   **Precondiciones:** El usuario debe tener la sesión iniciada y permisos para crear productos.
*   **Pasos:**
    1.  El usuario rellena el formulario de nuevo plato: título, descripción, tipo (venta o intercambio), precio (si es venta), selecciona fotos y confirma su ubicación aproximada en un mapa.
    2.  El sistema (frontend) sube las imágenes a Supabase Storage en el bucket `imagenes-productos` dentro de la carpeta asignada a su UUID de usuario.
    3.  El sistema inserta el registro principal en la tabla `productos` con estado inicial `disponible`, separando la ubicación en `latitud_publica` y `longitud_publica` (para mostrar de forma segura en el feed general) y `latitud_exacta` / `longitud_exacta` (oculta).
    4.  El sistema inserta las referencias a las imágenes devueltas por Storage en la tabla `imagenes_producto` con sus URLs y orden posicional.
*   **Excepciones / Casos de error:**
    *   Si la oferta es de tipo `venta` y no tiene precio (o es negativo), la base de datos aborta la inserción mediante una restricción `CHECK`.
    *   Si los valores de enumeración (como `estado` o `tipo_oferta`) no coinciden con los listados en los constraints de PostgreSQL, se deniega la petición.
    *   Si la política de privacidad (RLS) falla (ej. intentar publicar alterando el `propietario_id` por el de otro usuario), la inserción es bloqueada.

### 12.3. Búsqueda por Proximidad (Feed y Mapa)
*   **Actores implicados:** Usuario Autenticado (Explorador), Sistema.
*   **Precondiciones:** El usuario debe estar autenticado y deben existir productos `disponibles` en la plataforma.
*   **Pasos:**
    1.  El usuario abre la aplicación y el sistema detecta sus coordenadas actuales a través del GPS del dispositivo, o utiliza su ubicación predeterminada configurada previamente en el perfil.
    2.  El usuario (opcionalmente) ajusta el radio de búsqueda en kilómetros (ej. 5km, 10km, 25km).
    3.  El sistema (frontend) invoca la RPC `obtener_productos_cercanos` pasándole la latitud y longitud de origen, el radio de búsqueda y un límite de paginación (por defecto 50).
    4.  La base de datos, utilizando las potentes extensiones espaciales `cube` y `earthdistance` sumadas a un índice geográfico de tipo GiST, filtra y ordena todos los productos en estado `disponible` rigurosamente por proximidad radial.
    5.  El sistema devuelve al frontend una lista de productos consolidada, inyectando la información de su propietario, el paquete de imágenes asociadas y calculando la distancia matemática exacta a la que se encuentran del explorador, todo ello sin llegar a revelar jamás las coordenadas exactas reales del creador del producto.
*   **Excepciones / Casos de error:**
    *   Si no se proporcionan coordenadas (permiso de ubicación de SO denegado por el usuario), la búsqueda espacial matemática no podrá completarse, debiendo la app inyectar coordenadas por defecto o aplicar un mecanismo de fallback al catálogo global sin orden geográfico.

### 12.4. Solicitud de Compra/Intercambio
*   **Actores implicados:** Solicitante, Propietario, Sistema.
*   **Precondiciones:** El producto deseado debe estar en estado `disponible`. En caso de intercambio, el solicitante debe poseer un producto en estado `disponible` para ofrecer.
*   **Pasos:**
    1.  El Solicitante selecciona la opción de solicitar compra o intercambio sobre un producto desde la interfaz.
    2.  En un intercambio, el usuario selecciona uno de sus productos disponibles como contraoferta. Se puede incluir un mensaje inicial opcional.
    3.  El sistema invoca la RPC `crear_solicitud_oferta`.
    4.  La base de datos valida las restricciones de negocio: verifica que ambos productos sigan disponibles, que el propietario no sea el solicitante y que no exista una solicitud previa en curso para el mismo producto por parte del mismo usuario.
    5.  Tras las verificaciones, la transacción SQL inserta los siguientes registros de forma atómica:
        *   Un registro en `solicitudes_oferta` con estado `pendiente`.
        *   Un registro en `conversaciones` vinculado a la solicitud y a los participantes.
        *   Un registro en `notificaciones` dirigido al propietario del producto solicitado.
*   **Excepciones / Casos de error:**
    *   Si un proceso concurrente reserva o elimina alguno de los productos requeridos, la RPC revierte la transacción SQL devolviendo un error indicando falta de disponibilidad.
    *   Si el sistema detecta una solicitud pendiente existente para la misma combinación de usuario y producto, la operación se bloquea mediante restricción única devolviendo un error controlado por duplicidad.

### 12.5. Aceptación y Cierre de Transacción
*   **Actores implicados:** Propietario, Solicitante, Sistema.
*   **Precondiciones:** Debe existir una solicitud en estado `pendiente`.
*   **Pasos:**
    1.  El Propietario evalúa las solicitudes entrantes para su producto en la interfaz y selecciona la opción "Aceptar" sobre una de ellas.
    2.  El sistema invoca la RPC `aceptar_solicitud_oferta`.
    3.  La RPC aplica un bloqueo transaccional (`FOR UPDATE`) sobre los registros de los productos involucrados para asegurar la exclusividad en la operación. El estado de estos productos se actualiza a `reservado`.
    4.  Se genera un registro en la tabla `transacciones` con estado `aceptada`.
    5.  La RPC actualiza el estado de todas las demás solicitudes `pendientes` relacionadas con los productos involucrados al estado `auto_denegada`, generando notificaciones para los usuarios afectados.
    6.  El Solicitante de la solicitud aceptada recibe una notificación confirmando la transacción.
    7.  Al estar la transacción `aceptada`, las políticas RLS habilitan a ambas partes para consultar la ubicación real del producto mediante la RPC `obtener_ubicacion_exacta_producto`.
    8.  Una vez materializado el acuerdo físico, cualquiera de los participantes selecciona la opción "Completar transacción" en el cliente.
    9.  El sistema ejecuta la RPC `completar_transaccion`, actualizando el estado de la transacción a `completada` y el de los productos a `completado`.
*   **Excepciones / Casos de error:**
    *   Si durante el proceso de aceptación los productos requeridos ya no se encuentran en estado `disponible` debido a operaciones concurrentes previas, la RPC aborta la operación indicando que el producto o el producto ofrecido no están disponibles.

### 12.6. Sistema de Valoraciones
*   **Actores implicados:** Valorador, Valorado, Sistema.
*   **Precondiciones:** Debe existir una transacción en estado `completada`.
*   **Pasos:**
    1.  El Valorador accede al detalle de la transacción completada y emite una puntuación (1 a 5 estrellas) sobre el otro usuario.
    2.  El cliente envía la petición de inserción a la tabla `valoraciones`.
    3.  Las políticas RLS de PostgreSQL evalúan que el Valorador sea partícipe de la transacción, que la transacción esté en estado `completada` y evitan que un usuario se valore a sí mismo (`valorador_id` != `valorado_id`).
    4.  Al confirmar la inserción de la valoración, se desencadena el trigger interno `recalcular_valoracion_perfil`.
    5.  El trigger consolida las valoraciones históricas del usuario Valorado, calcula la nueva puntuación promedio y actualiza los campos `valoracion_media` y `numero_valoraciones` correspondientes en la tabla `perfiles`.
*   **Excepciones / Casos de error:**
    *   Si el usuario intenta valorar una transacción que no ha concluido o no le pertenece, la política RLS bloquea la operación de inserción de forma silenciosa por motivos de seguridad.
    *   Si el usuario intenta emitir valoraciones múltiples sobre la misma transacción, la restricción `UNIQUE (transaccion_id, valorador_id)` bloquea la operación devolviendo un error estructural.

### 12.7. Chat en Tiempo Real y Marcado de Mensajes como Leídos
*   **Actores implicados:** Los dos participantes de la conversación, Sistema.
*   **Precondiciones:** Debe existir una `conversacion` cuyo `solicitante_id` o `propietario_id` coincida con el usuario autenticado.
*   **Pasos:**
    1.  Al entrar en el listado de chats, el cliente carga las conversaciones del usuario y, mediante un cómputo en el DTO, calcula los mensajes no leídos por conversación (filas con `leido_en IS NULL` y `remitente_id <> auth.uid()`).
    2.  Al abrir una conversación concreta, el cliente se suscribe vía Supabase Realtime al canal de la tabla `mensajes` filtrado por `conversacion_id`, recibiendo los mensajes nuevos en streaming.
    3.  El envío de un mensaje hace `INSERT` en `mensajes`; el trigger `actualizar_ultimo_mensaje_conversacion` actualiza `ultimo_mensaje_en` en la conversación, lo que reordena el listado de chats por actividad reciente.
    4.  Al renderizar los mensajes ajenos no leídos, el cliente lanza un `UPDATE` sobre `mensajes` poniendo `leido_en = now()`. La policy "Participantes pueden actualizar mensajes ajenos" autoriza la fila si el caller es participante de la conversación y *no* es el remitente; el `GRANT UPDATE (leido_en)` restringe el cambio exclusivamente a esa columna.
*   **Excepciones / Casos de error:**
    *   Si el caller intenta actualizar `contenido` o cualquier otra columna distinta de `leido_en`, PostgreSQL devuelve `permission denied` por falta de GRANT antes de evaluar la RLS.
    *   Si el caller intenta marcar como leídos sus propios mensajes o los de una conversación en la que no participa, la policy lo rechaza.

### 12.8. Centro de Notificaciones Realtime
*   **Actores implicados:** Usuario Autenticado, Sistema.
*   **Precondiciones:** El usuario debe estar autenticado.
*   **Pasos:**
    1.  Al iniciar sesión, el cliente abre una suscripción Supabase Realtime sobre `public.notificaciones` filtrada por `usuario_id = auth.uid()`.
    2.  Las RPCs transaccionales (`crear_solicitud_oferta`, `aceptar_solicitud_oferta`, `cancelar_transaccion`, etc.) insertan filas en `notificaciones` con un `tipo` y un `datos` JSONB que contiene los identificadores de las entidades relacionadas (`producto_id`, `solicitud_id`, `conversacion_id`).
    3.  Cada nueva inserción llega en streaming al cliente, que recalcula el contador de no leídas y lo pinta como badge dinámico en el AppBar (rediseñado como `ConsumerWidget`).
    4.  Al abrir el centro de notificaciones, el cliente lista las filas ordenadas por `creado_en DESC` y, al pulsar una notificación, decide la ruta destino según el `tipo` (chat, detalle de producto, panel de pedidos) leyendo los identificadores del campo `datos`.
    5.  Tras navegar, la notificación se marca como leída actualizando `leido_en = now()`, lo que retira el badge.
*   **Excepciones / Casos de error:**
    *   Si la suscripción Realtime se interrumpe (red caída), el cliente recompone el contador con un `SELECT` directo al recuperar conexión.
    *   Si el `tipo` o el contenido del campo `datos` son desconocidos para una versión antigua del cliente, la notificación se muestra pero el toque no enruta a ningún destino para evitar navegaciones erróneas.

### 12.9. Edición de Perfil y Subida de Avatar
*   **Actores implicados:** Usuario Autenticado, Sistema.
*   **Precondiciones:** El usuario debe estar autenticado.
*   **Pasos:**
    1.  El cliente carga el perfil completo del usuario invocando la RPC `obtener_mi_perfil` (necesaria porque los GRANT por columna sobre `perfiles` ocultan campos privados como `email` o las coordenadas predeterminadas).
    2.  El usuario edita los campos modificables (nombre, ciudad, preferencias, ubicación predeterminada, certificación sanitaria) y opcionalmente selecciona una imagen nueva de avatar.
    3.  Si hay imagen, el cliente la sube al bucket `avatares` dentro de la carpeta `<uuid_usuario>/`. Las policies de `storage.objects` permiten INSERT y UPDATE únicamente a esa carpeta, garantizando aislamiento entre usuarios. La URL pública resultante se asigna a `url_avatar`.
    4.  El cliente lanza un `UPDATE` sobre `public.perfiles` con los nuevos valores. La RLS de la tabla limita la actualización al propio `id = auth.uid()`.
*   **Excepciones / Casos de error:**
    *   Si el usuario intenta subir el avatar a una carpeta que no es la suya, la policy de Storage rechaza la operación.
    *   Si la actualización viola un `CHECK` (por ejemplo, valores fuera de rango en preferencias o coordenadas), la transacción se aborta y se muestra un error normalizado en la UI.