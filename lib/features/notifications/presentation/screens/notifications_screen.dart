import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_notification.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsStreamProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E70CD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text(
              'Notificaciones',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unread nueva${unread > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        centerTitle: false,
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: () => ref
                  .read(notificationActionsNotifierProvider.notifier)
                  .markAllRead(),
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text('Marcar todas', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E70CD))),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(notificationsStreamProvider)),
        data: (items) => items.isEmpty ? const _EmptyState() : _NotificationList(items: items),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined, size: 40, color: Color(0xFF1E70CD)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin notificaciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando tengas actividad en tus reservas\naparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar las notificaciones',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.items});
  final List<AppNotification> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = _groupByDate(items);
    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sections.fold<int>(0, (sum, e) => sum + 1 + e.value.length),
      itemBuilder: (context, index) {
        int cursor = 0;
        for (final section in sections) {
          if (index == cursor) {
            return _SectionHeader(label: section.key);
          }
          cursor++;
          final sectionIndex = index - cursor;
          if (sectionIndex < section.value.length) {
            final item = section.value[sectionIndex];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _NotificationCard(
                item: item,
                onTap: () {
                  if (!item.read) {
                    ref.read(notificationActionsNotifierProvider.notifier).markRead(item.id);
                  }
                  if (item.reservationId != null) {
                    context.push('/reservation/${item.reservationId}');
                  }
                },
              ),
            );
          }
          cursor += section.value.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Map<String, List<AppNotification>> _groupByDate(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final result = <String, List<AppNotification>>{};
    for (final item in items) {
      final d = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      final String key;
      if (d == today) {
        key = 'Hoy';
      } else if (d == yesterday) {
        key = 'Ayer';
      } else {
        key = 'Anteriores';
      }
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.5,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: item.read ? Colors.white : const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.read ? Colors.grey.shade200 : const Color(0xFF1E70CD).withValues(alpha: 0.2),
        ),
        boxShadow: item.read
            ? null
            : [BoxShadow(color: const Color(0xFF1E70CD).withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                        child: Icon(_iconFor(item.type), color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.read ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: TextStyle(
                                color: item.read ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _relativeTime(item.createdAt),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!item.read)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E70CD),
                              shape: BoxShape.circle,
                            ),
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
