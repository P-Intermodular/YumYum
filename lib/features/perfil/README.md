# Perfil

Gestión del perfil propio (edición, avatar, ubicación) y visualización de perfiles ajenos.

## Pantallas

- `perfil_screen.dart` — perfil propio: cabecera con avatar, valoración media, número de valoraciones, alérgenos personales y atajos a "Guardados", productos publicados y ajustes.
- `perfil_publico_screen.dart` — perfil de otro usuario: muestra solo campos públicos + métricas agregadas (`pedidos_completados`).
- `editar_perfil_screen.dart` — formulario de edición (nombre, bio, alérgenos, avatar).
- `editar_ubicacion_perfil_screen.dart` — selector de ubicación predeterminada del usuario (usado para el radio de feed).

## Controllers

- `editar_perfil_controller.dart` — guardado del formulario y subida del avatar al bucket `avatares`.

## Widgets

- `cabecera_perfil.dart`, `insignia_valoracion.dart` — composición visual.

## Backend

- Tabla `perfiles` con privacidad por GRANTs columnares: `email`, `preferencias`, `certificacion_sanitaria`, `latitud_predeterminada`, etc. nunca llegan a perfiles ajenos.
- RPC `obtener_mi_perfil()` para campos privados del usuario propio.
- RPC `obtener_perfil_publico(p_perfil_id)` para el perfil ajeno + métricas agregadas.
- Bucket Storage `avatares` (público; la SELECT vía API queda restringida al dueño de la carpeta).
