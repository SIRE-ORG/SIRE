// PI-NOTIF-MOCK-DS — El mock simula realtime en memoria: emite snapshot,
// re-emite al marcar leídas. Es la fuente con USE_MOCKS=true.

import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/notifications/data/datasources/notifications_mock_datasource_impl.dart';

void main() {
  test('getNotifications devuelve el seed', () async {
    final ds = NotificationsMockDatasourceImpl();
    expect(await ds.getNotifications(), isNotEmpty);
  });

  test('getNotifications(unreadOnly) filtra las leídas', () async {
    final ds = NotificationsMockDatasourceImpl();
    final all = await ds.getNotifications();
    final unread = await ds.getNotifications(unreadOnly: true);
    expect(unread.every((n) => !n.read), isTrue);
    expect(unread.length, lessThan(all.length));
  });

  test('watchNotifications emite el snapshot inicial', () async {
    final ds = NotificationsMockDatasourceImpl();
    final first = await ds.watchNotifications().first;
    expect(first, isNotEmpty);
  });

  test('markAsRead muta y el stream re-emite', () async {
    final ds = NotificationsMockDatasourceImpl();
    final counts = <int>[];
    final sub = ds.watchNotifications().listen((e) => counts.add(e.length));
    await Future<void>.delayed(Duration.zero);

    await ds.markAsRead('notif-1');
    await Future<void>.delayed(Duration.zero);

    final list = await ds.getNotifications();
    expect(list.firstWhere((n) => n.id == 'notif-1').read, isTrue);
    // Al menos: emisión inicial + la re-emisión tras marcar.
    expect(counts.length, greaterThanOrEqualTo(2));

    await sub.cancel();
  });

  test('markAllAsRead deja todo leído', () async {
    final ds = NotificationsMockDatasourceImpl();
    await ds.markAllAsRead();
    final list = await ds.getNotifications();
    expect(list.every((n) => n.read), isTrue);
  });
}
