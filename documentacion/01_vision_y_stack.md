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
| `uuid ^4.3` | Generación de IDs locales (nombres de blob en Storage) |
| `web ^1.0` | Acceso al DOM en web para sincronizar `meta theme-color` de la PWA |

### Backend — Supabase

| Servicio | Uso en YumYum |
|----------|--------------|
| PostgreSQL | BD relacional con CHECKs, triggers e índices espaciales |
| GoTrue (Auth) | Autenticación PKCE, recuperación de contraseña |
| RLS | Seguridad a nivel de fila y columna |
| Storage | Imágenes de productos y avatares |
| Realtime | WebSockets para chat, notificaciones y favoritos |
| RPCs (PL/pgSQL) | Operaciones atómicas complejas |
| **Edge Functions** (Deno + TypeScript) | Asistente IA: integración con Google Gemini sin exponer la API key al cliente |

### Asistente IA — Edge Function + Google Gemini

El FAB de IA invoca la Edge Function `asistente-ia` alojada en Supabase (Deno + TypeScript). La función:
- Habla con **Google Gemini** usando *function calling* para buscar productos reales en la BD.
- La `GEMINI_API_KEY` vive como **secret de Supabase** — nunca llega al cliente.
- Aplica fallback automático en cascada entre seis modelos de Gemini si alguno falla.
- **No requiere ningún servidor externo** ni proceso adicional en local.

---

## Arquitectura en una imagen

```
Flutter App (iOS / Android / Web PWA)
        │ supabase_flutter
        ▼
Supabase ─── Auth ─── PostgreSQL (RLS + Triggers + RPCs)
         ├── Storage
         ├── Realtime (WebSockets)
         └── Edge Functions (Deno) ──► Google Gemini API
```
