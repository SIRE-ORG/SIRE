import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../domain/entities/publication.dart';
import '../../domain/entities/publication_summary_item.dart';
import '../providers/my_publications_provider.dart';
import '../../../reservations/domain/entities/reservation.dart';
import '../../../reservations/presentation/providers/reservations_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublisher = ref.watch(isPublisherProvider);
    final pubsAsync = ref.watch(myPublicationsNotifierProvider);
    final receivedAsync = ref.watch(receivedReservationsNotifierProvider);

    final pubs = pubsAsync.value ?? [];
    final received = receivedAsync.value ?? [];

    final activeCount = pubs.where((p) => p.isActive).length;
    final pendingCount =
        received.where((r) => r.status == ReservationStatus.pending).length;
    final completedCount =
        received.where((r) => r.status == ReservationStatus.completed).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        if (isWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: Row(
              children: [
                _buildSidebar(context, isPublisher),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mi Panel',
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildTopStats(activeCount, pendingCount, completedCount),
                            const SizedBox(height: 48),
                            _buildSectionHeader(
                              'Mis publicaciones',
                              () => context.push('/my-publications'),
                            ),
                            const SizedBox(height: 16),
                            _buildMyPublicationsList(pubs),
                            const SizedBox(height: 48),
                            _buildSectionHeader(
                              'Reservas recibidas',
                              () => context.push('/received-reservations'),
                            ),
                            const SizedBox(height: 16),
                            _buildReceivedReservationsList(received, isWeb: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E70CD),
              elevation: 0,
              title: const Text(
                'Mi Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
              actions: const [NotificationBell()],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopStatsMobile(activeCount, pendingCount, completedCount),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'Mis publicaciones',
                    () => context.push('/my-publications'),
                  ),
                  const SizedBox(height: 16),
                  _buildMyPublicationsList(pubs),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'Reservas recibidas',
                    () => context.push('/received-reservations'),
                  ),
                  const SizedBox(height: 16),
                  _buildReceivedReservationsList(received, isWeb: false),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(context, isPublisher),
          );
        }
      },
    );
  }

  Widget _buildSidebar(BuildContext context, bool isPublisher) {
    return Container(
      width: 250,
      color: const Color(0xFF1E70CD),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'SIRE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 40),
          _buildSidebarItem(
            context,
            Icons.home_outlined,
            'Inicio',
            () => context.go('/feed'),
          ),
          _buildSidebarItem(
            context,
            Icons.bar_chart,
            'Dashboard',
            () {},
            isActive: true,
          ),
          _buildSidebarItem(
            context,
            Icons.person_outline,
            'Perfil',
            () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
    );
  }

  Widget _buildTopStats(int active, int pending, int completed) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '$active',
            'Publicaciones\nActivas',
            const Color(0xFFE3F2FD),
            const Color(0xFF1E70CD),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            '$pending',
            'Pendientes\npor revisar',
            const Color(0xFFFFF3E0),
            const Color(0xFFE65100),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            '$completed',
            'Completadas',
            const Color(0xFFE8F5E9),
            const Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildTopStatsMobile(int active, int pending, int completed) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '$active',
                'Publicaciones\nActivas',
                const Color(0xFFE3F2FD),
                const Color(0xFF1E70CD),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                '$pending',
                'Pendientes\npor revisar',
                const Color(0xFFFFF3E0),
                const Color(0xFFE65100),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '$completed',
                'Completadas',
                const Color(0xFFE8F5E9),
                const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text(
            'Ver todas >',
            style: TextStyle(
              color: Color(0xFF1E70CD),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyPublicationsList(List<PublicationSummaryItem> pubs) {
    if (pubs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No tienes publicaciones aún',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Column(
      children: pubs.take(3).map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPublicationItem(
            p.title,
            '${_catLabel(p.category)} - ${p.region}',
            p.isActive ? 'Activa' : 'Pausada',
            p.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
            p.isActive ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPublicationItem(
    String title,
    String subtitle,
    String status,
    Color statusBg,
    Color statusText,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedReservationsList(
    List<Reservation> reservations, {
    required bool isWeb,
  }) {
    final pending =
        reservations.where((r) => r.status == ReservationStatus.pending).toList();
    if (pending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No hay reservas pendientes',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Column(
      children: pending.take(3).map((r) {
        final (label, bg, fg) = _statusInfo(r.status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildReservationItem(
            r.applicantName ?? 'Solicitante',
            '${r.publicationTitle ?? 'Espacio'} • ${r.date} • ${r.startTime}-${r.endTime}',
            label,
            bg,
            fg,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReservationItem(
    String name,
    String details,
    String status,
    Color statusBg,
    Color statusText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isPublisher) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 80, right: 80),
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1E70CD),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              onTap: () => context.go('/feed'),
              child: const Icon(Icons.home_outlined, color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart, color: Colors.white),
            ),
            InkWell(
              onTap: () => context.go('/profile'),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

String _catLabel(PublicationCategory cat) => switch (cat) {
  PublicationCategory.deporte => 'Deporte',
  PublicationCategory.eventos => 'Eventos',
  PublicationCategory.recreacion => 'Recreación',
  PublicationCategory.otros => 'Otros',
};

(String, Color, Color) _statusInfo(ReservationStatus s) => switch (s) {
  ReservationStatus.pending => (
    'Nueva',
    Color(0xFFE3F2FD),
    Color(0xFF1E70CD),
  ),
  ReservationStatus.completed => (
    'Completada',
    Color(0xFFE8F5E9),
    Color(0xFF2E7D32),
  ),
  ReservationStatus.cancelled => (
    'Cancelada',
    Color(0xFFF1F5F9),
    Color(0xFF64748B),
  ),
  ReservationStatus.rejected => (
    'Rechazada',
    Color(0xFFFFEBEE),
    Color(0xFFC62828),
  ),
  ReservationStatus.failed => (
    'Fallida',
    Color(0xFFFFEBEE),
    Color(0xFFC62828),
  ),
};
