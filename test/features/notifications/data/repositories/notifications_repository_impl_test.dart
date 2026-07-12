// PI-NOTIF-REPO - El repositorio mapea los modelos a entidades de dominio
// (en lista y en stream) y delega las acciones en el datasource.

import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/notifications/data/models/notification_model.dart';
import 'package:sire/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:sire/features/notifications/domain/entities/app_notification.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_doubles.dart';

void main() {
  test('getNotifications mapea models a entidades', () async {
    final repo = NotificationsRepositoryImpl(
      datasource: StubNotificationsDatasource(
        listResponse: [NotificationModel.fromJson(notificationJson())],
      ),
    );

    final list = await repo.getNotifications();

    expect(list.single, isA<AppNotification>());
    expect(list.single.type, NotificationType.newReservation);
  });

  test('watchNotifications mapea el stream a entidades', () async {
    final repo = NotificationsRepositoryImpl(
      datasource: StubNotificationsDatasource(
        listResponse: [
          NotificationModel.fromJson(notificationJson(read: true)),
        ],
      ),
    );

    final first = await repo.watchNotifications().first;

    expect(first.single, isA<AppNotification>());
    expect(first.single.read, isTrue);
  });

  test('markAsRead delega en el datasource', () async {
    final stub = StubNotificationsDatasource();
    final repo = NotificationsRepositoryImpl(datasource: stub);

    await repo.markAsRead('notif-1');

    expect(stub.markReadCalls, 1);
    expect(stub.lastMarkedId, 'notif-1');
  });

  test('markAllAsRead delega en el datasource', () async {
    final stub = StubNotificationsDatasource();
    final repo = NotificationsRepositoryImpl(datasource: stub);

    await repo.markAllAsRead();

    expect(stub.markAllReadCalls, 1);
  });
}
