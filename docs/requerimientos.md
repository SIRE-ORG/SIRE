# SIRE - Requisitos del Sistema

## Requisitos Funcionales

### RF-01 · Feed de publicaciones

| ID | Requisito | Prioridad |
|---|---|---|
| RF-01.1 | El sistema debe mostrar un feed paginado de publicaciones activas, detectando la región del usuario automáticamente o permitiendo seleccionarla manualmente | MVP |
| RF-01.2 | El sistema debe permitir ordenar el feed por fecha y filtrar por categoría (DEPORTE, EVENTOS, RECREACION, OTROS) | MVP |
| RF-01.3 | El sistema debe permitir ordenar por ranking/reservas y refinar por ciudad, guardando la preferencia en el perfil | Segunda capa |

### RF-02 · Publicaciones

| ID | Requisito | Prioridad |
|---|---|---|
| RF-02.1 | El sistema debe permitir a usuarios ACTIVE crear, editar, pausar, reactivar y eliminar publicaciones con nombre, descripción, categoría, imagen y región | MVP |
| RF-02.2 | El sistema debe mostrar el detalle completo de una publicación; las publicaciones pausadas se ocultan del feed sin afectar reservas existentes | MVP |

### RF-03 · Agenda inteligente

| ID | Requisito | Prioridad |
|---|---|---|
| RF-03.1 | El sistema debe permitir configurar horarios por día (único o diferenciado), con soporte para días cerrados y múltiples bloques horarios | MVP |
| RF-03.2 | El sistema debe calcular y mostrar los slots disponibles para una fecha, diferenciándolos visualmente de los ocupados | MVP |

### RF-04 · Autenticación y usuarios

| ID | Requisito | Prioridad |
|---|---|---|
| RF-04.1 | El sistema debe crear una cuenta GUEST implícitamente al reservar, reutilizando la cuenta si el correo ya existe, o redirigiendo al login si ya es ACTIVE | MVP |
| RF-04.2 | El sistema debe permitir al usuario GUEST establecer su contraseña desde la sesión activa, transitando a estado ACTIVE, o recibir un enlace de acceso si no tiene sesión | MVP |
| RF-04.3 | El sistema debe enviar un correo de verificación sin bloquear el flujo de reserva, y permitir a usuarios ACTIVE editar nombre, teléfono y avatar | MVP |

### RF-05 · Reservas

| ID | Requisito | Prioridad |
|---|---|---|
| RF-05.1 | El sistema debe permitir reservar un slot disponible, validando que no haya sido tomado al confirmar, y creándola en estado PENDIENTE | MVP |
| RF-05.2 | El sistema debe permitir al solicitante cancelar reservas PENDIENTES y al publicador marcarlas como COMPLETADA, FALLIDA o RECHAZADA | MVP |
| RF-05.3 | El sistema debe notificar en tiempo real a ambas partes ante cambios de estado, y permitir al publicador contactar al solicitante por correo o WhatsApp | MVP |
| RF-05.4 | El sistema debe habilitar puntuación mutua al completarse una reserva | Segunda capa |

### RF-06 · Notificaciones

| ID | Requisito | Prioridad |
|---|---|---|
| RF-06.1 | El sistema debe generar notificaciones internas ante nuevas reservas, cambios de estado y cancelaciones, propagadas en tiempo real mientras la app está activa | MVP |
| RF-06.2 | El sistema debe mostrar un indicador de no leídas visible globalmente y permitir marcarlas como leídas individual o masivamente | MVP |

---

## Requisitos No Funcionales

| ID | Área | Requisito |
|---|---|---|
| RNF-01 | Rendimiento | Feed < 2 s, slots < 1 s, notificaciones < 3 s |
| RNF-02 | Seguridad | JWT validado y con renovación automática; datos sensibles solo a partes autorizadas; contraseñas gestionadas por el servicio de auth; cumplimiento Ley 21.719 |
| RNF-03 | Infraestructura | Costo $0 en tiers gratuitos; sin soporte activo post-despliegue; notificaciones push nativas fuera del MVP |
| RNF-04 | Usabilidad | Reserva completable sin cuenta previa; creación de contraseña no bloqueante; geolocalización con explicación previa y fallback manual |
| RNF-05 | Compatibilidad | Flutter para iOS, Android y Web (WASM/Vercel); backend sin configuración propietaria |
| RNF-06 | Mantenibilidad | Arquitectura por features (data/domain/presentation); sin lógica de negocio en presentación; cambios en responses comunicados al equipo |
