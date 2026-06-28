import 'package:flutter/material.dart';

enum NotificationType { reservation, system }

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.type,
  });

  final String id;
  final String title;
  final String description;
  final String time;
  final NotificationType type;

  IconData get icon => switch (type) {
        NotificationType.reservation => Icons.calendar_today,
        NotificationType.system => Icons.notifications_active_outlined,
      };

  Color get color => switch (type) {
        NotificationType.reservation => const Color(0xFF1E70CD),
        NotificationType.system => const Color(0xFFF57C00),
      };
}
