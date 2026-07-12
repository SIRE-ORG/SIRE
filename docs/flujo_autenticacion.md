# SIRE - Flujo de autenticación de 3 fases (ANON -> GUEST -> ACTIVE)

## Objetivo

Un usuario puede navegar el feed y reservar **sin crear cuenta primero**. Solo se le pide un mínimo de datos (nombre, correo, teléfono) en el momento de su primera reserva, y la contraseña queda como un paso **opcional y diferible** después de reservar. Si vuelve a reservar sin haber creado contraseña, ahí sí se le exige activar la cuenta.

## Los 3 estados de cuenta

| Estado | ¿Dónde vive? | Cómo se llega | Cómo se detecta |
|---|---|---|---|
| **`anon`** | Solo Flutter (`AccountStatus.anon`, `lib/features/auth/domain/entities/user_profile.dart`) - **no existe en la DB ni en el `fromJson` del backend** | "Comenzar" en `welcome_screen.dart` -> `signInAnonymously()` | Hay sesión Supabase (`getCurrentUserId() != null`) pero `GET /auth/me` devuelve 404 (perfil null) |
| **`guest`** | `profiles.accountStatus = 'guest'` en la DB | Primera reserva -> formulario -> `POST /auth/register-guest` | `currentProfileProvider` resuelve un perfil con `accountStatus: guest` |
| **`active`** | `profiles.accountStatus = 'active'` en la DB | Completa el flujo de activación (correo + OTP + contraseña) -> `PATCH /auth/account-status` | `currentProfileProvider` resuelve un perfil con `accountStatus: active` |

`authStatusProvider` (`lib/features/auth/presentation/providers/auth_provider.dart`) es quien deriva estos 3 valores: perfil no-null -> su `accountStatus`; perfil null + sesión Supabase -> `anon`; sin sesión -> `null`.

## Reglas de negocio

1. **"Comenzar" (welcome)** -> sesión **anónima** de Supabase (`SignInAnonymouslyUseCase`). No pide datos.
2. **Primera reserva de un `anon`** -> formulario obligatorio nombre + teléfono + correo -> `registerGuest` -> pasa a **`guest`** -> se crea la reserva en la misma acción.
3. **Tras la reserva** se ofrece crear contraseña -> se adjunta el correo al usuario Supabase (`updateEmail`) -> **OTP al correo** (tipo `emailChange`, no `email`) -> validado -> contraseña (`updatePassword`) -> `PATCH /auth/account-status` -> **`active`**. Si el usuario pospone, queda `guest`.
4. **Un `guest` que ya tiene ≥1 reserva** debe activar su cuenta antes de reservar de nuevo. Un `guest` con 0 reservas (vino del registro directo y abandonó la activación) puede reservar sin re-llenar el formulario - su perfil ya existe.
5. La fecha de la reserva enviada al backend es **la del slot elegido** (`widget.date`, que llega por query param desde `publication_detail_screen`). No existe campo/DatePicker de fecha en el formulario de confirmación.
6. "Iniciar sesión" / registro directo (`register_screen` -> magic link -> `verify_otp_screen` tipo `email` -> `activate_account_screen`) no cambian estructuralmente; comparten pantallas con el camino de activación de un guest anónimo, parametrizadas por `otpType` (ver más abajo).

## Elegibilidad de reserva (regla 4)

`reservationEligibilityProvider` (`lib/features/reservations/presentation/providers/reservation_eligibility_provider.dart`) deriva un `ReservationEligibility` (`lib/features/reservations/domain/entities/reservation_eligibility.dart`) a partir de `authStatusProvider` y, solo para `guest`, del conteo de reservas propias:

- sin sesión o `anon` -> `needsGuestForm`
- `guest` con ≥1 reserva -> `needsActivation`
- `guest` con 0 reservas -> `allowedExistingProfile` (sin form)
- `active` -> `allowed`

`reservation_confirm_screen.dart` consulta este provider para decidir si muestra el formulario de invitado, confirma directo, o bloquea con un aviso de "Activa tu cuenta". Tras un `create()` exitoso, invalida `reservationEligibilityProvider` explícitamente - `create()` en `ReservationActionNotifier` solo invalida la lista de reservas, no la elegibilidad, así que sin esa invalidación un guest podía seguir reservando sin activar la cuenta (fix de revisión aplicado en P1, junto con un `PopScope` para que el back del sistema no cierre el modal de éxito antes de esa invalidación).

## Diagrama de secuencia

```mermaid
sequenceDiagram
    actor U as Usuario
    participant App as Flutter (AuthNotifier)
    participant SB as Supabase Auth
    participant BE as Backend REST

    Note over U,App: Fase 1 - ANON
    U->>App: "Comenzar" (welcome_screen)
    App->>SB: signInAnonymously()
    SB-->>App: sesión anónima (sin correo)
    App->>App: authStatusProvider = anon<br/>(perfil null + hay sesión)

    Note over U,App: Fase 2 - GUEST (primera reserva)
    U->>App: Confirmar reserva
    App->>App: reservationEligibilityProvider = needsGuestForm
    U->>App: Completa nombre / correo / teléfono
    App->>BE: POST /auth/register-guest {id, email, name, phone}
    BE-->>App: perfil guest creado
    App->>BE: POST /reservations {publicationId, date, startTime, endTime}
    BE-->>App: reserva creada (pending)
    App->>App: invalida reservationEligibilityProvider (regla 4)
    App-->>U: Modal "¡Reserva confirmada!"<br/>(PopScope: back del sistema no lo cierra)

    Note over U,App: Fase 3 - ACTIVE (opcional / diferible)
    U->>App: "Crear contraseña" (o "Activar cuenta" si needsActivation)
    App->>SB: updateUser(email) - adjunta correo al user anónimo
    SB-->>U: envía OTP de cambio de correo
    U->>App: Ingresa código OTP
    App->>SB: verifyOTP(email, token, type: emailChange)
    SB-->>App: correo verificado
    U->>App: Define contraseña (≥ 8 caracteres)
    App->>SB: updatePassword(password)
    App->>BE: PATCH /auth/account-status
    BE-->>App: accountStatus = active
    App->>App: invalida currentProfile/authStatus<br/>(reintento único ~400ms si el perfil llega null)

    Note over U,App: Regla 4 - guest que ya reservó antes
    U->>App: Confirmar OTRA reserva (guest, ≥1 reserva previa)
    App->>App: reservationEligibilityProvider = needsActivation
    App-->>U: oculta form/botón Confirmar; exige "Activar cuenta"
```

## Activación desde un guest anónimo vs. registro directo

El usuario Supabase de un guest anónimo sigue siendo `isAnonymous` (sin correo asociado) aunque su perfil ya sea `guest`. Por eso la activación tiene un paso extra (`updateEmail`) que el registro directo no necesita (ese ya verificó su correo al hacer `sendMagicLink` + OTP tipo `email`).

Para no duplicar pantallas, `verify_otp_screen.dart` y `activate_account_screen.dart` se comparten entre ambos caminos, parametrizados vía `extra` del router:

- `otpType: 'emailChange'` -> viene del camino de activación de un guest anónimo (`reservation_confirm_screen` -> `_goToActivation`). Usa `OtpType.emailChange` y **no** vuelve a llamar `registerGuest` (el perfil ya existe).
- Sin `otpType` (o distinto de `'emailChange'`) -> registro directo (`register_screen`). Usa `OtpType.email` y sí llama `registerGuest` tras verificar el OTP.

## Guards de navegación por estado de cuenta (P1)

`lib/core/router/app_router.dart` expone `appRouterProvider` con un `redirect` global (async, lee `authStatusProvider`) y un `refreshListenable` que reacciona a cambios de estado sin necesitar una navegación explícita (p. ej. un guest que activa su cuenta mientras sigue en la misma pantalla). Las rutas se clasifican por plantilla (`GoRouterState.fullPath`):

| Categoría | Rutas | Requisito |
|---|---|---|
| Públicas | `/`, `/location`, `/feed`, `/publication/:id`, `/login`, `/register`, `/verify-otp`, `/activate-account`, `/forgot-password` | Ninguno |
| Requiere sesión | `/publication/:id/confirm` | `anon`, `guest` o `active` (una sesión anónima basta) |
| Requiere `active` | `/dashboard`, `/my-publications`, `/publication/create`, `/publication/:id/edit`, `/received-reservations`, `/received-reservation/detail` | `AccountStatus.active` - si no, redirige a `/profile` |
| Requiere perfil | `/my-reservations`, `/reservation/:id`, `/notifications`, `/profile`, `/profile/edit` | `guest` o `active` - si no (sin sesión o `anon`), redirige a `/login` |

Si no se puede verificar el estado (p. ej. error de red al resolver `authStatusProvider`), el guard **falla cerrado**: se trata como "sin sesión verificada", nunca se deja pasar por defecto.

La tabla de decisiones (`decideRedirect`) está expuesta con `@visibleForTesting` y cubierta exhaustivamente en `test/core/router/app_router_test.dart`, junto con un par de pruebas de wiring end-to-end contra el `appRouterProvider` real.

## Archivos clave

| Capa | Archivo |
|---|---|
| Entidad | `lib/features/auth/domain/entities/user_profile.dart` (`AccountStatus`) |
| Entidad | `lib/features/reservations/domain/entities/reservation_eligibility.dart` |
| Usecase | `lib/features/auth/domain/usecases/sign_in_anonymously_usecase.dart` |
| Usecase | `lib/features/auth/domain/usecases/register_guest_usecase.dart` |
| Usecase | `lib/features/auth/domain/usecases/update_email_usecase.dart` |
| Usecase | `lib/features/auth/domain/usecases/activate_account_usecase.dart` |
| Repositorio | `lib/features/auth/data/repositories/auth_repository_impl.dart` |
| Provider | `lib/features/auth/presentation/providers/auth_provider.dart` (`AuthNotifier`, `authStatusProvider`, `currentProfileProvider`) |
| Provider | `lib/features/reservations/presentation/providers/reservation_eligibility_provider.dart` |
| Router | `lib/core/router/app_router.dart` (`appRouterProvider`, `decideRedirect`) |
| Pantallas | `welcome_screen.dart`, `reservation_confirm_screen.dart`, `verify_otp_screen.dart`, `activate_account_screen.dart` |

## Pendiente (no implementado a propósito)

Un guest cuya sesión anónima de Supabase expira o se pierde (p. ej. cambia de dispositivo) no tiene hoy un camino de "re-entrada": necesitaría `POST /auth/claim-guest` (reclamar su perfil existente por correo), que **no existe todavía en el backend**. No se implementó UI para este caso para no dejar una feature a medias visible en la demo - queda documentado como pendiente priorizado en [`api-status.md`](api-status.md#pendientes-priorizados-2026-07-12).
