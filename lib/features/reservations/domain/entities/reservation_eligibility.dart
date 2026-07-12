/// Resultado de evaluar si el usuario actual puede confirmar una reserva
/// directamente o necesita un paso previo (regla de negocio 4 del flujo de
/// 3 fases: ANON → GUEST → ACTIVE).
///
/// - [needsGuestForm]: sin sesión, o sesión anónima sin perfil todavía.
///   Debe completar nombre/correo/teléfono (`registerGuest`) antes de crear
///   la reserva.
/// - [needsActivation]: perfil `guest` que YA tiene al menos una reserva
///   previa. Debe activar su cuenta (contraseña) antes de reservar de nuevo.
/// - [allowedExistingProfile]: perfil `guest` con cero reservas (vino del
///   registro directo y abandonó la activación). Puede reservar sin volver
///   a llenar el formulario.
/// - [allowed]: perfil `active`. Puede reservar libremente.
enum ReservationEligibility {
  needsGuestForm,
  needsActivation,
  allowedExistingProfile,
  allowed,
}
