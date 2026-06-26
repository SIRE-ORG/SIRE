import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/notifications_datasource.dart';
import '../../data/datasources/notifications_mock_datasource_impl.dart';
import '../../data/models/notification_model.dart';

part 'notifications_provider.g.dart';

@riverpod
NotificationsDatasource notificationsDatasource(Ref ref) =>
    NotificationsMockDatasourceImpl();

@riverpod
Future<List<NotificationModel>> notifications(Ref ref) =>
    ref.watch(notificationsDatasourceProvider).getNotifications();
