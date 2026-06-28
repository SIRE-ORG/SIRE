import '../models/notification_model.dart';
import 'notifications_datasource.dart';

class NotificationsMockDatasourceImpl implements NotificationsDatasource {
  static const _seed = [
    NotificationModel(
      id: 'notif-1',
      title: 'Nueva reserva recibida',
      description: 'Carlos Perez reservó Cancha de fútbol • Sab 2 may 13:00',
      time: 'Hace 17 min',
      type: NotificationType.reservation,
    ),
    NotificationModel(
      id: 'notif-2',
      title: 'Nueva reserva recibida',
      description: 'Ana Ruiz reservó Cancha de fútbol • Vie 15 may 09:00',
      time: 'Hace 1 hora',
      type: NotificationType.reservation,
    ),
    NotificationModel(
      id: 'notif-3',
      title: 'Reserva completada',
      description: 'Tu reserva en Consultorio de kinesiología fue completada.',
      time: 'Mar 27 abr',
      type: NotificationType.reservation,
    ),
    NotificationModel(
      id: 'notif-4',
      title: 'Reserva cancelada',
      description: 'Pedro Soto canceló su reserva del Mar 5 de may.',
      time: 'Mar 5 may',
      type: NotificationType.reservation,
    ),
    NotificationModel(
      id: 'notif-5',
      title: 'Bienvenido a SIRE',
      description: 'Explora publicaciones cerca de ti en Temuco.',
      time: 'Hace 7 días',
      type: NotificationType.system,
    ),
  ];

  @override
  Future<List<NotificationModel>> getNotifications() async => _seed;
}
