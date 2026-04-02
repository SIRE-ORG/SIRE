# Flujo de trabajo — Cristian

### SIRE · Backend Lead

---

## Tu rol en el proyecto

Eres responsable de todo el backend del proyecto: modelo de datos, lógica de negocio, endpoints de la API REST, autenticación, integraciones con Resend y WhatsApp, y la configuración de Supabase.

Daniel se encarga de conectar Flutter con tu API. Para que puedan trabajar en paralelo sin bloquearse, van a definir juntos un **contrato de API** al inicio del proyecto. Una vez acordado, lo implementarás de forma autónoma y Daniel mockeará los datos en Flutter hasta que los endpoints estén listos.

Tu principal responsabilidad de comunicación hacia el equipo es mantener actualizado el estado de implementación de los endpoints en `docs/api-status.md`.

---

## La estructura del proyecto backend

```
backend/
├── src/
│   ├── routes/         ← definición de endpoints
│   ├── controllers/    ← lógica de cada endpoint
│   ├── services/       ← lógica de negocio (reservas, disponibilidad, etc.)
│   ├── repositories/   ← acceso a base de datos via Prisma
│   ├── models/         ← tipos e interfaces TypeScript
│   ├── middlewares/    ← autenticación, validación, manejo de errores
│   └── integrations/   ← Resend, wa.me, Supabase
├── prisma/
│   ├── schema.prisma   ← definición de tablas
│   └── migrations/     ← historial de cambios en la BD
└── .env.example        ← variables de entorno necesarias (sin valores reales)
```

---

## La carpeta de documentación

El repositorio tiene una carpeta `/docs` en la rama `dev` donde vive toda la documentación del proyecto. Esta carpeta **no existe en `main`** — es exclusiva del entorno de desarrollo.

```
docs/
├── definicion.md           ← documento de definición del proyecto
├── api-contract.md         ← contrato de API entre Daniel y Cristian
├── api-status.md           ← estado de implementación de endpoints ← tú actualizas esto
├── flujo-emilia.md         ← documento de flujo de Emilia
├── flujo-cristian.md      ← este documento
└── dudas/
    ├── emilia/             ← dudas de Emilia
    └── cristian/          ← aquí dejas tus archivos de dudas
```

### Cómo usar la carpeta de dudas

Cuando tengas una pregunta sobre el contrato o algo que necesites definir con Daniel, puedes crear un archivo en `docs/dudas/cristian/`:

```
docs/dudas/cristian/disponibilidad.md
```

```markdown
# Dudas — Endpoint de disponibilidad

## slotId
¿El slotId lo genera el backend al calcular los slots disponibles,
o es un identificador que construye el frontend al seleccionar un horario?

Esto afecta cómo modelo la tabla de reservas y cómo valido
que un slot no esté ocupado al momento de confirmar.
```

El archivo viaja junto con tu rama y se mergea a `dev` con el PR correspondiente. Así queda el historial de lo que se preguntó y cómo se resolvió, útil si surge la misma duda más adelante.

---

## El contrato de API

Antes de que empieces a implementar, tú y Daniel van a acordar el contrato completo: qué endpoints existen, qué reciben y qué retornan. Ese contrato quedará documentado en `docs/api-contract.md`.

Una vez acordado, si necesitas cambiar la forma de un response (agregar un campo, renombrar algo), lo más útil es conversarlo antes de hacer el cambio — un ajuste en la estructura puede afectar el frontend sin que sea obvio dónde. Con un aviso previo se coordina sin problema.

### Ejemplo de cómo se ve un contrato acordado

```
GET /publications

Query params:
  - region: string (requerido)
  - order: "recent" | "rating" | "popular" (default: "recent")
  - page: number (default: 1)
  - limit: number (default: 20)

Response 200:
{
  "data": [
    {
      "id": "uuid",
      "title": "string",
      "description": "string",
      "imageUrl": "string",
      "region": "string",
      "ownerName": "string",
      "rating": number | null
    }
  ],
  "pagination": {
    "page": number,
    "limit": number,
    "total": number,
    "hasMore": boolean
  }
}
```

```
POST /reservations

Body:
{
  "publicationId": "uuid",
  "slotId": "uuid",
  "guest": {                  // solo si el usuario no tiene cuenta
    "name": "string",
    "email": "string",
    "phone": "string"
  }
}

Response 201:
{
  "reservationId": "uuid",
  "status": "pending",
  "userCreated": boolean
}

Response 409: slot ya reservado
Response 400: datos inválidos
```

---

## El archivo api-status.md

Este archivo es el puente de comunicación con Daniel respecto al avance del backend. Cada vez que termines un endpoint, lo marcas como listo. Daniel lo revisa para saber qué puede conectar en Flutter y qué todavía mockea.

A diferencia del resto de los archivos de `/docs`, `api-status.md` lo puedes actualizar con un commit directo a `dev` sin necesidad de abrir un PR — es solo un archivo de estado y no tiene impacto en el código.

### Formato del archivo

```markdown
# Estado de implementación de endpoints

Última actualización: [fecha]

## Autenticación

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| POST | /auth/register-guest | ✅ Listo | |
| POST | /auth/login | ✅ Listo | |
| POST | /auth/request-magic-link | 🚧 En progreso | |
| GET | /auth/me | ⏳ Pendiente | |

## Publicaciones

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | /publications | ✅ Listo | Filtro por región y ordenamiento implementados |
| GET | /publications/:id | ✅ Listo | |
| POST | /publications | 🚧 En progreso | Falta validación de agenda |
| PUT | /publications/:id | ⏳ Pendiente | |
| DELETE | /publications/:id | ⏳ Pendiente | |

## Reservas

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| POST | /reservations | ⏳ Pendiente | |
| GET | /reservations/mine | ⏳ Pendiente | |
| PATCH | /reservations/:id/cancel | ⏳ Pendiente | |
| PATCH | /reservations/:id/status | ⏳ Pendiente | Solo publicador |

## Disponibilidad

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | /publications/:id/slots | ⏳ Pendiente | Requiere fecha como query param |

## Leyenda
✅ Listo — 🚧 En progreso — ⏳ Pendiente — ❌ Bloqueado
```

---

## Estructura de respuestas de error

Para que el frontend pueda manejar los errores de forma consistente, todos los errores siguen el mismo formato:

```json
{
  "error": {
    "code": "SLOT_NOT_AVAILABLE",
    "message": "El slot seleccionado ya no está disponible"
  }
}
```

Códigos de error acordados:

```
AUTH_INVALID_CREDENTIALS
AUTH_EMAIL_ALREADY_EXISTS
SLOT_NOT_AVAILABLE
SLOT_NOT_FOUND
PUBLICATION_NOT_FOUND
RESERVATION_NOT_FOUND
RESERVATION_CANNOT_CANCEL
FORBIDDEN
VALIDATION_ERROR
```

---

## Git — cómo trabajar con el repositorio

### Configuración inicial (solo la primera vez)

```bash
# Clonar el repositorio
git clone https://github.com/SIRE-ORG/SIRE.git
cd SIRE

# Configurar tu nombre
git config user.name "Cristian"
git config user.email "tu@correo.com"
```

### Flujo diario

```bash
# 1. Asegúrate de tener lo último de dev
git checkout dev
git pull

# 2. Crea tu rama para lo que vas a implementar
git checkout -b cristian/endpoint-publications

# 3. Implementa...

# 4. Guarda tus cambios
git add .
git commit -m "feat: endpoint GET /publications con filtro por región"

# 5. Actualiza el api-status.md en un commit separado
git add docs/api-status.md
git commit -m "docs: marcar GET /publications como listo"

# 6. Sube tu rama
git push origin cristian/endpoint-publications
```

### Cómo nombrar tus ramas

El formato es siempre: `cristian/[qué-estás-haciendo]`

```
cristian/endpoint-publications
cristian/endpoint-reservations
cristian/modelo-disponibilidad
cristian/integracion-resend
cristian/auth-magic-link
cristian/supabase-realtime
```

### Cómo nombrar tus commits

Usa este formato: `tipo: descripción corta en minúsculas`

| Tipo | Cuándo usarlo |
|---|---|
| `feat:` | Nuevo endpoint o funcionalidad |
| `fix:` | Corrección de un bug |
| `docs:` | Actualización de `api-status.md`, `api-contract.md` u otro archivo en `/docs` |
| `refactor:` | Reorganización de código sin cambiar comportamiento |
| `chore:` | Configuración, dependencias, variables de entorno |

**Ejemplos:**

```bash
git commit -m "feat: endpoint GET /publications con paginación"
git commit -m "feat: endpoint POST /reservations con creación de usuario guest"
git commit -m "fix: error en cálculo de slots cuando hay bloques múltiples"
git commit -m "docs: actualizar api-status con endpoints de autenticación"
git commit -m "chore: agregar variables de entorno para Resend"
```

### Crear un Pull Request

Cuando termines un conjunto de endpoints relacionados:

1. Ve al repositorio: [github.com/SIRE-ORG/SIRE](https://github.com/SIRE-ORG/SIRE)
2. Haz clic en **"Pull requests"** → **"New pull request"**
3. Base: `dev` ← Compare: `cristian/endpoint-publications`
4. Título descriptivo: *"Endpoints de publicaciones: GET list y GET detail"*
5. Describí brevemente qué implementaste, si hay dependencias (ej: *"requiere que las tablas de Supabase estén creadas"*) o algo que quieras que Daniel revise antes del merge
6. Asigna a Daniel como reviewer
7. Haz clic en **"Create pull request"**

Los archivos de dudas que hayas creado en `docs/dudas/cristian/` viajan en el mismo PR. No necesitas un PR separado para documentación.

---

## Manejo de variables de entorno

El archivo `.env` nunca va al repositorio. Lo que sí va es `.env.example` con las claves pero sin valores reales:

```bash
# .env.example — este SÍ va al repo
SUPABASE_URL=
SUPABASE_SERVICE_KEY=
RESEND_API_KEY=
DATABASE_URL=
PORT=3000
```

```bash
# .env — este NUNCA va al repo (ya está en .gitignore)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_KEY=eyJxxx...
RESEND_API_KEY=re_xxx...
DATABASE_URL=postgresql://...
PORT=3000
```

Cada vez que agregues una variable nueva, actualiza `.env.example` y avisa en el grupo para que Daniel pueda configurarla en su entorno también.

---

## Migraciones de base de datos con Prisma

Cada vez que necesites cambiar el schema de la base de datos, crea una migración con un nombre descriptivo:

```bash
# Crear la migración
npx prisma migrate dev --name agregar-tabla-reservaciones

# Esto genera un archivo en prisma/migrations/ que sí va al repo
# Cualquier integrante puede aplicar las migraciones en su entorno con:
npx prisma migrate dev
```

Es importante crear siempre la migración antes de modificar las tablas directamente en Supabase — si los entornos se desincronizán, es difícil de rastrear y toma tiempo arreglarlo.

---

## Cómo avisar al equipo si algo te bloquea

En el grupo de WhatsApp, usa este formato:

> 🔴 **Bloqueado** en [endpoint o tarea] — necesito [qué cosa específica] de [Daniel/Emilia]. Dejé una duda en `docs/dudas/cristian/[archivo].md`

**Ejemplo:**
> 🔴 **Bloqueado** en endpoint de disponibilidad — necesito que Daniel confirme si el `slotId` lo genera el backend o el frontend. Dejé el detalle en `docs/dudas/cristian/disponibilidad.md`

---

*Documento de trabajo interno — SIRE v1.2*

