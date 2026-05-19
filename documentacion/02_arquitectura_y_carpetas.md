# 02 — Arquitectura y estructura de carpetas

> Anterior: [`01_vision_y_stack.md`](./01_vision_y_stack.md)  |  Siguiente: [`03_base_de_datos.md`](./03_base_de_datos.md)

---

## Organización: Feature-First

El código **no** se organiza por tipo (`models/`, `screens/`…) sino por **funcionalidad de negocio**. Todo lo relacionado con productos vive en `lib/features/producto/`; lo que comparten varias features va en `lib/core/`.

---

## Mapa de carpetas

```
YumYum/
├── lib/
│   ├── main.dart
│   ├── core/                  # Código compartido entre features
│   │   ├── constants/         # Rutas, nombres de tablas/RPCs/buckets, estados, categorías, alérgenos
│   │   ├── router/            # GoRouter: rutas, redirecciones, ShellRoute
│   │   ├── supabase/          # Config e inyección del cliente Supabase
│   │   ├── theme/             # Material3, colores, persistencia, sync PWA
│   │   ├── preferencias/      # SharedPreferences + consentimiento cookies (RGPD)
│   │   ├── widgets/           # Widgets reutilizables globales
│   │   ├── services/          # IAService (cliente HTTP del asistente IA)
│   │   ├── location/          # GPS, permisos, formato de distancia
│   │   ├── errors/            # Excepciones y traducción de errores técnicos → mensajes UI
│   │   ├── feedback/          # Snackbars de éxito/error normalizados
│   │   ├── format/            # Formateadores (ej. "hace 5 min")
│   │   └── providers_refresher.dart  # Invalida providers relacionados tras acciones compartidas
│   │
│   └── features/
│       ├── auth/              # Login, registro, recuperación de contraseña
│       ├── principal/         # Shell con BottomNav (área privada)
│       ├── inicio/            # Feed principal con filtros
│       ├── mapa/              # Vista geográfica de productos
│       ├── producto/          # Publicación, edición, eliminación, detalle
│       ├── favoritos/         # Guardados con stream Realtime
│       ├── solicitudes/       # Solicitudes de compra/intercambio
│       ├── pedidos/           # Panel de transacciones
│       ├── chat/              # Chat en tiempo real
│       ├── notificaciones/    # Centro de notificaciones + badge
│       ├── perfil/            # Perfil propio, edición y perfil público ajeno
│       ├── ajustes/           # Cuenta, tema, preferencias de notificaciones
│       ├── valoraciones/      # Emisión de valoraciones
│       ├── reportes/          # Moderación (solo repositorio, sin pantallas)
│       └── legal/             # 6 páginas legales públicas (RGPD)
│
├── supabase/
│   └── migrations/            # Fuente de verdad del esquema, RLS, triggers y RPCs
├── test/                      # Tests de core, features y migraciones SQL
├── scripts/                   # Scripts de build y desarrollo local
└── web/                       # index.html, manifest, iconos PWA
```

---

## Estructura interna de una feature

```
feature/
├── controllers/    # AsyncNotifier/Notifier: orquestan acciones desde la UI
├── data/
│   ├── dtos/       # Convierten Map<String,dynamic> de Supabase → modelo de dominio
│   └── repositories/ # Implementaciones concretas contra Supabase
├── domain/
│   ├── entities/   # Modelos puros de Dart (sin dependencias de Supabase ni Flutter)
│   └── repositories/ # Interfaces: definen qué se puede hacer, no cómo
├── providers/      # Riverpod providers que inyectan repositorios y cachean estado
├── screens/        # Pantallas completas. Solo pintan UI y reaccionan al estado
└── widgets/        # Componentes visuales privados de la feature
```

> Si un widget se reutiliza en más de 2 features → muévelo a `core/widgets/`.

---

## Flujo de datos

```
Screen/Widget
  → Controller (valida, llama al repositorio, actualiza AsyncValue)
  → SupabaseRepository (queries, RPCs, Storage)
  → DTO (Map → Modelo de dominio)
  → Provider actualiza AsyncValue
  → UI se reconstruye
```

---

## Rutas

Definidas en dos archivos:
- `core/constants/rutas_app.dart` — cadenas de ruta y helpers con parámetros.
- `core/router/app_router.dart` — registro de pantallas, redirecciones y auth guards.

| Tipo | Rutas |
|------|-------|
| **Públicas** | `/iniciar-sesion`, `/registro`, `/recuperar-password`, `/restablecer-password`, `/legal`, `/privacidad`, `/terminos`, `/cookies`, `/reclamaciones`, `/odr` |
| **Shell privado** (BottomNav) | `/inicio`, `/mapa`, `/publicar`, `/pedidos`, `/chats`, `/perfil`, `/notificaciones`, `/guardados`, `/ajustes` |
| **Full-screen privadas** | `/producto/:id`, `/editar-plato/:id`, `/usuario/:id`, `/chat/:id`, `/transaccion/:id`, `/pedido/solicitud/:id`, `/valorar/:id` |
| **Aliases inglés** | `/login`, `/signup`, `/feed`, `/map`, `/product/:id`… (redirigen a sus equivalentes) |

**Para añadir una pantalla:** crear en `screens/` → constante en `rutas_app.dart` → `GoRoute` en `app_router.dart` → actualizar `PrincipalScreen` si va en el BottomNav.

---

## Reglas de contribución

| ❌ No hagas | ✅ Haz |
|------------|--------|
| Lógica de negocio en widgets | Delega en controllers/providers |
| Strings de tablas/RPCs/buckets a mano | Usa `supabase_names.dart` |
| Llamar a Supabase directamente desde una pantalla | Pasa por repositorios |
| Usar el Map de respuesta de Supabase en la UI | Convierte a modelo con un DTO |
| Modificar `build/`, `.dart_tool/`, logs generados | Son archivos de herramienta |

---

## `lib/main.dart` — qué hace al arrancar

1. `WidgetsFlutterBinding.ensureInitialized()`
2. URLs limpias en web (`usePathUrlStrategy`)
3. Locale `'es'` para formateo de fechas
4. Valida `SUPABASE_URL` y `SUPABASE_ANON_KEY` — si faltan, arranca app de error informativo
5. Inicializa Supabase con PKCE y `detectSessionInUri: false` (el router gestiona URLs de recovery)
6. Carga `SharedPreferences` **antes** de `runApp` → el tema se inicializa síncronamente sin "flash"
7. Arranca en `ProviderScope` con `SharedPreferences` inyectado
