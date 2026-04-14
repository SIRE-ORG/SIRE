# SIRE — Requisitos del Sistema

---

## Requisitos Funcionales

Los requisitos funcionales describen qué debe hacer el sistema. Se organizan por módulo y se clasifican según su prioridad: **MVP** (obligatorio para la entrega del semestre) o **Segunda capa** (se implementa si el tiempo lo permite).

---

### RF-01 · Feed de publicaciones

| ID | Requisito | Prioridad |
|---|---|---|
| RF-01.1 | El sistema debe mostrar una lista paginada de publicaciones activas filtrada por la región del usuario | MVP |
| RF-01.2 | El sistema debe detectar la región del usuario automáticamente via geolocalización del dispositivo | MVP |
| RF-01.3 | El sistema debe permitir al usuario seleccionar su región manualmente si rechaza el permiso de geolocalización | MVP |
| RF-01.4 | El sistema debe permitir ordenar el feed por fecha de creación (más recientes primero) | MVP |
| RF-01.5 | El sistema debe permitir filtrar publicaciones por categoría: DEPORTE, EVENTOS, RECREACION, OTROS | MVP |
| RF-01.6 | El sistema debe permitir ordenar el feed por ranking y por cantidad de reservas completadas | Segunda capa |
| RF-01.7 | El sistema debe permitir refinar el feed por ciudad dentro de la región detectada | Segunda capa |
| RF-01.8 | El sistema debe guardar el ordenamiento preferido del usuario en su perfil | Segunda capa |

---

### RF-02 · Publicaciones

| ID | Requisito | Prioridad |
|---|---|---|
| RF-02.1 | El sistema debe permitir a usuarios ACTIVE crear publicaciones con nombre, descripción, categoría, imagen y región | MVP |
| RF-02.2 | El sistema debe mostrar el detalle completo de una publicación incluyendo su configuración de disponibilidad | MVP |
| RF-02.3 | El sistema debe permitir al publicador editar cualquier campo de su publicación | MVP |
| RF-02.4 | El sistema debe permitir al publicador pausar y reactivar una publicación | MVP |
| RF-02.5 | El sistema debe ocultar del feed las publicaciones pausadas sin eliminarlas ni afectar reservas existentes | MVP |
| RF-02.6 | El sistema debe permitir al publicador eliminar una publicación | MVP |
| RF-02.7 | El sistema debe aceptar una imagen por publicación almacenada en Supabase Storage | MVP |

---

### RF-03 · Agenda inteligente

| ID | Requisito | Prioridad |
|---|---|---|
| RF-03.1 | El sistema debe permitir configurar un horario único aplicable a todos los días de la semana | MVP |
| RF-03.2 | El sistema debe permitir configurar horarios distintos por cada día de la semana | MVP |
| RF-03.3 | El sistema debe permitir marcar días específicos como cerrados | MVP |
| RF-03.4 | El sistema debe permitir configurar múltiples bloques horarios por día | MVP |
| RF-03.5 | El sistema debe permitir configurar la duración de cada slot de reserva | MVP |
| RF-03.6 | El sistema debe calcular y retornar los slots disponibles para una fecha específica, excluyendo los ya reservados | MVP |
| RF-03.7 | El sistema debe mostrar los slots ocupados visualmente diferenciados de los disponibles | MVP |

---

### RF-04 · Autenticación y usuarios

| ID | Requisito | Prioridad |
|---|---|---|
| RF-04.1 | El sistema debe crear una cuenta GUEST implícitamente al momento de completar el formulario de reserva | MVP |
| RF-04.2 | El sistema debe identificar usuarios por correo electrónico como identificador único | MVP |
| RF-04.3 | El sistema debe reutilizar la cuenta existente si el correo ya está registrado como GUEST | MVP |
| RF-04.4 | El sistema debe redirigir al login si el correo ya tiene una cuenta ACTIVE al intentar reservar | MVP |
| RF-04.5 | El sistema debe permitir al usuario GUEST establecer su contraseña desde la sesión activa via bottom sheet in-app | MVP |
| RF-04.6 | El sistema debe transicionar el estado de la cuenta de GUEST a ACTIVE al establecer la contraseña | MVP |
| RF-04.7 | El sistema debe ofrecer un magic link al correo como mecanismo de acceso para usuarios GUEST sin sesión activa | MVP |
| RF-04.8 | El sistema debe enviar un correo de verificación al crear una cuenta, sin bloquear el flujo de reserva | MVP |
| RF-04.9 | El sistema debe permitir a los usuarios ACTIVE editar su nombre, teléfono y avatar | MVP |
| RF-04.10 | El sistema debe exponer un perfil público de usuario sin datos de contacto | Segunda capa |

---

### RF-05 · Reservas

| ID | Requisito | Prioridad |
|---|---|---|
| RF-05.1 | El sistema debe permitir al solicitante reservar un slot disponible de una publicación | MVP |
| RF-05.2 | El sistema debe crear la reserva en estado PENDIENTE y hacerla visible en "Mis reservas" del solicitante | MVP |
| RF-05.3 | El sistema debe validar que el slot no haya sido reservado por otro usuario en el momento de confirmar | MVP |
| RF-05.4 | El sistema debe permitir al solicitante cancelar una reserva en estado PENDIENTE sin penalización | MVP |
| RF-05.5 | El sistema debe permitir al publicador marcar una reserva como COMPLETADA, FALLIDA o RECHAZADA | MVP |
| RF-05.6 | El sistema debe notificar al publicador en tiempo real cuando recibe una nueva reserva | MVP |
| RF-05.7 | El sistema debe notificar al solicitante en tiempo real cuando el estado de su reserva cambia | MVP |
| RF-05.8 | El sistema debe permitir al publicador contactar al solicitante por correo electrónico via Resend | MVP |
| RF-05.9 | Flutter debe construir el deep link de WhatsApp localmente con los datos del solicitante | MVP |
| RF-05.10 | El sistema debe habilitar puntuación mutua entre solicitante y publicador al completarse una reserva | Segunda capa |

---

### RF-06 · Notificaciones

| ID | Requisito | Prioridad |
|---|---|---|
| RF-06.1 | El sistema debe generar una notificación interna al publicador cuando recibe una reserva nueva | MVP |
| RF-06.2 | El sistema debe generar una notificación interna al solicitante cuando el estado de su reserva cambia | MVP |
| RF-06.3 | El sistema debe generar una notificación interna al publicador cuando el solicitante cancela su reserva | MVP |
| RF-06.4 | El sistema debe mostrar un indicador de notificaciones no leídas visible desde cualquier pantalla | MVP |
| RF-06.5 | El sistema debe permitir marcar notificaciones individuales o todas como leídas | MVP |
| RF-06.6 | Las notificaciones deben propagarse en tiempo real via Supabase Realtime mientras la app está activa | MVP |

---

## Requisitos No Funcionales

Los requisitos no funcionales describen cómo debe comportarse el sistema, independientemente de las funcionalidades específicas.

---

### RNF-01 · Rendimiento

| ID | Requisito |
|---|---|
| RNF-01.1 | El feed debe cargar la primera página en menos de 2 segundos en condiciones normales de red |
| RNF-01.2 | Los slots disponibles de una publicación deben calcularse y retornarse en menos de 1 segundo |
| RNF-01.3 | Las notificaciones en tiempo real deben llegar al cliente en menos de 3 segundos desde que ocurre el evento |

---

### RNF-02 · Seguridad

| ID | Requisito |
|---|---|
| RNF-02.1 | Todos los endpoints protegidos deben validar el JWT emitido por Supabase Auth antes de procesar el request |
| RNF-02.2 | Los datos sensibles del usuario (correo, teléfono) deben exponerse únicamente a las partes autorizadas: el propio usuario y el publicador de una reserva recibida |
| RNF-02.3 | El JWT debe renovarse automáticamente via Supabase Auth sin intervención del usuario |
| RNF-02.4 | Las contraseñas deben gestionarse exclusivamente a través de Supabase Auth, sin almacenarse en texto plano en ninguna capa |
| RNF-02.5 | El sistema debe cumplir con los principios de mínima recolección de datos y consentimiento explícito establecidos en la Ley 21.719 |

---

### RNF-03 · Disponibilidad e infraestructura

| ID | Requisito |
|---|---|
| RNF-03.1 | El costo operativo de la infraestructura durante el semestre debe ser de $0, utilizando los tiers gratuitos de Supabase, Render, Resend y Google Geocoding API |
| RNF-03.2 | El sistema debe operar sin soporte técnico activo una vez desplegado |
| RNF-03.3 | Las notificaciones en tiempo real solo están activas mientras la app está abierta; no se requieren notificaciones push nativas en el MVP |

---

### RNF-04 · Usabilidad

| ID | Requisito |
|---|---|
| RNF-04.1 | El flujo de reserva completo debe poder completarse sin que el usuario tenga una cuenta previamente creada |
| RNF-04.2 | La creación de contraseña debe ser no bloqueante: el usuario puede omitirla y completarla después |
| RNF-04.3 | La app debe solicitar el permiso de geolocalización con una explicación del beneficio antes de pedirlo al sistema operativo |
| RNF-04.4 | La app debe funcionar correctamente si el usuario rechaza el permiso de geolocalización, ofreciendo selección manual de región |

---

### RNF-05 · Compatibilidad

| ID | Requisito |
|---|---|
| RNF-05.1 | La aplicación móvil debe funcionar en iOS y Android desde una única base de código en Flutter |
| RNF-05.2 | La aplicación debe compilar a Web (Flutter Web / WASM) para el despliegue en Vercel en el hito 6 |
| RNF-05.3 | El backend debe ejecutarse en Node.js con TypeScript sobre Fastify, desplegado en Render |

---

### RNF-06 · Mantenibilidad

| ID | Requisito |
|---|---|
| RNF-06.1 | El proyecto Flutter debe seguir la arquitectura por features con capas internas (data, domain, presentation) |
| RNF-06.2 | El estado de implementación de cada endpoint debe mantenerse actualizado en `docs/api-status.md` |
| RNF-06.3 | Cualquier cambio en la estructura de un response del backend debe comunicarse al equipo antes de implementarse |
| RNF-06.4 | El código de la capa de presentación no debe contener lógica de negocio ni llamadas directas a la API |

---
