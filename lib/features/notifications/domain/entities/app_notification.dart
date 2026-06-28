import 'package:equatable/equatable.dart';

/// Tipos de notificación según el contrato (api-contract.md · Notificaciones).
/// Los tres primeros los genera el backend ante eventos de reservas; `system`
/// es el bucket por defecto para tipos desconocidos / futuros.
enum NotificationType {
  newReservation,
  statusUpdated,
  reservationCancelled,
  system,
}

/// Mapea el `type` del contrato (snake_case) al enum. Default `system` para
/// valores no reconocidos (forward-compat), mismo patrón que
/// `reservationStatusFromString`.
NotificationType notificationTypeFromString(String raw) => switch (raw) {
  'new_reservation' => NotificationType.newReservation,
  'status_updated' => NotificationType.statusUpdated,
  'reservation_cancelled' => NotificationType.reservationCancelled,
  _ => NotificationType.system,
};

/// Notificación interna. Entidad de dominio pura (sin Flutter): el ícono/color
/// y el formato de tiempo son responsabilidad de la capa de presentación.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.reservationId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  /// Reserva asociada (para navegación al tocar la notificación). Null en
  /// notificaciones de sistema.
  final String? reservationId;

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    read,
    createdAt,
    reservationId,
  ];
}
