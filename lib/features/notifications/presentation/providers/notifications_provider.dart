import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/notifications_datasource.dart';
import '../../data/datasources/notifications_mock_datasource_impl.dart';
import '../../data/datasources/notifications_remote_datasource_real_impl.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/watch_notifications_usecase.dart';

part 'notifications_provider.g.dart';

// ---------------------------------------------------------------------------
// Infraestructura
// ---------------------------------------------------------------------------

@riverpod
NotificationsDatasource notificationsDatasource(Ref ref) =>
    ApiFlags.useRealBackend
    ? NotificationsRemoteDatasourceRealImpl(dio: DioClient.createSync().dio)
    : NotificationsMockDatasourceImpl();

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepositoryImpl(
      datasource: ref.watch(notificationsDatasourceProvider),
    );

// ---------------------------------------------------------------------------
// Vista en vivo: el stream realtime es la fuente de verdad de la lista y del
// conteo de no leídas.
// ---------------------------------------------------------------------------

@riverpod
Stream<List<AppNotification>> notificationsStream(Ref ref) =>
    WatchNotificationsUseCase(
      ref.watch(notificationsRepositoryProvider),
    ).call();

@riverpod
int unreadCount(Ref ref) {
  final items = ref.watch(notificationsStreamProvider).valueOrNull;
  return items?.where((n) => !n.read).length ?? 0;
}

// ---------------------------------------------------------------------------
// Acciones: marcar leídas. El stream re-emite con read=true y la UI se
// actualiza sola.
// ---------------------------------------------------------------------------

@riverpod
class NotificationActionsNotifier extends _$NotificationActionsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> markRead(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => MarkNotificationReadUseCase(
        ref.read(notificationsRepositoryProvider),
      ).call(id: id),
    );
  }

  Future<void> markAllRead() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => MarkAllNotificationsReadUseCase(
        ref.read(notificationsRepositoryProvider),
      ).call(),
    );
  }
}
