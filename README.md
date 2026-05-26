# SIRE — Sistema Integral de Reservas Estratégicas

Aplicación móvil multiplataforma que centraliza la agenda y el agendamiento
de horas para emprendimientos locales, conectando negocios con sus clientes
a través de un feed dinámico y una agenda inteligente configurable.

---

## Problemática

La mayoría de los emprendimientos locales gestionan su atención al cliente
a través de canales dispersos y/o informales: Instagram, WhatsApp, Facebook, etc.
No hay estándar. Cada negocio resuelve cómo comunicarse por **su** cuenta,
cómo promocionarse y cómo organizar su agenda — y los clientes tienen que
adaptarse **a cada uno de ellos**.

## La solución

SIRE **centraliza tres cosas** en un solo lugar:

- **Feed de publicaciones** — los negocios publican sus servicios y los
  clientes los descubren filtrados por *zona geográfica*.
- **Agenda inteligente** — cada publicación tiene una *disponibilidad*
  *configurable por día y horario*; el cliente reserva directamente desde
  la app sin pasar por WhatsApp o canales externos.
- **Canal de comunicación unificado** — el negocio elige si contacta al
  cliente por correo o WhatsApp; *la app lo gestiona*.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Mobile | Flutter (Dart) |
| Estado | Riverpod |
| Backend | Node.js + TypeScript (Fastify) |
| Base de datos | Supabase (PostgreSQL) |
| ORM | Prisma |
| Autenticación | Supabase Auth (JWT + Magic Link) |
| Tiempo real | Supabase Realtime |
| Correo | Resend |
| Geolocalización | Google Geocoding API |
| Almacenamiento | Supabase Storage |

---

## Equipo

| Integrante | Rol |
|---|---|
| Daniel | Tech Lead · Arquitecto · Flutter Lead |
| Emilia | Designer · Frontend Flutter |
| Cristian | Backend Lead |

---

## Requisitos previos

Antes de clonar e instalar el proyecto, asegúrate de tener instalado:

| Herramienta | Versión mínima | Verificación | Instalación |
|---|---|---|---|
| **Git** | 2.x | `git --version` | <https://git-scm.com/downloads> |
| **Flutter SDK** | ≥ 3.11.3 | `flutter --version` | <https://docs.flutter.dev/get-started/install> |
| **Node.js** | ≥ 20 LTS | `node --version` | <https://nodejs.org/> |
| **npm** | ≥ 10 | `npm --version` | Incluido con Node.js |

### Requisitos externos

- **Proyecto en Supabase** — la app se conecta a un proyecto Supabase para
  autenticación, base de datos PostgreSQL, almacenamiento de archivos y
  tiempo real.
- **Dispositivo/emulador** — para ejecutar la app Flutter necesitas un
  dispositivo Android/iOS conectado o un emulador configurado.
  Verifica con `flutter doctor`.

---

## Variables de entorno

El proyecto usa dos archivos `.env` independientes. Ambos están excluidos
de Git (`.gitignore`), por lo que debes crearlos a partir de las plantillas
`.env.example` provistas.

### Flutter (raíz del proyecto)

| Variable | Obligatoria | Descripción |
|---|---|---|
| `SUPABASE_URL` | ✅ Sí | URL del proyecto en Supabase |
| `SUPABASE_ANON_KEY` | ✅ Sí | Clave anónima de Supabase (anon/public key) |
| `API_BASE_URL` | ✅ Sí | URL base del backend REST (Fastify). Desarrollo local: `http://<IP>:3000/api/v1` |
| `GOOGLE_GEOCODING_KEY` | 🔧 Opcional | API key de Google Geocoding — solo como fallback si el servicio nativo del dispositivo no está disponible |

**Dónde obtener los valores:**

- `SUPABASE_URL` y `SUPABASE_ANON_KEY`: Supabase Dashboard → Settings → API
- `API_BASE_URL`: la IP y puerto donde corre el backend (por defecto `http://localhost:3000/api/v1`)
- `GOOGLE_GEOCODING_KEY`: Google Cloud Console → APIs & Services → Credentials

### Backend (`backend/.env`)

| Variable | Obligatoria | Descripción |
|---|---|---|
| `DATABASE_URL` | ✅ Sí | Cadena de conexión PostgreSQL con PgBouncer (puerto 6543) |
| `DIRECT_URL` | ✅ Sí | Cadena de conexión PostgreSQL directa para migraciones de Prisma (puerto 5432) |
| `PORT` | 🔧 Opcional | Puerto del servidor Fastify (default: `3000`) |

**Dónde obtener los valores:**

- Supabase Dashboard → Settings → Database → Connection string
- Selecciona la pestaña "Prisma" para ver tanto `DATABASE_URL` como `DIRECT_URL`

---

## Estructura del proyecto

```
SIRE/
├── .env.example              # Plantilla de variables de entorno Flutter
├── pubspec.yaml              # Dependencias y configuración Dart/Flutter
├── README.md                 # Este archivo
│
├── scripts/                  # Scripts de automatización
│   ├── setup.sh              # Instalación automatizada (Linux/macOS/Git Bash)
│   ├── setup.bat             # Instalación automatizada (Windows CMD)
│   ├── run_dev.sh            # Ejecución en desarrollo (Linux/macOS/Git Bash)
│   └── run_dev.bat           # Ejecución en desarrollo (Windows CMD)
│
├── lib/                      # Código fuente Flutter (Clean Architecture)
│   ├── main.dart             # Punto de entrada — inicializa dotenv + Supabase
│   ├── core/                 # Capa transversal
│   │   ├── network/          # Cliente HTTP (Dio) + constantes de API
│   │   ├── router/           # Navegación (GoRouter)
│   │   ├── storage/          # Almacenamiento local
│   │   ├── theme/            # Tema de la app
│   │   └── widgets/          # Widgets reutilizables (cards, layouts)
│   └── features/             # Funcionalidades por dominio
│       ├── auth/             # Autenticación (Supabase Auth + backend REST)
│       ├── feed/             # Feed de publicaciones geolocalizado
│       ├── publications/     # CRUD de publicaciones + agenda configurable
│       ├── reservations/     # Reservas de slots horarios
│       ├── profile/          # Perfil de usuario
│       └── notifications/    # Notificaciones in-app
│
├── assets/                   # Recursos estáticos
│   ├── images/               # Imágenes
│   ├── icons/                # Íconos
│   └── fonts/                # Familia tipográfica SF Pro (5 pesos)
│
├── backend/                  # Backend REST (Node.js + Fastify + Prisma)
│   ├── .env.example          # Plantilla de variables de entorno del backend
│   ├── package.json          # Dependencias y scripts npm
│   ├── tsconfig.json         # Configuración TypeScript (strict, ESNext)
│   ├── prisma/
│   │   ├── schema.prisma     # Modelo de datos (Profile, Publication, Reservation)
│   │   └── migrations/       # Migraciones SQL generadas por Prisma
│   └── src/
│       ├── app.ts            # Punto de entrada Fastify — registra rutas en /api/v1
│       ├── controllers/      # Controladores (auth, user, publication)
│       ├── routes/           # Definición de rutas REST
│       ├── services/         # Lógica de negocio
│       └── repositories/     # Acceso a datos vía Prisma
│
├── docs/                     # Documentación del proyecto
│   ├── api-contract.md       # Contrato completo de la API REST
│   ├── api-status.md         # Estado actual de integración Flutter ↔ Backend
│   ├── requerimientos.md     # Requerimientos funcionales y no funcionales
│   ├── definicion_del_proyecto.md
│   ├── flujo-cristian.md     # Flujo de trabajo Backend
│   ├── flujo-emilia.md       # Flujo de trabajo Frontend
│   └── diagramas/            # Diagramas UML (casos de uso, clases, componentes, CPM)
│
├── android/                  # Proyecto Android (Kotlin/Gradle)
├── ios/                      # Proyecto iOS (Swift/Xcode)
├── web/                      # Proyecto Web (PWA)
├── windows/                  # Proyecto Windows (Win32)
├── linux/                    # Proyecto Linux (GTK)
└── macos/                    # Proyecto macOS (Cocoa)
```

---

## Instalación y configuración

### Opción 1: Script automatizado (recomendado)

El script verifica prerequisitos, crea los archivos `.env`, instala dependencias,
genera código y aplica migraciones. Cada paso valida que el anterior se completó
correctamente antes de continuar.

**Linux / macOS / Git Bash (Windows):**

```bash
bash scripts/setup.sh
```

**Windows CMD:**

```bat
scripts\setup.bat
```

El script te guiará paso a paso y te pedirá confirmación antes de aplicar
migraciones a la base de datos.

### Opción 2: Instalación manual paso a paso

Si prefieres control granular sobre cada etapa, sigue estos pasos en orden:

#### 1. Clonar el repositorio

```bash
git clone <url-del-repo>
cd SIRE
```

#### 2. Crear archivos de variables de entorno

```bash
# Flutter (raíz)
cp .env.example .env
# Editar .env con editor de texto — completar SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL

# Backend
cp backend/.env.example backend/.env
# Editar backend/.env — completar DATABASE_URL y DIRECT_URL con las cadenas de Supabase
```

#### 3. Instalar dependencias Flutter/Dart

```bash
flutter pub get
```

#### 4. Generar código con build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

> **Nota:** Este paso genera los archivos `.g.dart` requeridos por los
> proveedores anotados con `@riverpod`. Si el proyecto no tuviera anotaciones
> de Riverpod aún, build_runner completará sin generar archivos nuevos (no es error).

#### 5. Instalar dependencias del backend

```bash
cd backend
npm install
```

#### 6. Generar cliente de Prisma

```bash
npx prisma generate
```

#### 7. Aplicar migraciones a la base de datos

```bash
npx prisma migrate dev
```

> **Importante:** Este paso requiere que `DATABASE_URL` y `DIRECT_URL` en
> `backend/.env` estén configurados correctamente y que la IP de tu máquina
> esté en la whitelist de Supabase (Dashboard → Settings → Database).

#### 8. Verificar instalación

```bash
# Verificar que Flutter no tenga errores
flutter doctor
dart analyze lib/

# Verificar que el backend compila
cd backend
npx tsc --noEmit
```

---

## Scripts disponibles

| Script | Plataforma | Propósito |
|---|---|---|
| `bash scripts/setup.sh` | Linux / macOS / Git Bash | Instalación completa automatizada con verificación de prerequisitos, instalación de dependencias, generación de código, migraciones y doctores de integridad |
| `scripts\setup.bat` | Windows CMD | Igual que `setup.sh` para Windows nativo |
| `bash scripts/run_dev.sh` | Linux / macOS / Git Bash | Inicia backend (Fastify) + Flutter concurrentemente. Al detener Flutter (Ctrl+C), el backend se cierra automáticamente vía señal SIGINT |
| `scripts\run_dev.bat` | Windows CMD | Inicia backend en ventana separada + Flutter en la ventana actual. Al cerrar Flutter, debe cerrarse manualmente la ventana del backend |

### Comandos individuales

| Comando | Dónde ejecutarlo | Propósito |
|---|---|---|
| `flutter pub get` | Raíz del proyecto | Instalar/actualizar dependencias Dart |
| `flutter run` | Raíz del proyecto | Ejecutar la app en dispositivo/emulador conectado |
| `flutter run -d <device-id>` | Raíz del proyecto | Ejecutar en un dispositivo específico |
| `flutter devices` | Raíz del proyecto | Listar dispositivos/emuladores disponibles |
| `flutter doctor` | Raíz del proyecto | Diagnosticar el estado del entorno Flutter |
| `dart analyze lib/` | Raíz del proyecto | Análisis estático del código Dart |
| `dart run build_runner build --delete-conflicting-outputs` | Raíz del proyecto | Generar código (`.g.dart` para Riverpod) |
| `dart run build_runner clean` | Raíz del proyecto | Limpiar caché de build_runner |
| `npm run dev` | `backend/` | Iniciar backend Fastify con hot-reload (tsx watch) |
| `npm install` | `backend/` | Instalar/actualizar dependencias Node.js |
| `npx prisma generate` | `backend/` | Generar cliente de Prisma tipado |
| `npx prisma migrate dev` | `backend/` | Aplicar migraciones pendientes a la BD |
| `npx prisma migrate status` | `backend/` | Verificar estado de migraciones |
| `npx prisma validate` | `backend/` | Validar sintaxis del schema de Prisma |
| `npx prisma studio` | `backend/` | Abrir Prisma Studio (GUI para explorar la BD) |
| `npx tsc --noEmit` | `backend/` | Compilar TypeScript sin emitir JS (solo verificación) |
| `flutter build apk --debug` | Raíz del proyecto | Generar APK de desarrollo para Android |

---

## Cómo ejecutar el proyecto

### Resumen rápido

```bash
# Terminal 1 — Backend (debe iniciarse primero)
cd backend
npm run dev
# Fastify escucha en http://localhost:3000

# Terminal 2 — Flutter
flutter run
```

### Usando los scripts

**Linux / macOS / Git Bash:**

```bash
bash scripts/run_dev.sh
```

El script inicia backend + Flutter concurrentemente. Al presionar `Ctrl+C`
en la terminal de Flutter, el backend se cierra automáticamente.

**Windows CMD:**

```bat
scripts\run_dev.bat
```

El backend se abre en una ventana separada. Al cerrar Flutter, **recuerda
cerrar manualmente la ventana del backend** (titulada "SIRE Backend — Fastify :3000").

### Orden de inicio

1. **Backend primero** — Fastify debe estar escuchando antes de que Flutter
   intente consumir la API REST.
2. **Flutter después** — la app se conecta a Supabase directamente (auth,
   storage, realtime) y al backend para la lógica de negocio.

### Solución de problemas frecuentes

| Problema | Causa probable | Solución |
|---|---|---|
| `flutter pub get` falla | Sin conexión o caché corrupta | `flutter pub cache repair` y reintentar |
| `build_runner` falla | Conflicto de archivos `.g.dart` | `dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs` |
| Backend no arranca | `backend/.env` no configurado | Copiar `backend/.env.example` → `backend/.env` y completar `DATABASE_URL` |
| `prisma migrate dev` falla | IP no whitelisteada en Supabase | Supabase Dashboard → Settings → Database → agregar IPv4 |
| App no se conecta al backend | `API_BASE_URL` incorrecta en `.env` | Verificar IP y puerto; si usas emulador Android, usar `10.0.2.2` en vez de `localhost` |
| `dart analyze` reporta errores | Código con errores de compilación | Revisar los mensajes de `dart analyze`; pueden ser advertencias que no bloquean la ejecución |

---

## Funcionalidades MVP

- Registro y autenticación (flujo con contraseña diferida para reservas sin cuenta)
- Feed geolocalizado de publicaciones con filtros por zona y ciudad
- Agenda configurable: horarios por día, múltiples bloques, días cerrados
- Reserva de slots con validación de disponibilidad en tiempo real
- Gestión de reservas para publicadores (aceptar, rechazar, completar, contactar)
- Notificaciones in-app via Supabase Realtime
- Comunicación con el cliente vía correo (Resend) o WhatsApp (deep link wa.me)

---

## Estado del proyecto

🚧 En desarrollo — Proyecto académico · Universidad de la Frontera - Temuco · 2026

---

## Documentación adicional

| Documento | Contenido |
|---|---|
| [`docs/api-contract.md`](docs/api-contract.md) | Contrato completo de la API REST (endpoints, request/response, códigos de error) |
| [`docs/api-status.md`](docs/api-status.md) | Estado actual de integración entre Flutter y los servicios externos |
| [`docs/requerimientos.md`](docs/requerimientos.md) | Requerimientos funcionales y no funcionales del sistema |
| [`docs/definicion_del_proyecto.md`](docs/definicion_del_proyecto.md) | Definición y alcance del proyecto |
| [`docs/diagramas/`](docs/diagramas/) | Diagramas UML: casos de uso, CPM, clases de dominio, componentes |
