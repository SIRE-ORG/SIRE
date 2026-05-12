# SIRE — Sistema Integral de Reservas Estratégicas

Aplicación móvil multiplataforma que centraliza la agenda y el agendamiento
de horas para emprendimientos locales, conectando negocios con sus clientes
a través de un feed dinámico y una agenda inteligente configurable.

---

## Problematica

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
  *configurable por día y horario* ; el cliente reserva directamente desde
  la app sin pasar por WhatsApp o canales externos.
- **Canal de comunicación unificado** — el negocio elige si contacta al
  cliente por correo o WhatsApp; *la app lo gestiona*.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Mobile | Flutter (Dart) |
| Estado | Riverpod |
| Backend | Node.js + TypeScript (Express / Fastify) |
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

🚧 En desarrollo — Proyecto académico · Universidad de la frontera - Temuco · 2026
