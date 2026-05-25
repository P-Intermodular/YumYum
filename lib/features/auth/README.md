# Auth

Registro, inicio de sesión y recuperación de contraseña. Usa Supabase Auth con flujo PKCE.

## Pantallas

- `inicio_sesion_screen.dart` — login con email + password.
- `registro_screen.dart` — alta de usuario con aceptación de términos/RGPD; tras registrarse crea fila en `perfiles` automáticamente vía trigger.
- `recuperar_password_screen.dart` — solicita un email de recuperación a Supabase.
- `restablecer_password_screen.dart` — pantalla destino del enlace del email; consume el token PKCE y permite elegir nueva contraseña.

## Controllers

- `auth_controller.dart` — fuente única de verdad del usuario autenticado (`AsyncValue<UsuarioModel?>`). Inicia sesión, registra, cierra sesión y se suscribe a `onAuthStateChange`.
- `restablecer_password_controller.dart` — gestiona el intercambio de código PKCE y la actualización de password.

## Capas

- `data/dtos/usuario_dto.dart` y `data/repositories/supabase_auth_repository.dart` encapsulan llamadas a Auth y a `perfiles`.
- `domain/entities/usuario_model.dart` y `domain/repositories/auth_repository.dart` definen el contrato.

## Backend

- `auth.users` (Supabase Auth) + `public.perfiles` (datos públicos del usuario).
- RPC `obtener_mi_perfil()` para leer campos privados del usuario propio.
- `detectSessionInUri: false` y manejo manual del enlace de recovery desde el router (ver `lib/core/router/app_router.dart`).
