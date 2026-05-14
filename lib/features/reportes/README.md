# Reportes

Capa de datos para reportar productos, perfiles o mensajes. La UI de reportes está pendiente; el backend ya soporta la inserción.

## Capas

- `domain/repositories/reporte_repository.dart` — contrato de creación de reporte.
- `data/repositories/supabase_reporte_repository.dart` — implementación contra Supabase.
- `providers/reporte_repository_provider.dart` — inyección Riverpod.

## Backend

- Tabla `reportes` polimórfica: `tipo_objetivo in ('producto', 'perfil', 'mensaje')` + `objetivo_id uuid`. Sin FK dura (limitación documentada en §9 de la documentación técnica).
- Estados de tramitación: `abierta`, `en_revision`, `resuelta`, `descartada` (gestionados por moderación, no por el usuario).
