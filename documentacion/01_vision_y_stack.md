# 01 — Visión y Stack tecnológico

> Anterior: —  |  Siguiente: [`02_arquitectura_y_carpetas.md`](./02_arquitectura_y_carpetas.md)

---

## ¿Qué es YumYum?

Plataforma de **intercambio local de comida casera**. Los usuarios publican platos (venta o intercambio), los descubren por proximidad GPS, negocian por chat en tiempo real y cierran el trato. La ubicación exacta solo se revela cuando hay una transacción aceptada.

---

## Stack

### Frontend — Flutter (SDK ≥3.3.0)

| Librería | Para qué sirve |
|----------|---------------|
| `flutter_riverpod ^3.3.1` | Estado reactivo e inyección de dependencias |
| `go_router ^14` | Navegación declarativa, redirecciones de auth |
| `flutter_map ^6` + `latlong2` | Mapas open-source (OpenStreetMap, sin SDK comercial) |
| `supabase_flutter ^2.12` | Auth, REST, Realtime y Storage en una dependencia |
| `geolocator ^12` | Coordenadas GPS y permisos |
| `image_picker ^1.1` | Galería/cámara para imágenes |
| `cached_network_image ^3.3` | Caché de imágenes del feed |
| `google_fonts ^6.2` | Tipografías Inter y Fraunces |
| `shared_preferences ^2.3` | Persistencia local del tema activo |
| `intl ^0.19` | Fechas, distancias y monedas en `es` |
| `http ^1.2` | Cliente del asistente IA (backend Node externo) |

### Backend — Supabase

| Servicio | Uso en YumYum |
|----------|--------------|
| PostgreSQL | BD relacional con CHECKs, triggers e índices espaciales |
| GoTrue (Auth) | Autenticación PKCE, recuperación de contraseña |
| RLS | Seguridad a nivel de fila y columna |
| Storage | Imágenes de productos y avatares |
| Realtime | WebSockets para chat, notificaciones y favoritos |
| RPCs (PL/pgSQL) | Operaciones atómicas complejas |

> ⚠️ **Servicio externo:** El asistente IA usa un backend Node en `localhost:3000` que **no está en este repositorio**. Si no está levantado, el FAB de IA da error de red sin afectar el resto de la app.

---

## Arquitectura en una imagen

```
Flutter App (iOS / Android / Web PWA)
        │ supabase_flutter
        ▼
Supabase ─── Auth ─── PostgreSQL (RLS + Triggers + RPCs)
         └── Storage
         └── Realtime (WebSockets)
        │ (solo IA)
        ▼
Backend Node externo (localhost:3000) ← no está en el repo
```
