import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_notification.dart';
import '../providers/notifications_provider.dart';

// NOTA DE MIGRACIÓN (para Emilia): esta pantalla se cableó a la nueva capa de
// dominio (entidad AppNotification + notificationsStreamProvider). El ícono, el
// color y el formato de tiempo viven ahora aquí (la entidad es pura). El cableado
// es funcional pero básico: el pulido de UX (estilo no-leído, animaciones,
// navegación fina) es tuyo. Ver claude/handoff_notificaciones_emilia.md.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E70CD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'Marcar todas como leídas',
            onPressed: () => ref
                .read(notificationActionsNotifierProvider.notifier)
                .markAllRead(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'No se pudieron cargar las notificaciones',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Text(
                  'Sin notificaciones por ahora',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _NotificationCard(
                  item: items[i],
                  onTap: () {
                    final item = items[i];
                    if (!item.read) {
                      ref
                          .read(notificationActionsNotifierProvider.notifier)
                          .markRead(item.id);
                    }
                    if (item.reservationId != null) {
                      context.push('/reservation/${item.reservationId}');
                    }
                  },
                ),
              ),
      ),
    );
  }
}

IconData _iconFor(NotificationType type) => switch (type) {
  NotificationType.newReservation => Icons.event_available,
  NotificationType.statusUpdated => Icons.check_circle_outline,
  NotificationType.reservationCancelled => Icons.cancel_outlined,
  NotificationType.system => Icons.notifications_active_outlined,
};

Color _colorFor(NotificationType type) => switch (type) {
  NotificationType.newReservation => const Color(0xFF1E70CD),
  NotificationType.statusUpdated => const Color(0xFF2E7D32),
  NotificationType.reservationCancelled => const Color(0xFFD32F2F),
  NotificationType.system => const Color(0xFFF57C00),
};

String _relativeTime(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'Hace un momento';
  if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'Hace ${d.inHours} h';
  if (d.inDays < 7) return 'Hace ${d.inDays} d';
  return '${dt.day}/${dt.month}/${dt.year}';
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(item.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          // Las no leídas resaltan con un fondo levemente teñido.
          color: item.read ? Colors.white : const Color(0xFFEAF2FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(item.type),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.read
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _relativeTime(item.createdAt),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!item.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E70CD),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
