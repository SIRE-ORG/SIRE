import '../models/notification_model.dart';

abstract class NotificationsDatasource {
  Future<List<NotificationModel>> getNotifications();
}
