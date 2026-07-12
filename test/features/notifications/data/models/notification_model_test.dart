import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/notifications/data/models/notification_model.dart';
import 'package:sire/features/notifications/domain/entities/app_notification.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('NotificationModel.fromJson (REST camelCase)', () {
    test('parsea la forma del contrato', () {
      final m = NotificationModel.fromJson(notificationJson());
      expect(m.id, 'notif-1');
      expect(m.type, 'new_reservation');
      expect(m.reservationId, 'res-1');
      expect(m.read, isFalse);
    });

    test('campos faltantes degradan a defaults seguros', () {
      final m = NotificationModel.fromJson({'id': 'x'});
      expect(m.type, 'system');
      expect(m.title, '');
      expect(m.body, '');
      expect(m.read, isFalse);
      expect(m.reservationId, isNull);
    });
  });

  group('NotificationModel.fromRealtimeRow (snake_case)', () {
    test('parsea la fila cruda de la tabla', () {
      final m = NotificationModel.fromRealtimeRow({
        'id': 'n-9',
        'type': 'status_updated',
        'title': 'T',
        'body': 'B',
        'reservation_id': 'res-9',
        'read': true,
        'created_at': '2026-06-20T12:00:00.000Z',
      });
      expect(m.id, 'n-9');
      expect(m.type, 'status_updated');
      expect(m.reservationId, 'res-9');
      expect(m.read, isTrue);
      expect(m.createdAt, '2026-06-20T12:00:00.000Z');
    });
  });

  group('toEntity', () {
    test('mapea type a enum y createdAt a DateTime', () {
      final e = NotificationModel.fromJson(
        notificationJson(
          type: 'reservation_cancelled',
          createdAt: '2026-06-20T12:00:00.000Z',
        ),
      ).toEntity();
      expect(e, isA<AppNotification>());
      expect(e.type, NotificationType.reservationCancelled);
      expect(e.createdAt, DateTime.parse('2026-06-20T12:00:00.000Z'));
    });

    test('createdAt inválido degrada a epoch', () {
      final e = NotificationModel.fromJson(
        notificationJson(createdAt: 'no-es-fecha'),
      ).toEntity();
      expect(e.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('notificationTypeFromString', () {
    test('mapea los tres tipos del contrato', () {
      expect(
        notificationTypeFromString('new_reservation'),
        NotificationType.newReservation,
      );
      expect(
        notificationTypeFromString('status_updated'),
        NotificationType.statusUpdated,
      );
      expect(
        notificationTypeFromString('reservation_cancelled'),
        NotificationType.reservationCancelled,
      );
    });

    test('tipo desconocido -> system', () {
      expect(notificationTypeFromString('lo_que_sea'), NotificationType.system);
    });
  });

  test('copyWith(read) cambia solo read', () {
    final m = NotificationModel.fromJson(notificationJson(read: false));
    final c = m.copyWith(read: true);
    expect(c.read, isTrue);
    expect(c.id, m.id);
    expect(c.title, m.title);
    expect(c.createdAt, m.createdAt);
  });
}
