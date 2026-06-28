import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_constants.dart';
import '../models/notification_model.dart';
import 'notifications_datasource.dart';

/// Implementación real:
///   - Historial + marcar leídas → REST (`dio`); la identidad la inyecta el
///     AuthInterceptor de DioClient.
///   - Stream en vivo → Supabase Realtime directo a la tabla `notifications`
///     (primer uso de realtime en la app).
///
/// [client] es inyectable para pruebas; en producción usa el singleton
/// `Supabase.instance.client` (mismo patrón que AuthSupabaseDatasourceImpl).
class NotificationsRemoteDatasourceRealImpl implements NotificationsDatasource {
  NotificationsRemoteDatasourceRealImpl({
    required this.dio,
    SupabaseClient? client,
  }) : _injected = client;

  final Dio dio;
  final SupabaseClient? _injected;

  SupabaseClient get _client => _injected ?? Supabase.instance.client;

  @override
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get(
      ApiConstants.notifications,
      queryParameters: {'unreadOnly': unreadOnly, 'page': page, 'limit': limit},
    );
    final raw =
        ((response.data as Map<String, dynamic>)['data'] as List?) ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() {
    final uid = _client.auth.currentUser?.id;
    // Sin sesión no hay a quién suscribir: lista vacía en vez de reventar.
    if (uid == null) return Stream.value(const <NotificationModel>[]);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(NotificationModel.fromRealtimeRow).toList());
  }

  @override
  Future<void> markAsRead(String id) async {
    await dio.patch(ApiConstants.notificationRead(id));
  }

  @override
  Future<void> markAllAsRead() async {
    await dio.patch(ApiConstants.notificationsReadAll);
  }
}
