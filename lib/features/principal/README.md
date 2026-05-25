# Principal

Shell de navegación principal de la app autenticada.

## Pantallas

- `principal_screen.dart` — `Scaffold` con `extendBody: true` que envuelve a las cinco pestañas del bottom nav (Inicio, Mapa, Publicar, Pedidos, Chats). Usa `go_router` con `ShellRoute` para mantener el bottom nav fijo mientras cambia la sub-ruta.

## Notas

- La pestaña "Publicar" no es una pestaña real: enruta a `/publicar` que vuelve a salir del shell.
- La pestaña "Perfil" ya no existe en el bottom nav (se accede desde el avatar del header de inicio); por eso `_calculateSelectedTab` no resalta nada cuando la ruta empieza por `/perfil`.
