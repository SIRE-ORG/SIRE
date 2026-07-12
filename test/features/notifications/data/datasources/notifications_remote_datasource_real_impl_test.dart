// PI-NOTIF-DS - Datasource real: historial + marcar leídas por REST (dio +
// http_mock_adapter), y la rama sin sesión del stream realtime (no toca
// Supabase). El path realtime con sesión se valida en integración, no aquí.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:sire/features/notifications/data/datasources/notifications_remote_datasource_real_impl.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_doubles.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.interceptors.add(ErrorInterceptor());
  });

  NotificationsRemoteDatasourceRealImpl dsCon({bool conUsuario = false}) =>
      NotificationsRemoteDatasourceRealImpl(
        dio: dio,
        client: supabaseWithUser(conUsuario ? fakeUser() : null),
      );

  test('getNotifications -> lista mapeada desde data[]', () async {
    adapter.onGet(
      ApiConstants.notifications,
      (s) => s.reply(200, {
        'data': [
          notificationJson(),
          notificationJson(id: 'notif-2', read: true),
        ],
        'unreadCount': 1,
      }),
      queryParameters: {'unreadOnly': false, 'page': 1, 'limit': 20},
    );

    final list = await dsCon().getNotifications();

    expect(list.length, 2);
    expect(list.first.id, 'notif-1');
    expect(list.last.read, isTrue);
  });

  test('markAsRead -> PATCH /:id/read se completa', () async {
    adapter.onPatch(
      ApiConstants.notificationRead('notif-1'),
      (s) => s.reply(200, {'id': 'notif-1', 'read': true}),
    );

    await expectLater(dsCon().markAsRead('notif-1'), completes);
  });

  test('markAllAsRead -> PATCH /read-all se completa', () async {
    adapter.onPatch(
      ApiConstants.notificationsReadAll,
      (s) => s.reply(200, {'updated': 5}),
    );

    await expectLater(dsCon().markAllAsRead(), completes);
  });

  test(
    'watchNotifications sin sesión -> stream vacío (no toca realtime)',
    () async {
      final first = await dsCon().watchNotifications().first;
      expect(first, isEmpty);
    },
  );
}
