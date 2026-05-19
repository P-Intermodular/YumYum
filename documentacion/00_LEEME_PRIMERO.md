# 📚 Documentación YumYum — Índice

YumYum es una app móvil/web para intercambiar comida casera entre vecinos por proximidad geográfica. El stack es **Flutter + Supabase**.

---

## Orden de lectura recomendado

| # | Documento | Qué aprenderás |
|---|-----------|---------------|
| 1 | [`01_vision_y_stack.md`](./01_vision_y_stack.md) | Qué hace la app y con qué tecnologías |
| 2 | [`02_arquitectura_y_carpetas.md`](./02_arquitectura_y_carpetas.md) | Cómo está organizado el código |
| 3 | [`03_base_de_datos.md`](./03_base_de_datos.md) | Tablas, relaciones y decisiones de BD |
| 4 | [`04_api_y_backend.md`](./04_api_y_backend.md) | RPCs, triggers y Storage |
| 5 | [`05_flujos_de_negocio.md`](./05_flujos_de_negocio.md) | Los flujos principales paso a paso |
| 6 | [`06_reglas_de_negocio.md`](./06_reglas_de_negocio.md) | Validaciones y restricciones de la BD |
| 7 | [`07_estado_y_deuda_tecnica.md`](./07_estado_y_deuda_tecnica.md) | Qué hay hecho y qué problemas conocidos existen |

---

## Antes de empezar — conceptos clave

- **Riverpod** — gestión de estado. Aprende `AsyncValue`, `Provider`, `Notifier`.
- **GoRouter** — navegación declarativa. Rutas y redirecciones centralizadas en `core/router/`.
- **RLS** — políticas de PostgreSQL que controlan qué filas puede ver/editar cada usuario.
- **RPC** — funciones PL/pgSQL que garantizan atomicidad en operaciones complejas.
- **Nunca** escribas nombres de tablas/RPCs/buckets como strings. Usa `core/constants/supabase_names.dart`.
