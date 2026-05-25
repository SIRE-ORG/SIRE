import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublisher = ref.watch(isPublisherProvider);

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mi Perfil',
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildMainInfoCard(
                                    ref,
                                    isPublisher,
                                    isWeb: true,
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 2,
                                  child: _buildActionsCard(
                                    context,
                                    isPublisher,
                                  ),
                                ),
                              ],
                            ),
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
            body: Column(
              children: [
                _buildHeader(isPublisher, isWeb: false),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildModeSelector(ref, isPublisher),
                        const SizedBox(height: 32),
                        _buildMenuMobile(context, isPublisher),
                      ],
                    ),
                  ),
                ),
              ],
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
          if (!isPublisher)
            _buildSidebarItem(
              context,
              Icons.calendar_today_outlined,
              'Mis Reservas',
              () => context.go('/my-reservations'),
            )
          else
            _buildSidebarItem(
              context,
              Icons.bar_chart,
              'Dashboard',
              () => context.go('/dashboard'),
            ),
          _buildSidebarItem(
            context,
            Icons.person,
            'Perfil',
            () {},
            isActive: true,
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

  Widget _buildHeader(bool isPublisher, {required bool isWeb}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E70CD),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'María González',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'maria@correo.com',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Temuco, Chile',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          isPublisher
              ? _buildPublisherStatsMobile()
              : _buildSolicitanteStatsMobile(),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(
    WidgetRef ref,
    bool isPublisher, {
    required bool isWeb,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 4),
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'María González',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'maria@correo.com',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF94A3B8),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Temuco, La Araucanía, Chile',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isWeb) _buildModeSelectorWeb(ref, isPublisher),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 32),
          const Text(
            'Resumen de actividad',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          isPublisher ? _buildPublisherStatsWeb() : _buildSolicitanteStatsWeb(),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, bool isPublisher) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Accesos directos',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildWebActionItem(
                context,
                Icons.edit_outlined,
                'Editar Perfil',
                () => context.push('/profile/edit'),
              ),
              if (isPublisher)
                _buildWebActionItem(
                  context,
                  Icons.dashboard_outlined,
                  'Mis Publicaciones',
                  () => context.push('/my-publications'),
                )
              else
                _buildWebActionItem(
                  context,
                  Icons.calendar_today_outlined,
                  'Mis Reservas',
                  () => context.go('/my-reservations'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(color: Color(0xFFEF9A9A)),
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: const Color(0xFFFFEBEE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelectorWeb(WidgetRef ref, bool isPublisher) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildModeTab(
            ref,
            'Solicitante',
            !isPublisher,
            () => ref.read(isPublisherProvider.notifier).state = false,
          ),
          _buildModeTab(
            ref,
            'Publicador',
            isPublisher,
            () => ref.read(isPublisherProvider.notifier).state = true,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(
    WidgetRef ref,
    String title,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF1E70CD)
                    : const Color(0xFF64748B),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitanteStatsWeb() => const Row(
    children: [
      Expanded(
        child: _WebStatCard('4', 'Reservas Totales', Icons.calendar_today),
      ),
      SizedBox(width: 16),
      Expanded(
        child: _WebStatCard('2', 'Completadas', Icons.check_circle_outline),
      ),
    ],
  );
  Widget _buildPublisherStatsWeb() => const Row(
    children: [
      Expanded(child: _WebStatCard('4', 'Publicaciones', Icons.corporate_fare)),
      SizedBox(width: 16),
      Expanded(
        child: _WebStatCard('28', 'Reservas Recibidas', Icons.receipt_long),
      ),
    ],
  );

  Widget _buildWebActionItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1E70CD), size: 20),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(WidgetRef ref, bool isPublisher) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modo de Uso',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildModeTabMobile(
                ref,
                'Solicitante',
                !isPublisher,
                () => ref.read(isPublisherProvider.notifier).state = false,
              ),
              _buildModeTabMobile(
                ref,
                'Publicador',
                isPublisher,
                () => ref.read(isPublisherProvider.notifier).state = true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeTabMobile(
    WidgetRef ref,
    String title,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF1E70CD)
                    : const Color(0xFF64748B),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitanteStatsMobile() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildStatItem('4', 'Reservas'),
      _buildStatItem('2', 'Completadas'),
    ],
  );
  Widget _buildPublisherStatsMobile() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [_buildStatItem('4', 'Publicaciones')],
  );
  Widget _buildStatItem(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    ],
  );

  Widget _buildMenuMobile(BuildContext context, bool isPublisher) {
    return Column(
      children: [
        _buildMenuItem(
          Icons.edit_outlined,
          'Editar perfil',
          'Nombre, teléfono, foto',
          () => context.push('/profile/edit'),
        ),
        const SizedBox(height: 12),
        if (!isPublisher)
          _buildMenuItem(
            Icons.calendar_today_outlined,
            'Mis reservas',
            'Ver historial completo',
            () => context.go('/my-reservations'),
          )
        else
          _buildMenuItem(
            Icons.dashboard_outlined,
            'Mis publicaciones',
            'Ver publicaciones subidas',
            () => context.push('/my-publications'),
          ),
        const SizedBox(height: 12),
        _buildMenuItem(
          Icons.logout,
          'Cerrar sesión',
          '',
          () => context.go('/'),
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLogout
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isLogout ? Colors.red : const Color(0xFF1E70CD),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLogout ? Colors.red : const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
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
            if (!isPublisher)
              InkWell(
                onTap: () => context.go('/my-reservations'),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white,
                ),
              )
            else
              InkWell(
                onTap: () => context.go('/dashboard'),
                child: const Icon(
                  Icons.bar_chart_outlined,
                  color: Colors.white,
                ),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebStatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _WebStatCard(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1E70CD), size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
