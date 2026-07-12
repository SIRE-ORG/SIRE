// PI-NOTIF (PI-PROV-10) — Providers de notificaciones con el datasource
// sustituido: stream → entidades, derivación de no leídas, y acciones de
// marcar leídas (con guard) sin excepciones sin capturar.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/network/api_flags.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/notifications/data/datasources/notifications_datasource.dart';
import 'package:sire/features/notifications/data/datasources/notifications_remote_datasource_real_impl.dart';
import 'package:sire/features/notifications/data/models/notification_model.dart';
import 'package:sire/features/notifications/presentation/providers/notifications_provider.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_doubles.dart';

void main() {
  ProviderContainer containerCon(NotificationsDatasource ds) {
    final container = ProviderContainer(
      overrides: [notificationsDatasourceProvider.overrideWithValue(ds)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PI-NOTIF-01: stream → lista de entidades', () {
    test('emite las notificaciones mapeadas', () async {
      final container = containerCon(
        StubNotificationsDatasource(
          listResponse: [NotificationModel.fromJson(notificationJson())],
        ),
      );

      final items = await container.read(notificationsStreamProvider.future);

      expect(items.single.id, 'notif-1');
      expect(container.read(notificationsStreamProvider).hasValue, isTrue);
    });

    test('error del datasource → AsyncError', () async {
      final container = containerCon(
        StubNotificationsDatasource(
          error: ServerException(
            code: 'INTERNAL_SERVER_ERROR',
            message: 'boom',
          ),
        ),
      );

      await expectLater(
        container.read(notificationsStreamProvider.future),
        throwsA(isA<ServerException>()),
      );
      expect(container.read(notificationsStreamProvider).hasError, isTrue);
    });
  });

  group('PI-NOTIF-02: unreadCount derivado del stream', () {
    test('cuenta solo las no leídas', () async {
      final container = containerCon(
        StubNotificationsDatasource(
          listResponse: [
            NotificationModel.fromJson(notificationJson(id: 'a', read: false)),
            NotificationModel.fromJson(notificationJson(id: 'b', read: true)),
            NotificationModel.fromJson(notificationJson(id: 'c', read: false)),
          ],
        ),
      );

      await container.read(notificationsStreamProvider.future);

      expect(container.read(unreadCountProvider), 2);
    });

    test('sin datos → 0', () {
      final container = containerCon(
        StubNotificationsDatasource(listResponse: const []),
      );

      expect(container.read(unreadCountProvider), 0);
    });
  });

  group('PI-NOTIF-03: acciones de marcar leídas', () {
    test('markRead delega y deja AsyncData', () async {
      final stub = StubNotificationsDatasource();
      final container = containerCon(stub);

      await container
          .read(notificationActionsNotifierProvider.notifier)
          .markRead('notif-1');

      expect(stub.markReadCalls, 1);
      expect(stub.lastMarkedId, 'notif-1');
      expect(
        container.read(notificationActionsNotifierProvider).hasValue,
        isTrue,
      );
    });

    test('markAllRead delega y deja AsyncData', () async {
      final stub = StubNotificationsDatasource();
      final container = containerCon(stub);

      await container
          .read(notificationActionsNotifierProvider.notifier)
          .markAllRead();

      expect(stub.markAllReadCalls, 1);
      expect(
        container.read(notificationActionsNotifierProvider).hasValue,
        isTrue,
      );
    });

    test('error en markRead → AsyncError (guard, no relanza)', () async {
      final container = containerCon(
        StubNotificationsDatasource(
          error: ServerException(code: 'NOT_FOUND', message: 'no existe'),
        ),
      );

      // guard: no relanza, solo deja el estado en error.
      await container
          .read(notificationActionsNotifierProvider.notifier)
          .markRead('x');

      expect(
        container.read(notificationActionsNotifierProvider).hasError,
        isTrue,
      );
    });
  });

  group('PI-NOTIF-04: flag por defecto selecciona el backend real', () {
    test('ApiFlags.useMocks es false por defecto', () {
      expect(ApiFlags.useMocks, isFalse);
    });

    test('sin overrides, el datasource es la implementación real', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000/api/v1');
      addTearDown(dotenv.clean);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(notificationsDatasourceProvider),
        isA<NotificationsRemoteDatasourceRealImpl>(),
      );
    });
  });
}
