# SIRE — Contrato de API

*Borrador para revisión de Cristian*

---

## Convenciones generales

- Base URL: `https://[dominio-render]/api/v1`
- Todos los requests y responses usan `Content-Type: application/json`
- Los endpoints protegidos requieren header `Authorization: Bearer <jwt_token>`
- Los IDs son UUIDs v4
- Las fechas siguen el formato ISO 8601: `"2025-04-07T10:00:00Z"`
- Los horarios de slots usan formato `"HH:MM"`: `"09:00"`, `"10:30"`

---

## Formato de errores

Todos los errores siguen esta estructura:

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
| `AUTH_INVALID_CREDENTIALS` | 401 | Login con contraseña incorrecta, o token JWT expirado | Redirige al login o solicita magic link |
| `AUTH_EMAIL_ALREADY_EXISTS` | 409 | Formulario de reserva con correo que ya tiene cuenta ACTIVE | Redirige al login con mensaje explicativo |
| `AUTH_EMAIL_NOT_VERIFIED` | 403 | Acción que requiere correo verificado (reservado para uso futuro, no bloquea en MVP) | Muestra prompt de reenvío de verificación |
| `AUTH_UNAUTHORIZED` | 401 | Request a endpoint protegido sin token, con token malformado o expirado | Interceptado globalmente, redirige al login |
| `SLOT_NOT_AVAILABLE` | 409 | Dos usuarios intentan reservar el mismo slot simultáneamente; el segundo en llegar recibe este error | Recarga los slots disponibles y muestra aviso |
| `SLOT_NOT_FOUND` | 404 | El slotId no corresponde a la publicación y fecha; ocurre si la agenda fue modificada mientras el usuario tenía la pantalla abierta | Vuelve al calendario y recarga disponibilidad |
| `PUBLICATION_NOT_FOUND` | 404 | La publicación fue eliminada o pausada mientras el usuario navegaba hacia ella | Vuelve al feed con aviso de no disponibilidad |
| `RESERVATION_NOT_FOUND` | 404 | ID de reserva inexistente o de otro usuario | Vuelve a "Mis reservas" |
| `RESERVATION_CANNOT_CANCEL` | 422 | Intento de cancelar una reserva que no está en estado `pending` | El botón de cancelar se deshabilita en el frontend si el estado no es `pending`; este código es red de seguridad |
| `RESERVATION_CANNOT_UPDATE` | 422 | Transición de estado inválida (ej: completar una reserva ya rechazada) | Recarga el estado actual de la reserva |
| `FORBIDDEN` | 403 | Usuario intenta operar sobre un recurso que no le pertenece (ej: editar publicación ajena, cambiar estado de reserva que no recibió) | Muestra error genérico, recarga el recurso |
| `VALIDATION_ERROR` | 400 | Campos faltantes, tipos incorrectos o valores fuera de rango en el body | Muestra errores de validación inline en el formulario |

---

## Módulo: Autenticación

### Descripción

Gestiona el ciclo de vida de las cuentas de usuario. SIRE tiene dos estados de cuenta: `GUEST` (creada implícitamente desde el formulario de reserva, sin contraseña) y `ACTIVE` (con contraseña establecida). La autenticación se basa en JWT gestionado por Supabase Auth.

### Flujos principales

- **Registro implícito:** el formulario de reserva crea una cuenta GUEST sin interrumpir el flujo. Si el correo ya existe como GUEST, se reutiliza la cuenta. Si existe como ACTIVE, se redirige al login.
- **Establecimiento de contraseña:** desde sesión activa, el usuario GUEST puede establecer su contraseña via `POST /auth/set-password`, que llama a `supabase.auth.updateUser({ password })` internamente y transiciona el estado a ACTIVE.
- **Fallback sin sesión:** si el usuario GUEST cierra la app y regresa sin sesión activa, solicita un magic link via `POST /auth/request-magic-link`. Supabase Auth envía el link por Resend y al hacer clic se restaura la sesión, donde se le presenta el bottom sheet de contraseña.
- **Verificación de correo:** se envía automáticamente al crear la cuenta. No bloquea el flujo de reserva en el MVP (opción B).

### Se comunica con

- Supabase Auth (JWT, magic link, updateUser)
- Resend (correo de verificación y magic link)
- Módulo de Reservas (al crear cuenta GUEST desde el formulario de reserva)

---

### POST /auth/register-guest

Crea una cuenta en estado GUEST desde el formulario de reserva. Si el correo ya existe como GUEST, retorna la cuenta existente sin duplicar.

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

### POST /auth/login

Autentica un usuario con correo y contraseña.

**Body:**

```json
{
  "email": "string",
  "password": "string"
}
```

**Response 200:**

```json
{
  "userId": "uuid",
  "name": "string",
  "email": "string",
  "accountStatus": "active",
  "token": "jwt_token"
}
```

---

### POST /auth/set-password

Establece la contraseña de un usuario GUEST desde sesión activa. Transiciona el estado a ACTIVE.

**Headers:** `Authorization: Bearer <jwt_token>`

**Body:**

```json
{
  "password": "string"
}
```

**Response 200:**

```json
{
  "accountStatus": "active"
}
```

---

### POST /auth/request-magic-link

Envía un magic link al correo registrado. Usado como fallback cuando el usuario GUEST regresa sin sesión activa. Siempre retorna 200 para no exponer qué correos están registrados.

**Body:**

```json
{
  "email": "string"
}
```

**Response 200:**

```json
{
  "message": "Si el correo está registrado, recibirás un link de acceso."
}
```

---

### POST /auth/request-verification

Reenvía el correo de verificación al usuario autenticado.

**Headers:** `Authorization: Bearer <jwt_token>`

**Response 200:**

```json
{
  "message": "Correo de verificación enviado"
}
```

---

### GET /auth/me

Retorna los datos del usuario autenticado.

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

## Módulo: Usuarios

### Descripción

Gestiona los perfiles de usuario. Existen dos vistas del perfil: la privada (accesible solo por el propio usuario) y la pública (accesible por cualquier usuario autenticado, sin datos de contacto). Los datos privados del solicitante — correo y teléfono — se exponen al publicador únicamente dentro del detalle de la reserva recibida, no como endpoint separado de usuario.

### Se comunica con

- Módulo de Autenticación (token JWT para identificar al usuario)
- Módulo de Reservas (el detalle de reserva recibida incluye los datos del solicitante)
- Supabase Storage (avatar del usuario)

---

### PUT /users/me

Actualiza el perfil del usuario autenticado.

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

Retorna el perfil público de un usuario. No expone datos de contacto. Los campos de segunda capa retornan `null` en el MVP.

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

El feed es la vista principal de la aplicación: una lista paginada de publicaciones filtradas por región. Es el único módulo completamente público — no requiere autenticación para ser consultado. La región se detecta automáticamente via Google Geocoding API en el cliente Flutter y se envía como parámetro al backend. El backend no hace geolocalización, solo filtra por el valor de región que recibe.

El feed es distinto al módulo de Publicaciones: el feed es la vista de descubrimiento público, mientras que Publicaciones gestiona el CRUD de las publicaciones propias del publicador.

### Se comunica con

- Módulo de Publicaciones (comparten la entidad `Publication`)
- Google Geocoding API (en el cliente Flutter, no en el backend)

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
      "category": "string",
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

Gestiona el CRUD de publicaciones desde la perspectiva del publicador. Una publicación es la entidad central del sistema: contiene la información del servicio ofrecido, la configuración de la agenda inteligente y el estado de visibilidad. Solo usuarios con cuenta ACTIVE pueden crear o gestionar publicaciones.

La agenda inteligente se almacena dentro de la publicación como un objeto `availability`. El backend calcula los slots disponibles para una fecha específica aplicando la lógica definida: respeta los `dayOverrides`, los días cerrados y filtra los slots que ya tienen reservas activas.

### Se comunica con

- Módulo de Reservas (para filtrar slots ya ocupados)
- Supabase Storage (imagen de la publicación)
- Feed (las publicaciones activas aparecen en el feed)

---

### GET /publications/:id

Retorna el detalle completo de una publicación, incluyendo la configuración de agenda. Público, no requiere autenticación.

**Response 200:**

```json
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "imageUrl": "string | null",
  "region": "string",
  "city": "string | null",
  "category": "string",
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

Retorna todos los slots del día para una fecha específica, marcando cuáles están disponibles y cuáles ocupados. Los slots ocupados se retornan para que Flutter pueda mostrarlos visualmente como no disponibles.

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

Retorna las publicaciones del usuario autenticado con su estado de visibilidad.

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
      "category": "string",
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
  "category": "string",
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

Activa o pausa una publicación. Pausar la oculta del feed sin eliminarla ni afectar las reservas existentes.

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

Gestiona el ciclo de vida completo de una reserva. Una reserva conecta a un solicitante con una publicación en un slot específico de fecha y hora. El estado de la reserva sigue una máquina de estados definida:

```
PENDIENTE
    ├── → CANCELADA     (acción del solicitante)
    ├── → RECHAZADA     (acción del publicador)
    ├── → COMPLETADA    (acción del publicador)
    └── → FALLIDA       (acción del publicador)
```

El publicador puede contactar al solicitante desde la misma app eligiendo el canal: correo via Resend o WhatsApp via deep link wa.me. Los datos de contacto del solicitante — nombre, correo y teléfono — están disponibles en el detalle de la reserva recibida, sin necesidad de un endpoint separado de usuario.

Las notificaciones de cambios de estado se propagan en tiempo real al cliente Flutter via Supabase Realtime, suscripto a cambios en la tabla `reservations`.

### Se comunica con

- Módulo de Autenticación (identificación del solicitante y del publicador)
- Módulo de Publicaciones (validación del slot y disponibilidad)
- Módulo de Notificaciones (disparo de notificaciones internas)
- Resend (correo al publicador al recibir reserva, correo al solicitante si elige ese canal)
- Supabase Realtime (propagación de cambios de estado en tiempo real)

---

### POST /reservations

Crea una reserva. Si el usuario no está autenticado, se incluyen los datos de guest en el body y se crea la cuenta implícitamente.

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
| `status` | string | — | Filtro opcional: `pending`, `completed`, `failed`, `cancelled`, `rejected` |
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

Retorna las reservas recibidas por el publicador autenticado. Incluye los datos de contacto del solicitante para gestionar la comunicación.

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

Retorna el detalle completo de una reserva. Accesible por el solicitante o el publicador de esa reserva específica.

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

Cancela una reserva. Solo el solicitante puede cancelar, y solo si el estado es `pending`.

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

Actualiza el estado de una reserva. Solo el publicador puede usarlo. Las transiciones válidas desde `pending` son `completed`, `failed` y `rejected`.

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

### POST /reservations/:id/contact

Registra el canal de contacto elegido por el publicador y dispara la comunicación. Si el canal es `email`, Resend envía un correo al solicitante. Si el canal es `whatsapp`, el backend construye y retorna el deep link con el mensaje pre-redactado.

**Headers:** `Authorization: Bearer <jwt_token>`

**Body:**

```json
{
  "channel": "email | whatsapp"
}
```

**Response 200 — canal email:**

```json
{
  "channel": "email",
  "sent": true
}
```

**Response 200 — canal whatsapp:**

```json
{
  "channel": "whatsapp",
  "deepLink": "https://wa.me/56912345678?text=Hola%20Juan..."
}
```

---

## Módulo: Notificaciones

### Descripción

Gestiona las notificaciones internas de la plataforma. Las notificaciones se almacenan en base de datos y se propagan en tiempo real via Supabase Realtime al cliente Flutter mientras la app está activa. No hay notificaciones push nativas en el MVP.

Los eventos que generan notificaciones son:

- El publicador recibe una reserva nueva → `new_reservation`
- El solicitante recibe una actualización de estado → `status_updated`
- El publicador recibe una cancelación del solicitante → `reservation_cancelled`

### Se comunica con

- Módulo de Reservas (los cambios de estado disparan notificaciones)
- Supabase Realtime (propagación al cliente Flutter en tiempo real)

---

### GET /notifications

Retorna las notificaciones del usuario autenticado en orden cronológico inverso.

**Headers:** `Authorization: Bearer <jwt_token>`

**Query params:**

| Param | Tipo | Default | Descripción |
|---|---|---|---|
| `unreadOnly` | boolean | `false` | Solo notificaciones no leídas |
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

## Supabase Realtime — suscripciones

El cliente Flutter se suscribe directamente a Supabase Realtime para propagar cambios en tiempo real sin necesidad de polling.

| Tabla | Evento | Filtro | Quién escucha | Para qué |
|---|---|---|---|---|
| `reservations` | `INSERT` | `publication.owner_id = userId` | Publicador | Nueva reserva recibida |
| `reservations` | `UPDATE` | `requester_id = userId` | Solicitante | Cambio de estado por el publicador |
| `reservations` | `UPDATE` | `publication.owner_id = userId` | Publicador | Cancelación por el solicitante |
| `notifications` | `INSERT` | `user_id = userId` | Ambos | Indicador de notificaciones no leídas |

*Nota: estas suscripciones solo están activas mientras la app está abierta. No reemplazan notificaciones push.*

---

## Pendientes por confirmar con Cristian

- [ ] ¿El `slotId` lo genera el backend al calcular disponibilidad, o es un identificador construido desde `publicationId + date + startTime`?, dependiendo de eso lo consumiré de una forma u otra.
- [ ] ¿Las categorías de publicación son un enum fijo en el backend o un campo de texto libre? Yo propongo Enum, validarías los tipos con Zod y me dejarías la definición de tipado de datos aqui mismo (en api-contract.md) para replicarlos en la capa de datos del front.
- [ ] ¿El endpoint `POST /reservations/:id/contact` registra el evento en base de datos además de disparar la comunicación?, para saber cómo reaccionar desde el front, si con un observador o con refresco in-app.
- [ ] ¿Cómo se maneja el refresh del JWT cuando expira — el cliente lo solicita activamente o Supabase Auth lo renueva automáticamente?, para saber cómo manejar el consumo de credenciales y también por la capa de seguridad.
- [ ] Confirmar si Supabase Auth maneja el magic link y la verificación de correo directamente o si pasan por el backend como intermediario - sino tendrás que hacer un microservicio en el backend específico para eso.

---
