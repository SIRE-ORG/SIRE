import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  /// Historial paginado (REST GET /notifications).
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  });

  /// Stream en vivo (Supabase Realtime, suscripción directa a la tabla).
  /// Fuente de verdad de la vista y del conteo de no leídas.
  Stream<List<AppNotification>> watchNotifications();

  /// Marca una notificación como leída (REST PATCH /:id/read).
  Future<void> markAsRead(String id);

  /// Marca todas como leídas (REST PATCH /read-all).
  Future<void> markAllAsRead();
}
