import '../../domain/entities/app_notification.dart';

/// DTO puro (sin Flutter). Tiene dos parsers porque la fuente difiere:
///   - [fromJson]: respuesta REST `GET /notifications` (camelCase).
///   - [fromRealtimeRow]: fila cruda de la tabla vía Supabase Realtime
///     (snake_case). Mismo patrón que `UserProfileModel.fromBackendProfile`.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.reservationId,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;
  final String? reservationId;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      reservationId: json['reservationId'] as String?,
    );
  }

  /// Fila de la tabla `notifications` (columnas snake_case).
  factory NotificationModel.fromRealtimeRow(Map<String, dynamic> row) {
    return NotificationModel(
      id: row['id'] as String,
      type: row['type'] as String? ?? 'system',
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      read: row['read'] as bool? ?? false,
      createdAt: row['created_at'] as String? ?? '',
      reservationId: row['reservation_id'] as String?,
    );
  }

  NotificationModel copyWith({bool? read}) => NotificationModel(
    id: id,
    type: type,
    title: title,
    body: body,
    read: read ?? this.read,
    createdAt: createdAt,
    reservationId: reservationId,
  );

  AppNotification toEntity() => AppNotification(
    id: id,
    type: notificationTypeFromString(type),
    title: title,
    body: body,
    read: read,
    createdAt:
        DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
    reservationId: reservationId,
  );
}
