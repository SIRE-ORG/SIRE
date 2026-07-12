import 'dart:async';

import '../models/notification_model.dart';
import 'notifications_datasource.dart';

/// Mock con estado en memoria que simula el realtime: `watchNotifications`
/// emite el snapshot actual y luego cada cambio (mark-read) re-emite. Permite
/// demostrar y testear toda la pipeline (lista + badge + marcar leídas) sin
/// backend, con `USE_MOCKS=true`.
class NotificationsMockDatasourceImpl implements NotificationsDatasource {
  NotificationsMockDatasourceImpl() : _items = _seed();

  final List<NotificationModel> _items;
  final _controller = StreamController<List<NotificationModel>>.broadcast();

  static List<NotificationModel> _seed() {
    final now = DateTime.now();
    String iso(Duration ago) => now.subtract(ago).toIso8601String();
    return [
      NotificationModel(
        id: 'notif-1',
        type: 'new_reservation',
        title: 'Nueva reserva recibida',
        body: 'Carlos Pérez reservó Cancha de fútbol • Sáb 2 may 13:00',
        reservationId: 'res-1',
        read: false,
        createdAt: iso(const Duration(minutes: 17)),
      ),
      NotificationModel(
        id: 'notif-2',
        type: 'new_reservation',
        title: 'Nueva reserva recibida',
        body: 'Ana Ruiz reservó Cancha de fútbol • Vie 15 may 09:00',
        reservationId: 'res-2',
        read: false,
        createdAt: iso(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notif-3',
        type: 'status_updated',
        title: 'Reserva completada',
        body: 'Tu reserva en Consultorio de kinesiología fue completada.',
        reservationId: 'res-3',
        read: true,
        createdAt: iso(const Duration(days: 2)),
      ),
      NotificationModel(
        id: 'notif-4',
        type: 'reservation_cancelled',
        title: 'Reserva cancelada',
        body: 'Pedro Soto canceló su reserva del Mar 5 de may.',
        reservationId: 'res-4',
        read: true,
        createdAt: iso(const Duration(days: 5)),
      ),
      NotificationModel(
        id: 'notif-5',
        type: 'system',
        title: 'Bienvenido a SIRE',
        body: 'Explora publicaciones cerca de ti en Temuco.',
        read: true,
        createdAt: iso(const Duration(days: 7)),
      ),
    ];
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    return unreadOnly
        ? _items.where((n) => !n.read).toList()
        : List<NotificationModel>.from(_items);
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<void> markAsRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i != -1) {
      _items[i] = _items[i].copyWith(read: true);
      _emit();
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(List.unmodifiable(_items));
  }
}
