# SIRE — Estado de integración API (capa Flutter)

Snapshot del estado actual de la integración entre Flutter y los servicios externos (backend REST + Supabase). Indico qué está implementado, qué se está mockeando ahorita, y qué necesito que el backend provea para reemplazar el mock por la integración real.

El objetivo de este doc es que puedas priorizar las entregas sabiendo exactamente dónde encaja cada endpoint en la app para hacer las integraciones reales.

---

## Convenciones de redacción

- ✅ **Activo** — Consumo implementación real.
- 🟡 **Mock activo** — Uso mock por defecto. La impl real ya está escrita y probada con `flutter analyze` (significa que no hay errores en codebase). Activarla solo requeriría swap del provider cuando el endpoint esté listoco.
- 🔧 **Bloqueado por Backend** — esperando integración externa (env var, bucket, endpoint) para poder funcionar.
- ❌ **No implementado** — pendiente de un sprint futuro.

---

## Bootstrap — qué necesita del backend para que la app arranque

| Recurso | Estado | Para qué lo uso |
|---|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` en `.env` | ✅ | `Supabase.initialize()` en `main.dart`. |
| `API_BASE_URL` en `.env` | 🔧 | `ApiConstants.baseUrl` lo lee con `dotenv`. Sin esto, los `*RemoteDatasourceImpl` apuntan a string vacío. La app igual arranca porque está mockeado. |
| `GOOGLE_GEOCODING_KEY` en `.env` | 🔧 *opcional* | El paquete `geocoding` usa el servicio nativo del dispositivo por defecto XD. La api de geocoding de google solo se necesita si más adelante usamos fallback de Google (para Windows x ej), pero ahora mismo no la estaríamos necesitando (pq estamos en mobile-first). |
| Bucket Supabase Storage `avatars` con política `SELECT public` | 🔧 | `AvatarStorageDatasourceImpl.uploadAvatar` (Sprint 1). Sin esto la Emilia no puede testear edición de avatar en UI. |
| Bucket Supabase Storage `publications` con política `SELECT public` | 🔧 | `PublicationImageDatasourceImpl.uploadImage` (Sprint 2). Sin esto la creación de publicación con imagen falla (lo mismo que el otro, sólo necesito que configures los buckets de ambos en storage). |

---

## Sprint 1 — Auth + Users

### Supabase Auth (SDK directo, sin backend)

Lo que Flutter maneja contra Supabase Auth sin pasar por el backend:

| Operación | Estado |
|---|---|
| `signInWithPassword(email, password)` | ✅ |
| `signInWithOtp(email)` (magic link) | ✅ |
| `updateUser({ password })` (GUEST → ACTIVE en Auth) | ✅ |
| `signOut()` | ✅ |
| `resend(type: signup)` (verificación de correo) | ✅ |
| `authStateChanges()` stream | ✅ |

Estos no requieren nada del backend porque el dominio conecta directo con supa cómo habíamos planeado.

### Backend REST (lo que si necesito del backend)

| Endpoint | Estado | Implementación esperada |
|---|---|---|
| `POST /auth/register-guest` | 🟡 | EL mock de ahora retorna `{userId: 'mock-user-id-123', accountStatus: 'guest', userCreated: true, token: 'mock-token-123'}`. Backend: crear usuario en Supabase Auth + perfil en `profiles` en una transacción. |
| `PATCH /auth/account-status` | 🟡 | Mock no-op (200 vacío). Backend: actualizar `accountStatus = 'ACTIVE'` en `profiles` directamente vía Prisma. **No usar trigger Supabase** (lo que dijimos antes). |
| `GET /users/me` | 🟡 | Mock retorna usuario demo (`demo@sire.cl`, GUEST). Backend: leer `profiles` por JWT. |
| `PUT /users/me` | 🟡 | Mock retorna entidad merged. Backend: actualizar campos opcionales (`name`, `phone`, `avatarUrl`); NO sobreescribir con null si el campo viene ausente del body. |

## Sprint 2 — Feed + Publications

### Geolocalización (Flutter, sin backend)

| Operación | Estado | Notas |
|---|---|---|
| `Geolocator.checkPermission` + `requestPermission` | ✅ | Manejo defensivo de denegación |
| `Geolocator.getCurrentPosition` con `LocationSettings` | ✅ | Usa `LocationAccuracy.low` con timeout 10s |
| `placemarkFromCoordinates` (geocoding) | ✅ | Servicio nativo del dispositivo |
| Cache de región en `LocalStorageService(StorageKeys.region)` | ✅ | Para no volver a pedir GPS en sesiones siguientes |

**Pendiente de Emilia:** agregar permisos a manifests:

- Android: `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` en `AndroidManifest.xml`
- iOS: `NSLocationWhenInUseUsageDescription` en `Info.plist` con texto explicativo
- Investigar si se requiere algo más que sólo editar los manifests, si algo cambió en las últimas versiones y sobre la retrocompatibilidad.

### Backend REST

| Endpoint | Estado | Notas |
|---|---|---|
| `GET /feed` | 🟡 | Mock con 5 publicaciones seeded en Región de La Araucanía con categorías mixtas |
| `GET /publications/:id` | 🟡 | Mock con 3 publicaciones (incluye `availability` completo con `dayOverrides`) |
| `GET /publications/mine` | 🟡 | Mock retorna 2 entradas del usuario demo (`mock-user-id-123`) |
| `POST /publications` | 🟡 | Mock retorna entidad creada. **Patrón especial:** el front asume que la respuesta puede ser sparse (`{id, title, isActive, createdAt}` según el contrato actual) y compensa con un `GET /publications/:id` adicional inmediato para obtener la entidad completa con `availability`. Si decides retornar la entidad completa en el 201, ese GET extra se vuelve redundante (no causa errores, solo es ineficiente), así que necesito la definición de cómo lo implementaste para optimizarlo. |
| `PUT /publications/:id` | 🟡 | Mismo patrón sparse + GET adicional |
| `PATCH /publications/:id/status` | 🟡 | Mock no-op |
| `DELETE /publications/:id` | 🟡 | Mock no-op |

### Categorías (enum congelado)

`DEPORTE | EVENTOS | RECREACION | OTROS` (decidido antes — Zod en backend rechaza otros valores).

Front mapea uppercase API ↔ lowercase enum Dart vía `publicationCategoryFromString` / `publicationCategoryToString` en `publication_detail_model.dart`. Si amplías el enum luego (ej: agregar `SALUD` cómo nueva categoría), me actualizas el contrato (`api-contract`) y agrego el case en el helper jojojo.

### Storage

| Operación | Estado |
|---|---|
| Upload imagen al bucket `publications` (extensión + UUID v4) | 🔧 *esperando bucket* |

---

## Resumen ejecutivo (lo que destraba más)

**Si entregas lo del backend antes del miercoles o durante esta semana, en orden de impacto:**

1. **`.env` con `API_BASE_URL`** — destraba los endpoints de sprint 1 y 2. Ahora mismo la app arranca y supabase está conectado, pero los `*RemoteDatasourceImpl` no apuntan a un host real para las peticiones.
2. **Buckets Supabase `avatars` + `publications` con política pública** — destraba toda la subida de imágenes (avatar de Sprint 1, imagen de publicación de Sprint 2).
3. **Endpoints Sprint 1 (4)** — al estar listos puedo dar de baja `AuthRemoteDatasourceMockImpl` e implementar la autenticación real.
4. **Endpoints Sprint 2 (7)** — al estar listos puedo dar de baja `FeedRemoteDatasourceMockImpl` y `PublicationsRemoteDatasourceMockImpl` e implementar el repo de publicaciones real para feed y vista de publicaciones.

**Total endpoints implementados a la espera de backend:** 11 (4 Sprint 1 + 7 Sprint 2). Los 7 endpoints faltantes (Sprint 3 + Sprint 4) los implementaré conforme avancemos porque ésta presentación sólo requiere el 30% de cobertura de data treat y con todo lo que está ya en Flutter tenemos ~50% de cobertura de RF y RNF.

---

---

## Actualización Backend (Cristian)

Se levantó la arquitectura base con Fastify + Prisma ORM + Supabase PostgreSQL.

| Recurso / Tarea | Estado | Notas del Backend |
|---|---|---|
| `API_BASE_URL` | ✅ | Servidor escuchando en red local. En tu `.env` de Flutter pon: `API_BASE_URL=http://192.168.1.17:3000/api/v1` |
| Conexión a Base de Datos | ✅ | Migraciones exitosas (`init-tablas-core`). Tablas físicas de `profiles`, `publications` y `reservations` ya existen en Supabase. |
| Endpoint base de perfiles | ✅ | `GET /users/profiles` está operativo y trayendo datos reales (actualmente retorna `[]` porque la BD está limpia). |
| Enum Categorías | ✅ | Congelado a nivel de BD en Prisma (`DEPORTE`, `EVENTOS`, `RECREACION`, `OTROS`). |

---

## Publicaciones

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | /api/v1/publications | ✅ Listo | Público (Feed). Soporta filtro opcional por `region` via query param |
| GET | /api/v1/publications/mine | ✅ Listo | Privado. Requiere pasar el ID de usuario en los headers |
| POST | /api/v1/publications | ✅ Listo | Validación de categorías. Requiere estrictamente cuenta ACTIVE |
| GET | /api/v1/publications/:id | ⏳ Pendiente | |
| PUT | /api/v1/publications/:id | ⏳ Pendiente |  |
| DELETE | /api/v1/publications/:id | ⏳ Pendiente |  |

---

## Autenticación

*Nota: Login y Logout son manejados directamente en Flutter vía Supabase Auth. El backend solo sincroniza perfiles.*

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| POST | /api/v1/auth/register-guest | ✅ Listo | Recibe ID de Supabase y crea perfil en estado `guest` |
| PATCH | /api/v1/auth/account-status | ✅ Listo | Pasa el estado de la cuenta a `active` |
| GET | /api/v1/auth/me | ✅ Listo | Devuelve los datos del perfil actual |