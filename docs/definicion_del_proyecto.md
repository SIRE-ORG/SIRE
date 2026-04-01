# SIRE — Documento de Definición del Proyecto
### Sistema Integral de Reservas Estratégicas
*Versión 2.0 — Documento interno de trabajo*

---

## 1. Equipo

| Integrante | Rol | Dominio |
|---|---|---|
| **Daniel** | Tech Lead · Arquitecto · DevOps · Flutter Lead | Arquitectura general, Flutter (lógica, estado, navegación, integraciones), infraestructura, decisiones técnicas transversales |
| **Emilia** | Designer · Frontend Flutter | Diseño UX/UI en Figma, sistema de diseño, implementación de pantallas y widgets en Flutter |
| **Cristóbal** | Backend Lead | Modelo de datos, API REST, autenticación, lógica de negocio, integraciones externas, Supabase |

### Responsabilidades por módulo

| Módulo | Daniel | Emilia | Cristóbal |
|---|---|---|---|
| Feed y publicaciones | Integración API, lógica de zona y ordenamiento | Pantallas, componentes visuales, cards | Endpoints, modelo de datos, queries con filtros |
| Reservas | Flujo de UI, estados en pantalla | Pantallas de reserva y estado | Lógica de negocio, estados, transiciones |
| Agenda inteligente | Componente de selección de horario en Flutter | UI del configurador de agenda | Modelo de disponibilidad, cálculo de slots, validación de conflictos |
| Autenticación y usuarios | Arquitectura de auth en Flutter con Riverpod, intercepción de navegación para GUEST | Pantallas de login, registro y bottom sheet de contraseña | JWT, estados de cuenta, `updateUser` via Supabase Auth, magic link como fallback |
| Notificaciones in-app | Suscripción Riverpod + Supabase Realtime en Flutter | Indicadores visuales, pantalla de notificaciones | Configuración de Realtime, almacenamiento de notificaciones |
| Comunicación externa | Deep link wa.me, disparo de Resend | Pantalla de selección de canal | Integración Resend, construcción de links wa.me |
| Geolocalización | Integración Google Geocoding API en Flutter | UI de selector de zona, filtros del feed | Almacenamiento de zona y ciudad en entidades |
| Infraestructura y deploy | Supabase config, Railway/Render, CI/CD | — | Variables de entorno, configuración del servidor Node |

---

## 2. Stack Tecnológico

| Capa | Tecnología | Responsable | Justificación |
|---|---|---|---|
| Mobile | Flutter (Dart) | Daniel + Emilia | Multiplataforma, dominio del equipo |
| Gestión de estado | Riverpod | Daniel | Tipado fuerte, arquitectura reactiva, compatible con capas |
| Backend | Node.js + TypeScript | Cristóbal | Experiencia del equipo, ecosistema de integraciones superior en JS/TS |
| Framework HTTP | Express o Fastify | Cristóbal | Por definir — Fastify tiene mejor rendimiento y soporte nativo de TS |
| Base de datos | Supabase (PostgreSQL) | Cristóbal + Daniel | Auth gestionado, storage, Realtime, tier gratuito generoso |
| ORM | Prisma | Cristóbal | Tipado fuerte con TS, migraciones versionadas, compatible con Supabase |
| Autenticación | Supabase Auth | Cristóbal | Magic link, JWT, gestión de sesiones lista para usar |
| Notificaciones in-app | Supabase Realtime | Cristóbal + Daniel | Suscripción en tiempo real a cambios en tablas, sin costo adicional |
| Geolocalización | Google Geocoding API | Daniel | Detección automática de región desde coordenadas GPS |
| Correo transaccional | Resend | Cristóbal | SDK nativo en TypeScript, tier gratuito suficiente para el MVP |
| WhatsApp | wa.me deep link | Cristóbal | Sin complejidad de API de Meta, simula la funcionalidad correctamente |
| Hosting backend | Railway o Render | Daniel | Instancias Node.js, tier gratuito viable, arranque rápido |
| Almacenamiento de imágenes | Supabase Storage | Cristóbal | Integrado al stack, sin servicio adicional |

---

## 3. Modelo de Geolocalización

### Jerarquía geográfica

```
Zona (Región)     → detectada automáticamente via Google Geocoding API
    └── Ciudad    → refinamiento opcional seleccionable por el usuario (segunda capa)
```

### Comportamiento en el feed

- Al abrir la app se solicita permiso de ubicación al usuario
- Si acepta: la región se detecta automáticamente via Google Geocoding API
- Si rechaza: se presenta un selector manual de región
- El filtro por ciudad es opcional, no bloqueante, y pertenece a la segunda capa
- Una publicación almacena región (obligatoria) y ciudad (opcional)

### Ordenamiento del feed

| Orden | Descripción | Disponibilidad |
|---|---|---|
| Más recientes | Publicaciones más nuevas primero | MVP — predeterminado inicial |
| Por ranking | Publicaciones mejor puntuadas primero | Segunda capa — predeterminado cuando haya datos |
| Más reservados | Por cantidad de reservas completadas | Segunda capa |

El usuario puede cambiar el ordenamiento activo desde los filtros del feed. En la segunda capa, el ordenamiento preferido se guarda en el perfil del usuario.

---

## 4. Agenda Inteligente

Una publicación tiene disponibilidad configurable con las siguientes reglas:

### Tipos de configuración soportados

| Tipo | Descripción | Ejemplo |
|---|---|---|
| Horario único para todos los días | El mismo rango horario aplica de lunes a domingo | 09:00–18:00 todos los días |
| Horario por día de la semana | Cada día puede tener su propio rango | Lunes 09–18, Sábado 10–14 |
| Días cerrados | Un día puede marcarse como no disponible | Domingo cerrado |
| Múltiples bloques por día | Un día puede tener bloques horarios separados | 09–13 y 15–19 |
| Duración del slot de reserva | Cuánto dura cada turno reservable | Slots de 30 o 60 minutos |

### Modelo de disponibilidad

```
Publication
    └── AvailabilityConfig
            ├── slot_duration_minutes: number         // duración de cada turno
            ├── same_schedule_all_days: boolean        // si es true, aplica default_schedules
            ├── default_schedules: DaySchedule[]       // bloques para días sin config específica
            └── day_overrides: DayOverride[]           // configuración específica por día de semana

DaySchedule
    ├── start_time: string    // "09:00"
    └── end_time: string      // "13:00"

DayOverride
    ├── day_of_week: enum     // MONDAY | TUESDAY | ... | SUNDAY
    ├── is_closed: boolean    // si es true, no hay disponibilidad ese día
    └── schedules: DaySchedule[]   // vacío si is_closed = true

Reservation
    ├── publication_id
    ├── requester_id
    ├── date: Date
    ├── start_time: string    // "10:00"
    ├── end_time: string      // calculado: start_time + slot_duration_minutes
    └── status: ReservationStatus
```

### Lógica de cálculo de slots disponibles para una fecha

1. Verificar si el día tiene `DayOverride` con `is_closed = true` → retornar vacío
2. Si tiene `DayOverride` con schedules → usar esos schedules
3. Si `same_schedule_all_days = true` → usar `default_schedules`
4. Generar todos los slots del día según `slot_duration_minutes`
5. Filtrar los slots que ya tienen una reserva en estado `PENDIENTE` o `COMPLETADA`

---

## 5. Estados del Sistema

### 5.1 Estados de cuenta de usuario

| Estado | Descripción | Transición |
|---|---|---|
| `GUEST` | Creado desde formulario de reserva, sin contraseña | → `ACTIVE` al crear contraseña via bottom sheet in-app |
| `ACTIVE` | Cuenta completa con contraseña establecida | Estado final estable |

**Capacidades por estado:**

| Acción | GUEST | ACTIVE |
|---|---|---|
| Ver feed | ✓ | ✓ |
| Ver detalle de publicación | ✓ | ✓ |
| Hacer una reserva | ✓ | ✓ |
| Ver "Mis reservas" | ✓ | ✓ |
| Cancelar una reserva propia | ✓ | ✓ |
| Crear publicaciones | ✗ | ✓ |
| Gestionar reservas recibidas | ✗ | ✓ |
| Editar perfil | ✗ | ✓ |

### 5.2 Estados de una reserva

```
                    ┌─────────────┐
                    │   PENDIENTE │
                    └──────┬──────┘
          ┌────────────────┼──────────────┐
          ▼                ▼              ▼
    ┌──────────┐    ┌───────────┐   ┌──────────┐
    │CANCELADA │    │ RECHAZADA │   │  FALLIDA │
    │(solicit.)│    │(publicad.)│   │(publicad)│
    └──────────┘    └───────────┘   └──────────┘

    ┌────────────┐
    │ COMPLETADA │  (publicador)
    └─────┬──────┘
          │ (segunda capa)
          ▼
 ┌──────────────────────┐
 │ PUNTUACIÓN_PENDIENTE │
 └──────────┬───────────┘
    ┌───────┴────────┐
    ▼                ▼
┌────────┐      ┌──────────┐
│PUNTUADA│      │ EXPIRADA │
└────────┘      └──────────┘
```

### 5.3 Impacto en sistema de puntajes (segunda capa)

| Estado final | ¿Genera puntuación? | ¿Afecta métricas? |
|---|---|---|
| COMPLETADA | Sí, ambos usuarios pueden puntuarse | Suma a "reservas completadas" |
| FALLIDA | No | No afecta métricas positivas |
| RECHAZADA | No | Suma a "rechazos del publicador" |
| CANCELADA | No | Suma a "cancelaciones del solicitante" |

---

## 6. Flujo Completo del Sistema

### 6.1 Flujo del solicitante

```
[App abre]
    └── Solicita permiso de geolocalización
            ├── Acepta → Google Geocoding detecta región automáticamente
            └── Rechaza → Selector manual de región
                    └── Feed filtrado por región
                        ordenado por más recientes (MVP) o ranking (segunda capa)
                            └── [Toca publicación]
                                    └── Vista de detalle
                                            ├── Información del servicio y publicador
                                            ├── Imagen de la publicación
                                            ├── Calendario de disponibilidad
                                            └── [Selecciona slot → "Reservar"]
                                                    ├── Sin cuenta / GUEST
                                                    │   └── Formulario (Nombre, Correo, Teléfono)
                                                    │           └── Cuenta creada → estado: GUEST
                                                    │                   └── Reserva → PENDIENTE
                                                    │                       └── Bottom sheet no bloqueante:
                                                    │                           "Crea tu contraseña"
                                                    │                           ├── Campos contraseña + confirmar → ACTIVE
                                                    │                           └── Omite → se intercepta al intentar navegar
                                                    └── ACTIVE
                                                            └── Datos pre-rellenados → Confirmar
                                                                    └── Reserva → PENDIENTE

[Mis reservas]
    └── Lista con estados visibles
            └── [Toca reserva en estado PENDIENTE]
                    └── Detalle + opción de cancelar
```

### 6.2 Flujo del publicador

```
[Llega notificación interna via Supabase Realtime]
    └── Indicador en el ícono de notificaciones
            └── [Abre notificación]
                    └── Detalle de la reserva recibida:
                            ├── Datos del solicitante (Nombre, Correo, Teléfono)
                            ├── Fecha y hora del slot solicitado
                            └── Acciones disponibles:
                                    ├── [Contactar por correo]
                                    │       └── Resend envía email al solicitante
                                    ├── [Contactar por WhatsApp]
                                    │       └── Deep link wa.me con mensaje pre-redactado
                                    └── [Rechazar]
                                            └── Reserva → RECHAZADA

[Gestión ocurre externamente via canal elegido]
    └── Publicador vuelve a la app → Reservas recibidas
            └── [Toca reserva]
                    └── Actualiza estado:
                            ├── COMPLETADA
                            └── FALLIDA
```

---

## 7. MVP — Funcionalidades

### 7.1 Núcleo duro (excluyente para el MVP)

| # | Funcionalidad | Daniel | Emilia | Cristóbal |
|---|---|---|---|---|
| 1 | Feed paginado filtrado por región via Google Geocoding API, con ordenamiento y filtros seleccionables | ✓ integración geo + lógica de ordenamiento + consumo API | ✓ pantalla feed + cards + controles de filtro | ✓ endpoint con filtros de zona y ordenamiento |
| 2 | Vista de detalle de publicación | ✓ navegación + consumo API | ✓ pantalla de detalle | ✓ endpoint de detalle |
| 3 | Formulario de reserva con creación de cuenta implícita (Nombre, Correo, Teléfono) | ✓ flujo de UI + lógica de estado de cuenta | ✓ pantalla del formulario | ✓ endpoint de creación de reserva + usuario GUEST |
| 4 | Contraseña diferida: bottom sheet in-app no bloqueante post-reserva con campos de contraseña, interceptado al navegar si se omite | ✓ lógica de intercepción con Riverpod | ✓ bottom sheet y modal de creación de contraseña | ✓ `updateUser({ password })` via Supabase Auth desde sesión activa |
| 5 | Reserva creada con estado PENDIENTE visible en "Mis reservas" | ✓ consumo API + UI | ✓ pantalla de mis reservas | ✓ modelo de reserva + endpoint |
| 6 | Notificación interna al publicador al recibir una reserva (Supabase Realtime) | ✓ suscripción Realtime en Flutter, indicador en UI | ✓ indicador visual de notificaciones | ✓ configuración de Realtime + almacenamiento |
| 7 | Publicador selecciona canal de contacto desde la app: correo (Resend) o WhatsApp (wa.me) | ✓ navegación + construcción de deep link | ✓ pantalla de selección de canal | ✓ envío via Resend + construcción de link wa.me con mensaje pre-redactado |
| 8 | Publicador actualiza estado de reserva: COMPLETADA, FALLIDA o RECHAZADA | ✓ UI de gestión + consumo API | ✓ pantalla de gestión (publicador) | ✓ endpoint de actualización de estado |
| 9 | Solicitante puede cancelar su reserva sin penalización | ✓ acción desde "Mis reservas" + consumo API | ✓ botón de cancelar con confirmación | ✓ endpoint de cancelación + validación de estado |
| 10 | Creación y edición de publicaciones con configurador de agenda inteligente | ✓ lógica del configurador + consumo API | ✓ pantallas de creación y edición + UI del configurador de agenda | ✓ modelo de disponibilidad + endpoints CRUD |
| 11 | Gestión de perfil propio | ✓ consumo API | ✓ pantalla de perfil y edición | ✓ endpoint de perfil |

### 7.2 Segunda capa (se implementa si el tiempo lo permite)

| # | Funcionalidad | Observación |
|---|---|---|
| 12 | Vista pública del perfil de otro usuario | Prerequisito para el sistema de puntajes |
| 13 | Sistema de puntuación mutua post-COMPLETADA | Se activa solo cuando la reserva llega a ese estado |
| 14 | Métricas de usuario: reservas completadas, ranking de confianza | Se derivan del sistema de puntuación |
| 15 | Correo recordatorio al publicador para actualizar reservas pendientes antiguas | Implementable como cron job simple en Node |
| 16 | Filtro por ciudad dentro de la región detectada | La región se detecta siempre; la ciudad es un refinamiento opcional |
| 17 | Ordenamiento personalizado del feed guardado por usuario | El predeterminado es por ranking cuando haya datos suficientes |

### 7.3 Fuera del MVP (documentado explícitamente)

| Funcionalidad | Motivo de exclusión |
|---|---|
| WhatsApp Business API real | Requiere aprobación de Meta, costo por conversación, complejidad de integración |
| Pagos en línea | Pasarela de pago, complejidad legal y técnica desproporcionada |
| Notificaciones push nativas (FCM/APNs) | Requieren cuenta Apple Developer ($99/año) y configuración de Firebase; fuera del alcance y del presupuesto |
| Penalización por cancelación | Lógica de negocio compleja — se deja planteada como mejora futura |
| Panel de administración de la plataforma | No es necesario para validar el flujo de usuario |
| Múltiples imágenes por publicación | *TODO: implementar si el storage lo permite; en MVP se permite una imagen por publicación* |
| Reservas recurrentes | Complejidad innecesaria para el MVP |

---

## 8. Mapa de Pantallas

### 8.1 Árbol de navegación

```
App
├── [Sin autenticación]
│   ├── Página-01 · Splash y onboarding de permisos
│   ├── Página-02 · Feed principal
│   ├── Página-03 · Detalle de publicación
│   ├── Página-04 · Formulario de reserva (crea cuenta GUEST)
│   ├── Página-05 · Prompt de creación de contraseña (post-reserva)
│   ├── Página-06 · Login
│   └── Página-06b · Registro completo
│
└── [Autenticada — ACTIVE]
    ├── Página-02 · Feed (con acciones adicionales)
    ├── Página-03 · Detalle de publicación
    ├── Página-04 · Formulario de reserva (datos pre-rellenados)
    ├── Página-07 · Mis reservas (solicitante)
    │   └── Página-08 · Detalle de reserva (solicitante)
    ├── Página-09 · Dashboard del publicador
    │   ├── Página-10 · Mis publicaciones
    │   │   └── Página-10b · Crear / Editar publicación
    │   └── Página-11 · Reservas recibidas
    │       └── Página-12 · Detalle de reserva (publicador)
    ├── Página-13 · Notificaciones
    ├── Página-14 · Perfil propio
    │   └── Página-14b · Editar perfil
    └── [Segunda capa] Página-15 · Perfil público de otro usuario
```

---

### 8.2 Pantallas en detalle

---

#### Página-01 · Splash y onboarding de permisos
**Responsable:** Emilia (diseño + UI) · Daniel (lógica de permisos + integración Google Geocoding)

**Contenido:**
- Logo y nombre de la app
- Solicitud de permiso de geolocalización con explicación del beneficio
- Si rechaza: selector manual de región

**Flujo de salida:** → Página-02

---

#### Página-02 · Feed principal
**Responsable:** Emilia (diseño + cards + controles de filtro) · Daniel (paginación, lógica de ordenamiento, integración API)

**Contenido:**
- Barra superior con región detectada o seleccionada (editable)
- Barra de búsqueda y filtros: categoría de servicio, ordenamiento activo
- Ordenamiento predeterminado: "Más recientes" en MVP
- Lista paginada de cards de publicaciones
- Cada card muestra: imagen, nombre del servicio, nombre del publicador, región, rating (segunda capa)

**Acciones:**
- Tocar card → Página-03
- Cambiar ordenamiento desde filtros
- Icono de notificaciones (si está autenticado) → Página-13
- Icono de perfil → Página-14 o Página-06 si no está autenticado

---

#### Página-03 · Detalle de publicación
**Responsable:** Emilia (diseño) · Daniel (consumo API, integración de agenda) · Cristóbal (endpoint de detalle + disponibilidad)

**Contenido:**
- Imagen del espacio o servicio (una en MVP)
- Nombre, descripción, categoría
- Información del publicador: nombre y rating (segunda capa)
- Calendario de disponibilidad con días disponibles marcados
- Al seleccionar un día: lista de slots horarios libres
- Botón "Reservar slot seleccionado" (activo solo si hay un slot seleccionado)

**Flujo de salida:** → Página-04

---

#### Página-04 · Formulario de reserva
**Responsable:** Emilia (diseño) · Daniel (lógica de estado de cuenta + flujo post-reserva) · Cristóbal (endpoint de creación de reserva + usuario GUEST)

**Contenido:**
- Resumen del slot seleccionado: publicación, fecha, hora
- Si no tiene cuenta: campos Nombre, Correo, Teléfono
- Si tiene cuenta ACTIVE: datos pre-rellenados, solo confirmar
- Botón "Confirmar reserva"

**Post-confirmación:**
- Cuenta nueva creada en estado GUEST → Página-05
- Usuario ya ACTIVE → Página-07

---

#### Página-05 · Bottom sheet de creación de contraseña
**Responsable:** Emilia (diseño) · Daniel (lógica de intercepción con Riverpod) · Cristóbal (`updateUser` via Supabase Auth)

**Contenido:**
- Confirmación de reserva exitosa
- Explicación del beneficio de crear contraseña
- Campo: contraseña
- Campo: confirmar contraseña
- Botón "Crear contraseña" → llama `supabase.auth.updateUser({ password })` desde la sesión GUEST activa → estado pasa a ACTIVE
- Botón "Ahora no" → cierra el sheet, continúa como GUEST

**Comportamiento:** Si el usuario omite y luego intenta una acción que requiere estado ACTIVE, Riverpod intercepta la navegación y muestra este mismo bottom sheet antes de continuar.

**Fallback para usuarios que regresan sin sesión activa:** si el usuario cerró la app sin crear contraseña y vuelve días después, no tiene sesión activa y no puede usar `updateUser`. En ese caso, la pantalla de Login ofrece "Envíame un link de acceso" → magic link al correo → entra a la app → se le presenta este mismo bottom sheet para crear contraseña. Este es el único caso donde el correo es necesario.

**Flujo de salida:** → Página-07

---

#### Página-06 · Login
**Responsable:** Emilia (diseño) · Daniel (lógica de auth con Riverpod) · Cristóbal (Supabase Auth)

**Contenido:**
- Campo correo + contraseña
- Link "Olvidé mi contraseña" → magic link de recuperación via Supabase Auth
- Link "Registrarse" → Página-06b

**Flujo de salida:** → Página-02 autenticado

---

#### Página-06b · Registro completo
**Responsable:** Emilia (diseño) · Daniel (lógica) · Cristóbal (endpoint de registro + Supabase Auth)

**Contenido:**
- Nombre, correo, teléfono, contraseña
- A diferencia del flujo de reserva, aquí la contraseña se solicita desde el inicio

**Flujo de salida:** → Página-02

---

#### Página-07 · Mis reservas (solicitante)
**Responsable:** Emilia (diseño) · Daniel (consumo API) · Cristóbal (endpoint de reservas del usuario)

**Contenido:**
- Lista de reservas agrupadas por estado: pestaña "Activas" y pestaña "Historial"
- Cada item muestra: nombre del servicio, fecha, hora, estado con color diferenciado

**Acciones:**
- Tocar reserva → Página-08

---

#### Página-08 · Detalle de reserva (solicitante)
**Responsable:** Emilia (diseño) · Daniel (consumo API + acción de cancelar) · Cristóbal (endpoint de cancelación)

**Contenido:**
- Información completa: publicación, fecha, hora, estado actual
- Si estado es PENDIENTE: botón "Cancelar reserva" con confirmación

**Acciones:**
- Cancelar → estado pasa a CANCELADA, notificación interna al publicador via Supabase Realtime

---

#### Página-09 · Dashboard del publicador
**Responsable:** Emilia (diseño) · Daniel (navegación + consumo API)

**Contenido:**
- Resumen: publicaciones activas, reservas pendientes, historial reciente
- Acceso a: Mis publicaciones y Reservas recibidas
- Botón flotante para crear nueva publicación

**Acciones:**
- → Página-10
- → Página-11
- Botón flotante → Página-10b

---

#### Página-10 · Mis publicaciones
**Responsable:** Emilia (diseño) · Daniel (consumo API) · Cristóbal (endpoints de listado y estado)

**Contenido:**
- Lista de publicaciones del usuario con estado: activa o pausada
- Acciones por publicación: editar, pausar/activar, eliminar

**Acciones:**
- Tocar publicación → Página-10b

---

#### Página-10b · Crear / Editar publicación
**Responsable:** Emilia (diseño + UI del configurador de agenda) · Daniel (lógica del configurador + consumo API) · Cristóbal (endpoints CRUD + modelo de disponibilidad)

**Contenido:**
- Nombre del servicio, descripción, categoría
- Imagen (una por publicación en MVP — *TODO: múltiples imágenes si el storage lo permite*)
- Región y ciudad de la publicación
- **Configurador de agenda inteligente:**
  - Duración de cada slot (ej: 30 o 60 minutos)
  - Toggle: "Mismo horario todos los días" / "Personalizar por día"
  - Si mismo horario: selector de rango horario único + opción de múltiples bloques
  - Si personalizado: por cada día de la semana, toggle activo/cerrado + rangos horarios con soporte de múltiples bloques por día

---

#### Página-11 · Reservas recibidas (publicador)
**Responsable:** Emilia (diseño) · Daniel (consumo API + suscripción Realtime) · Cristóbal (endpoint + Supabase Realtime)

**Contenido:**
- Lista de reservas recibidas ordenadas por estado (pendientes primero)
- Indicador visual de reservas nuevas no vistas
- Actualización en tiempo real via Supabase Realtime mientras la app está activa

**Acciones:**
- Tocar reserva → Página-12

---

#### Página-12 · Detalle de reserva (publicador)
**Responsable:** Emilia (diseño) · Daniel (lógica de canales + deep link + consumo API) · Cristóbal (endpoints de actualización de estado + Resend + construcción de link wa.me)

**Contenido:**
- Datos del solicitante: Nombre, Correo, Teléfono
- Fecha y hora del slot solicitado
- Estado actual de la reserva

**Acciones disponibles si estado es PENDIENTE:**
- "Contactar por correo" → Resend envía email al solicitante con datos de la reserva
- "Contactar por WhatsApp" → deep link wa.me con mensaje pre-redactado que incluye nombre del solicitante y slot reservado
- "Rechazar reserva" → estado pasa a RECHAZADA, notificación al solicitante
- "Marcar como completada" → estado pasa a COMPLETADA
- "Marcar como fallida" → estado pasa a FALLIDA

---

#### Página-13 · Notificaciones
**Responsable:** Emilia (diseño) · Daniel (lógica in-app + Riverpod) · Cristóbal (almacenamiento + Supabase Realtime)

**Contenido:**
- Lista cronológica de notificaciones internas
- Tipos: nueva reserva recibida, reserva cancelada por solicitante, estado de reserva actualizado

**Comportamiento:**
- Actualización en tiempo real via Supabase Realtime mientras la app está activa
- Indicador de no leídas visible desde cualquier pantalla

---

#### Página-14 · Perfil propio
**Responsable:** Emilia (diseño) · Daniel (consumo API) · Cristóbal (endpoint de perfil)

**Contenido:**
- Avatar, nombre, datos de contacto
- Estadísticas: reservas realizadas, publicaciones activas
- Rating y reservas completadas (segunda capa)
- Acceso a editar perfil
- Opción de cerrar sesión

**Acciones:**
- Editar → Página-14b

---

#### Página-14b · Editar perfil
**Responsable:** Emilia (diseño) · Daniel (consumo API) · Cristóbal (endpoint de actualización de perfil)

**Contenido:**
- Nombre, teléfono, avatar
- Cambio de contraseña via Supabase Auth

---

#### Página-15 · Perfil público (segunda capa)
**Responsable:** Emilia (diseño) · Daniel (consumo API) · Cristóbal (endpoint público de perfil)

**Contenido:**
- Nombre y avatar (sin datos de contacto privados)
- Rating y métricas de confianza
- Publicaciones activas del usuario si es publicador

---

## 9. Decisiones de Diseño

| Decisión | Resolución |
|---|---|
| Base de datos | Supabase (PostgreSQL gestionado) |
| Gestión de estado en Flutter | Riverpod |
| Geolocalización | Región detectada automáticamente via Google Geocoding API o selección manual; ciudad es refinamiento de segunda capa |
| Agenda | Múltiples slots por día, horarios configurables por día de semana, soporte de días cerrados |
| Rechazo de reserva | El publicador puede rechazar; afecta métricas de confianza en segunda capa |
| WhatsApp | Deep link wa.me con mensaje pre-redactado; sin API de Meta en el MVP |
| Contraseña | Diferida: bottom sheet in-app no bloqueante post-reserva con campos de contraseña; `updateUser` via Supabase Auth desde sesión activa. Fallback para usuarios sin sesión: magic link desde pantalla de Login |
| Cancelación | Sin penalización en MVP — se deja planteada como mejora futura |
| Notificaciones | Supabase Realtime in-app mientras la app está activa; sin notificaciones push nativas |
| Imágenes | Una imagen por publicación en MVP — *TODO: múltiples imágenes si el storage lo permite* |
| Ordenamiento del feed | Predeterminado por "Más recientes" en MVP; por ranking cuando haya datos suficientes (segunda capa) |

---

## 10. Pendientes antes de comenzar el desarrollo

| Tarea | Responsable | Urgencia |
|---|---|---|
| Definir framework HTTP backend: Express vs Fastify | Cristóbal | Alta |
| Crear proyecto en Supabase y configurar tablas base | Cristóbal + Daniel | Alta |
| Contrato de API documentado: rutas, payloads, respuestas de éxito y error | Cristóbal + Daniel | Alta — antes de que cualquiera empiece a consumir endpoints |
| Identidad visual: paleta, tipografía, logo o isotipo | Emilia | Alta — antes de comenzar la implementación de UI |
| Estructura de carpetas del proyecto Flutter con Riverpod | Daniel | Alta |
| Cuenta de Google Cloud para Geocoding API | Daniel | Media |
| Cuenta de Resend | Cristóbal | Media |

---

*Documento de trabajo interno — SIRE v2.0*
