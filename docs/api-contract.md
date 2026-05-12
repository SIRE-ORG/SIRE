# SIRE — Contrato de API

*Documento vivo. Las decisiones de arquitectura externa están consolidadas; cambios menores en payloads se actualizan inline al ocurrir.*

---

## Decisiones de arquitectura definidas

Resueltas tras revisión con Cristian (2026-05-10):

- **`slotId`:** identificador determinista construido por el backend como `publicationId + date + startTime`. Flutter lo recibe en `GET /publications/:id/slots` y lo reenvía tal cual en `POST /reservations`.
- **`PublicationCategory`:** enum cerrado validado por Zod en el backend. Valores: `DEPORTE`, `EVENTOS`, `RECREACION`, `OTROS`. Cualquier otro string en `category` retorna `VALIDATION_ERROR`. Si se amplía el enum, Cristian actualiza este documento y notifica al equipo.
- **`PATCH /auth/account-status`:** el backend actualiza `accountStatus = 'ACTIVE'` en la tabla `profiles` directamente vía Prisma, en respuesta al request de Flutter después de `supabase.auth.updateUser({ password })`. No hay trigger en Supabase Auth — el control de la transición vive en el código del backend.
- **Contacto publicador → solicitante:** dividido en dos canales con manejo distinto. Email vía `POST /reservations/:id/contact` (fire-and-forget, dispara Resend, no persiste en BD). WhatsApp se construye **localmente en Flutter** usando `requester.phone` que viene en el detalle de la reserva — no requiere endpoint.

---

## Arquitectura de comunicación

SIRE usa una arquitectura híbrida. Flutter no habla exclusivamente con el backend — consume Supabase directamente para lo que el SDK maneja de forma nativa, y usa el backend REST solo para la lógica de negocio que requiere validación, transacciones o comunicación externa.

```
Flutter
  ├── Supabase SDK      → Auth (login, magic link, JWT, updateUser)
  │                     → Realtime (suscripciones en tiempo real)
  │                     → Storage (subida de imágenes)
  └── Backend REST      → Lógica de negocio (reservas, publicaciones, slots)
                        → Validación de permisos
                        → Comunicación externa (Resend, wa.me)
                        → Escritura en BD via Prisma

Backend
  └── Supabase          → Base de datos via Prisma
                        → Verifica JWT de los requests entrantes
```

---

## Convenciones generales

- Base URL backend: `https://[dominio-render]/api/v1`
- Todos los requests y responses usan `Content-Type: application/json`
- Los endpoints protegidos requieren header `Authorization: Bearer <jwt_token>` — el JWT lo emite Supabase Auth y el backend lo verifica
- Los IDs son UUIDs v4 generados por Supabase
- Las fechas siguen el formato ISO 8601: `"2025-04-07T10:00:00Z"`
- Los horarios de slots usan formato `"HH:MM"`: `"09:00"`, `"10:30"`


---

### Tipado de Datos: Categorías (Enum)
Para garantizar la integridad de los filtros en el feed, la categoría de una publicación (`category`) no es texto libre. Debe ser estrictamente uno de los siguientes valores:
- `DEPORTE` (Canchas de fútbol, tenis, basketball, etc.)
- `EVENTOS` (Quinchos, salones, espacios para cumpleaños)
- `RECREACION` (Bares, mesas de pool, juegos)
- `OTROS` (Cualquier espacio que no encaje en los anteriores)

*Nota para Flutter: Enviar cualquier valor fuera de este Enum en el POST/PUT de publicaciones retornará un error 400 VALIDATION_ERROR.*

---

## Formato de errores

Todos los errores del backend siguen esta estructura:

```json
{
  "error": {
    "code": "SLOT_NOT_AVAILABLE",
    "message": "El slot seleccionado ya no está disponible"
  }
}
```

### Códigos de error y sus casos de uso

| Código | HTTP | Cuándo ocurre | Cómo lo maneja Flutter |
|---|---|---|---|
| `AUTH_EMAIL_ALREADY_EXISTS` | 409 | Formulario de reserva con correo que ya tiene cuenta ACTIVE | Redirige al login con mensaje explicativo |
| `AUTH_UNAUTHORIZED` | 401 | Request a endpoint protegido con token inválido o expirado | Interceptado globalmente — Supabase SDK refresca el token automáticamente antes de reintentar |
| `SLOT_NOT_AVAILABLE` | 409 | Dos usuarios intentan reservar el mismo slot simultáneamente; el segundo en llegar recibe este error | Recarga los slots disponibles y muestra aviso |
| `SLOT_NOT_FOUND` | 404 | El slotId no corresponde a la publicación y fecha; ocurre si la agenda fue modificada mientras el usuario tenía la pantalla abierta | Vuelve al calendario y recarga disponibilidad |
| `PUBLICATION_NOT_FOUND` | 404 | La publicación fue eliminada o pausada mientras el usuario navegaba hacia ella | Vuelve al feed con aviso de no disponibilidad |
| `RESERVATION_NOT_FOUND` | 404 | ID de reserva inexistente o de otro usuario | Vuelve a "Mis reservas" |
| `RESERVATION_CANNOT_CANCEL` | 422 | Intento de cancelar una reserva que no está en estado `pending` | El botón de cancelar se deshabilita en el frontend si el estado no es `pending`; este código es red de seguridad |
| `RESERVATION_CANNOT_UPDATE` | 422 | Transición de estado inválida (ej: completar una reserva ya rechazada) | Recarga el estado actual de la reserva |
| `FORBIDDEN` | 403 | Usuario intenta operar sobre un recurso que no le pertenece | Muestra error genérico, recarga el recurso |
| `VALIDATION_ERROR` | 400 | Campos faltantes, tipos incorrectos o valores fuera de rango en el body | Muestra errores de validación inline en el formulario |

---

## Supabase SDK — lo que Flutter maneja directamente

Estos flujos no pasan por el backend. Flutter los ejecuta directamente contra Supabase Auth y Supabase Storage.

### Autenticación via SDK

```dart
// Login con correo y contraseña
await supabase.auth.signInWithPassword(email: email, password: password);

// Magic link (fallback para GUEST sin sesión)
await supabase.auth.signInWithOtp(email: email);

// Establecer contraseña desde sesión activa (GUEST → ACTIVE en Supabase Auth)
await supabase.auth.updateUser(UserAttributes(password: password));

// Reenviar correo de verificación
await supabase.auth.resend(type: OtpType.signup, email: email);

// Datos del usuario autenticado (sin necesidad de endpoint)
final user = supabase.auth.currentUser;

// Cerrar sesión
await supabase.auth.signOut();
```

**Refresh del JWT:** Supabase Auth lo maneja automáticamente. El SDK renueva el token antes de que expire sin que Flutter tenga que hacer nada. El backend verifica el JWT en cada request pero no gestiona el refresh.

### Storage via SDK

```dart
// Subir imagen de publicación
await supabase.storage.from('publications').upload(path, file);

// Subir avatar de usuario
await supabase.storage.from('avatars').upload(path, file);

// Obtener URL pública
final url = supabase.storage.from('publications').getPublicUrl(path);
```

### Realtime via SDK

```dart
// Suscripción a nuevas reservas recibidas (publicador)
supabase.from('reservations')
  .stream(primaryKey: ['id'])
  .eq('publication_owner_id', userId)
  .listen((data) { ... });

// Suscripción a cambios de estado (solicitante)
supabase.from('reservations')
  .stream(primaryKey: ['id'])
  .eq('requester_id', userId)
  .listen((data) { ... });

// Suscripción a notificaciones nuevas
supabase.from('notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .listen((data) { ... });
```

---

## Módulo: Autenticación (backend)

### Descripción

El backend maneja únicamente lo que Supabase Auth no puede hacer por sí solo: crear el perfil extendido del usuario (nombre, teléfono, estado de cuenta) en la tabla `profiles` de la base de datos, y actualizar el `accountStatus` cuando el usuario GUEST establece su contraseña **automáticamente en la base de datos vía un Trigger**.

El login, magic link, refresh de JWT, verificación de correo y logout son responsabilidad exclusiva del SDK de Supabase en el cliente Flutter.

### Flujos principales

- **Registro implícito:** Flutter llama a `POST /auth/register-guest` en el backend. El backend crea el usuario en Supabase Auth y el perfil en la tabla `profiles` en una sola transacción. Retorna el JWT generado por Supabase Auth.
- **Establecimiento de contraseña:** Flutter llama a `supabase.auth.updateUser({ password })` directamente. Un Trigger de PostgreSQL en Supabase detecta el cambio y actualiza automáticamente el `accountStatus` a `ACTIVE` en la tabla `profiles`.
- **Login, magic link, verificación:** Flutter los maneja directamente via SDK, sin pasar por el backend.

### Se comunica con

- Supabase Auth (crea el usuario en Supabase durante el registro GUEST)
- Tabla `profiles` en la base de datos (almacena nombre, teléfono y accountStatus)

---

### POST /auth/register-guest

Crea una cuenta GUEST. El backend crea el usuario en Supabase Auth y el perfil extendido en `profiles`. Si el correo ya existe como GUEST, retorna la cuenta existente sin duplicar.

**Body:**

```json
{
  "name": "string",
  "email": "string",
  "phone": "string"
}
```

**Response 201 — cuenta nueva:**

```json
{
  "userId": "uuid",
  "accountStatus": "guest",
  "userCreated": true,
  "token": "jwt_token"
}
```

**Response 200 — correo ya existía como GUEST:**

```json
{
  "userId": "uuid",
  "accountStatus": "guest",
  "userCreated": false,
  "token": "jwt_token"
}
```

**Response 409 — correo ya registrado como ACTIVE:**

```json
{
  "error": {
    "code": "AUTH_EMAIL_ALREADY_EXISTS",
    "message": "Este correo ya tiene una cuenta activa. Inicia sesión para continuar."
  }
}
```

---

### PATCH /auth/account-status

Actualiza el `accountStatus` en la tabla `profiles` a `ACTIVE`. Flutter llama a este endpoint después de que `supabase.auth.updateUser({ password })` se completa exitosamente.

El backend actualiza el campo directamente vía Prisma (no hay trigger en Supabase Auth). Esto da control explícito del flujo en el código del backend a costa de que la operación sea no-atómica entre Supabase Auth y `profiles`. Si la red cae entre los dos pasos, el usuario tiene contraseña seteada en Supabase pero `accountStatus` sigue `guest`. Aceptado para MVP: `updateUser` es idempotente y el usuario puede reintentar.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 200:**

```json
{
  "accountStatus": "active"
}
```

---

## Módulo: Usuarios

### Descripción

Gestiona los perfiles extendidos de usuario almacenados en la tabla `profiles`. La información base de autenticación (correo, sesión) la gestiona Supabase Auth; este módulo maneja los datos adicionales (nombre, teléfono, avatar, accountStatus) y las vistas de perfil público.

Los datos de contacto del solicitante se exponen al publicador únicamente dentro del detalle de la reserva recibida, no como endpoint separado.

### Se comunica con

- Supabase Auth (para validar el JWT e identificar al usuario)
- Supabase Storage (URL del avatar)
- Módulo de Reservas (el detalle de reserva recibida incluye datos del solicitante)

---

### GET /users/me

Retorna el perfil extendido del usuario autenticado. Complementa `supabase.auth.currentUser` con los datos almacenados en `profiles`.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 200:**

```json
{
  "userId": "uuid",
  "name": "string",
  "email": "string",
  "phone": "string",
  "accountStatus": "guest | active",
  "emailVerified": true,
  "avatarUrl": "string | null",
  "createdAt": "ISO8601"
}
```

---

### PUT /users/me

Actualiza el perfil extendido del usuario autenticado.

**Headers:** `Authorization: Bearer <jwt_token>`

**Body:** *(todos los campos son opcionales)*

```json
{
  "name": "string",
  "phone": "string",
  "avatarUrl": "string"
}
```

**Response 200:**

```json
{
  "userId": "uuid",
  "name": "string",
  "phone": "string",
  "avatarUrl": "string | null"
}
```

---

### GET /users/:userId/public

Retorna el perfil público de un usuario sin datos de contacto. Campos de segunda capa retornan `null` en el MVP.

**Response 200:**

```json
{
  "userId": "uuid",
  "name": "string",
  "avatarUrl": "string | null",
  "completedReservations": null,
  "rating": null
}
```

---

## Módulo: Feed

### Descripción

Vista de descubrimiento público: lista paginada de publicaciones activas filtradas por región. No requiere autenticación. La región llega como parámetro desde Flutter — el backend no hace geolocalización, solo filtra.

Distinto al módulo de Publicaciones: el feed es solo lectura y público; Publicaciones gestiona el CRUD del publicador autenticado.

### Se comunica con

- Tabla `publications` en la base de datos
- Google Geocoding API: en el cliente Flutter, no en el backend

---

### GET /feed

Retorna el feed paginado filtrado por región.

**Query params:**

| Param | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `region` | string | Sí | — | Región detectada o seleccionada por el usuario |
| `city` | string | No | — | Ciudad para refinamiento (segunda capa) |
| `order` | string | No | `recent` | `recent` \| `rating` \| `popular` |
| `page` | number | No | `1` | Número de página |
| `limit` | number | No | `20` | Resultados por página |

**Response 200:**

```json
{
  "data": [
    {
      "id": "uuid",
      "title": "string",
      "description": "string",
      "imageUrl": "string | null",
      "region": "string",
      "city": "string | null",
      "category": "Deporte | Eventos | Recreacion | Otros",
      "ownerName": "string",
      "ownerId": "uuid",
      "rating": null,
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "hasMore": true
  }
}
```

---

## Módulo: Publicaciones

### Descripción

Gestiona el CRUD de publicaciones desde la perspectiva del publicador autenticado. Una publicación contiene la información del servicio, la configuración de agenda inteligente y el estado de visibilidad. Solo usuarios ACTIVE pueden crear o gestionar publicaciones.

La agenda inteligente vive como objeto `availability` dentro de la publicación. El backend calcula los slots disponibles para una fecha aplicando la lógica: respeta `dayOverrides`, días cerrados, y filtra slots con reservas activas.

Las imágenes se suben directamente a Supabase Storage desde Flutter. El backend recibe solo la URL resultante.

**Categorías:** el campo `category` está restringido al enum `DEPORTE | EVENTOS | RECREACION | OTROS`. El backend valida con Zod y rechaza cualquier otro valor con `VALIDATION_ERROR`.

**`slotId`:** los IDs de slot son deterministas, construidos por el backend como `publicationId + date + startTime`. Flutter los recibe vía `GET /publications/:id/slots` y los pasa tal cual en `POST /reservations` — no se intenta reconstruir ni validar la forma en el cliente.

### Se comunica con

- Módulo de Reservas (filtra slots ya ocupados al calcular disponibilidad)
- Supabase Storage (recibe la URL de la imagen, no el archivo)
- Feed (publica las publicaciones activas)

---

### GET /publications/:id

Retorna el detalle completo de una publicación con su configuración de agenda. Público.

**Response 200:**

```json
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "imageUrl": "string | null",
  "region": "string",
  "city": "string | null",
  "category": "Deporte | Eventos | Recreacion | Otros",
  "ownerId": "uuid",
  "ownerName": "string",
  "rating": null,
  "isActive": true,
  "availability": {
    "slotDurationMinutes": 60,
    "sameScheduleAllDays": true,
    "defaultSchedules": [
      { "startTime": "09:00", "endTime": "18:00" }
    ],
    "dayOverrides": [
      {
        "dayOfWeek": "SUNDAY",
        "isClosed": true,
        "schedules": []
      }
    ]
  },
  "createdAt": "ISO8601"
}
```

---

### GET /publications/:id/slots

Retorna todos los slots del día para una fecha. Los ocupados se incluyen para que Flutter los muestre visualmente como no disponibles.

**Query params:**

| Param | Tipo | Requerido | Descripción |
|---|---|---|---|
| `date` | string | Sí | Fecha en formato `YYYY-MM-DD` |

**Response 200:**

```json
{
  "date": "2025-04-10",
  "slotDurationMinutes": 60,
  "slots": [
    {
      "id": "uuid",
      "startTime": "09:00",
      "endTime": "10:00",
      "available": true
    },
    {
      "id": "uuid",
      "startTime": "10:00",
      "endTime": "11:00",
      "available": false
    }
  ]
}
```

---

### GET /publications/mine

Retorna las publicaciones del usuario autenticado.

**Headers:** `Authorization: Bearer <jwt_token>`

**Query params:**

| Param | Tipo | Default |
|---|---|---|
| `page` | number | `1` |
| `limit` | number | `20` |

**Response 200:**

```json
{
  "data": [
    {
      "id": "uuid",
      "title": "string",
      "imageUrl": "string | null",
      "category": "Deporte | Eventos | Recreacion | Otros",
      "region": "string",
      "isActive": true,
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 3,
    "hasMore": false
  }
}
```

---

### POST /publications

Crea una nueva publicación. Requiere cuenta ACTIVE.

**Headers:** `Authorization: Bearer <jwt_token>`

**Body:**

```json
{
  "title": "string",
  "description": "string",
  "category": "Deporte | Eventos | Recreacion | Otros",
  "imageUrl": "string | null",
  "region": "string",
  "city": "string | null",
  "availability": {
    "slotDurationMinutes": 60,
    "sameScheduleAllDays": true,
    "defaultSchedules": [
      { "startTime": "09:00", "endTime": "18:00" }
    ],
    "dayOverrides": []
  }
}
```

**Response 201:**

```json
{
  "id": "uuid",
  "title": "string",
  "isActive": true,
  "createdAt": "ISO8601"
}
```

---

### PUT /publications/:id

Actualiza una publicación existente. Solo el dueño puede editarla.

**Headers:** `Authorization: Bearer <jwt_token>`

**Body:** *(misma estructura que POST, todos los campos opcionales)*

**Response 200:**

```json
{
  "id": "uuid",
  "title": "string",
  "updatedAt": "ISO8601"
}
```

---

### PATCH /publications/:id/status

Activa o pausa una publicación. Pausar la oculta del feed sin eliminarla ni afectar reservas existentes.

**Headers:** `Authorization: Bearer <jwt_token>`

**Body:**

```json
{
  "isActive": false
}
```

**Response 200:**

```json
{
  "id": "uuid",
  "isActive": false
}
```

---

### DELETE /publications/:id

Elimina una publicación. Solo el dueño puede eliminarla.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 204:** *(sin body)*

---

## Módulo: Reservas

### Descripción

Gestiona el ciclo de vida completo de una reserva. Conecta a un solicitante con una publicación en un slot específico. El estado sigue esta máquina de estados:

```
PENDIENTE
    ├── → CANCELADA     (acción del solicitante)
    ├── → RECHAZADA     (acción del publicador)
    ├── → COMPLETADA    (acción del publicador)
    └── → FALLIDA       (acción del publicador)
```

El publicador contacta al solicitante eligiendo el canal desde la app. Los datos de contacto del solicitante están disponibles en el detalle de la reserva recibida.

Los cambios de estado se propagan en tiempo real via Supabase Realtime directamente desde Flutter, sin necesidad de polling al backend.

### Se comunica con

- Módulo de Autenticación (identifica solicitante y publicador via JWT)
- Módulo de Publicaciones (valida slot y disponibilidad)
- Módulo de Notificaciones (crea notificaciones internas al cambiar estado)
- Resend (correo al publicador al recibir reserva, y al solicitante si elige email)
- Supabase Realtime (Flutter se suscribe directamente a cambios en `reservations`)

---

### POST /reservations

Crea una reserva. Si el usuario no está autenticado, se crean los datos de guest en el body y el backend crea la cuenta GUEST implícitamente antes de crear la reserva.

**Headers:** `Authorization: Bearer <jwt_token>` *(opcional)*

**Body:**

```json
{
  "publicationId": "uuid",
  "slotId": "uuid",
  "date": "2025-04-10",
  "guest": {
    "name": "string",
    "email": "string",
    "phone": "string"
  }
}
```

*Nota: `guest` solo se incluye si el usuario no está autenticado. Si hay token válido, se ignora.*

**Response 201:**

```json
{
  "reservationId": "uuid",
  "status": "pending",
  "publicationTitle": "string",
  "date": "2025-04-10",
  "startTime": "09:00",
  "endTime": "10:00",
  "userCreated": false,
  "token": "jwt_token | null"
}
```

*Nota: `token` se retorna solo si se creó una cuenta GUEST nueva en el mismo request.*

---

### GET /reservations/mine

Retorna las reservas del usuario autenticado como solicitante.

**Headers:** `Authorization: Bearer <jwt_token>`

**Query params:**

| Param | Tipo | Default | Descripción |
|---|---|---|---|
| `status` | string | — | Filtro: `pending`, `completed`, `failed`, `cancelled`, `rejected` |
| `page` | number | `1` | — |
| `limit` | number | `20` | — |

**Response 200:**

```json
{
  "data": [
    {
      "id": "uuid",
      "publicationId": "uuid",
      "publicationTitle": "string",
      "ownerName": "string",
      "date": "2025-04-10",
      "startTime": "09:00",
      "endTime": "10:00",
      "status": "pending",
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "hasMore": false
  }
}
```

---

### GET /reservations/received

Retorna las reservas recibidas por el publicador autenticado, incluyendo datos de contacto del solicitante.

**Headers:** `Authorization: Bearer <jwt_token>`

**Query params:** *(mismos que GET /reservations/mine)*

**Response 200:**

```json
{
  "data": [
    {
      "id": "uuid",
      "publicationId": "uuid",
      "publicationTitle": "string",
      "date": "2025-04-10",
      "startTime": "09:00",
      "endTime": "10:00",
      "status": "pending",
      "requester": {
        "userId": "uuid",
        "name": "string",
        "email": "string",
        "phone": "string"
      },
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 3,
    "hasMore": false
  }
}
```

---

### GET /reservations/:id

Detalle completo de una reserva. Accesible por el solicitante o el publicador de esa reserva.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 200:**

```json
{
  "id": "uuid",
  "publicationId": "uuid",
  "publicationTitle": "string",
  "date": "2025-04-10",
  "startTime": "09:00",
  "endTime": "10:00",
  "status": "pending",
  "requester": {
    "userId": "uuid",
    "name": "string",
    "email": "string",
    "phone": "string"
  },
  "owner": {
    "userId": "uuid",
    "name": "string"
  },
  "createdAt": "ISO8601"
}
```

---

### PATCH /reservations/:id/cancel

Cancela una reserva. Solo el solicitante puede cancelar y solo si el estado es `pending`.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 200:**

```json
{
  "reservationId": "uuid",
  "status": "cancelled"
}
```

---

### PATCH /reservations/:id/status

Actualiza el estado de una reserva. Solo el publicador. Transiciones válidas desde `pending`: `completed`, `failed`, `rejected`.

**Headers:** `Authorization: Bearer <jwt_token>`

**Body:**

```json
{
  "status": "completed | failed | rejected"
}
```

**Response 200:**

```json
{
  "reservationId": "uuid",
  "status": "completed"
}
```

---

### POST /reservations/:id/contact-email

Dispara la comunicación por correo electrónico usando Resend. 

*Nota: Este endpoint no registra el evento en la base de datos ni altera el estado de la reserva. El contacto por WhatsApp lo maneja Flutter nativamente via deep link utilizando el teléfono obtenido en el endpoint GET /reservations/received.*
Dispara un correo al solicitante vía Resend. Fire-and-forget: el endpoint **no persiste el evento en la base de datos** y retorna inmediatamente sin esperar confirmación de entrega de Resend.

WhatsApp **no pasa por este endpoint** — Flutter construye el `wa.me/...` localmente usando `requester.phone` que viene en el detalle de la reserva (`GET /reservations/:id`).

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 200:**

```json
{
  "sent": true,
  "message": "Correo enviado exitosamente al solicitante"
}
  "channel": "email"
}
```

**Response 200:**

```json
{
  "channel": "email",
  "sent": true
}
```

`sent: true` significa "dispatched a Resend"; no garantiza entrega final.

---

## Módulo: Notificaciones

### Descripción

Gestiona las notificaciones internas almacenadas en la tabla `notifications`. El backend las crea cuando ocurren eventos relevantes en el módulo de Reservas. Flutter las recibe en tiempo real via Supabase Realtime (suscripción directa a la tabla `notifications`) y las consulta via estos endpoints para el historial y el conteo de no leídas.

No hay notificaciones push nativas en el MVP.

Eventos que generan notificaciones:

- Nueva reserva recibida → `new_reservation` (para el publicador)
- Estado de reserva actualizado → `status_updated` (para el solicitante)
- Reserva cancelada por el solicitante → `reservation_cancelled` (para el publicador)

### Se comunica con

- Módulo de Reservas (los cambios de estado disparan la creación de notificaciones)
- Supabase Realtime (Flutter se suscribe directamente, el backend solo escribe)

---

### GET /notifications

Retorna las notificaciones del usuario en orden cronológico inverso.

**Headers:** `Authorization: Bearer <jwt_token>`

**Query params:**

| Param | Tipo | Default | Descripción |
|---|---|---|---|
| `unreadOnly` | boolean | `false` | Solo no leídas |
| `page` | number | `1` | — |
| `limit` | number | `20` | — |

**Response 200:**

```json
{
  "data": [
    {
      "id": "uuid",
      "type": "new_reservation | reservation_cancelled | status_updated",
      "title": "string",
      "body": "string",
      "reservationId": "uuid",
      "read": false,
      "createdAt": "ISO8601"
    }
  ],
  "unreadCount": 2,
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "hasMore": false
  }
}
```

---

### PATCH /notifications/:id/read

Marca una notificación como leída.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 200:**

```json
{
  "id": "uuid",
  "read": true
}
```

---

### PATCH /notifications/read-all

Marca todas las notificaciones del usuario como leídas.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 200:**

```json
{
  "updated": 5
}
```

---

## Changelog del contrato

- **2026-05-10** — Resueltas 4 decisiones pendientes con Cristian. Ver sección **Decisiones de arquitectura definidas** al inicio del documento. WhatsApp removido de `POST /reservations/:id/contact`; ahora se construye en Flutter usando `requester.phone` del detalle de la reserva.

---
