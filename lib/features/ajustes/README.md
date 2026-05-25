# Ajustes

Hub de gestión de cuenta y preferencias del usuario autenticado.

## Pantallas

- `ajustes_screen.dart` — header de cuenta + tiles agrupados (Cuenta, Apariencia, Legal) + cierre de sesión y versión de app.
- `preferencias_notificaciones_screen.dart` — alterna las categorías de notificaciones que el usuario desea recibir.

## Widgets

- `ajustes_grupo.dart`, `ajustes_tile.dart` — composición visual de las secciones.
- `selector_tema_bottom_sheet.dart` — bottom sheet de elección de tema (Huerto Moderno / Mesa de Barrio).

## Backend

- Lee/escribe `perfiles.preferencias_notificaciones` vía PostgREST.
- El cambio de contraseña usa el flujo de email de recuperación de Supabase Auth (no se cambia desde la app).
- El tema visual se persiste con `SharedPreferences` y se aplica de forma síncrona en el arranque (ver `lib/core/theme/`).
