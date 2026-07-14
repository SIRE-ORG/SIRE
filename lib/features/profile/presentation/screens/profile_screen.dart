import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/widgets/tab_back_scope.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../publications/presentation/providers/my_publications_provider.dart';
import '../../../reservations/domain/entities/reservation.dart';
import '../../../reservations/presentation/providers/reservations_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublisher = ref.watch(isPublisherProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    // Sin perfil (sesión anónima que nunca completó su registro, o sin
    // sesión): empty-state amable en vez del layout completo, que asume
    // datos de un perfil real (reservas, publicaciones, editar perfil). El
    // guard de /profile en app_router.dart ya permite entrar acá con una
    // sesión anónima (antes redirigía en seco a /login).
    if (profile == null) {
      return TabBackToFeed(child: _buildEmptyState(context));
    }

    // authStatusProvider distingue "anónimo" (sesión sin perfil) de
    // "cargando" (todavía sin resolver); el perfil solo conoce guest/active.
    final status = profile.accountStatus;
    final nombre = profile.name.isNotEmpty ? profile.name : profile.email;
    final email = profile.email;

    final avatarUrl = profile.avatarUrl;
    final pubsAsync = ref.watch(myPublicationsNotifierProvider);
    final myResAsync = ref.watch(myReservationsNotifierProvider);
    final receivedAsync = ref.watch(receivedReservationsNotifierProvider);
    final myRes = myResAsync.value ?? [];
    final received = receivedAsync.value ?? [];

    // hasValue (no .value directo) distingue "todavía sin cargar" de "cero
    // real": antes se colapsaba con `?? 0` y el panel mostraba estadísticas
    // en cero al entrar hasta que otra pantalla disparaba el mismo fetch.
    final pubCount = pubsAsync.hasValue ? pubsAsync.value!.length : null;
    final totalReservations = myResAsync.hasValue ? myRes.length : null;
    final completedCount = myResAsync.hasValue
        ? myRes.where((r) => r.status == ReservationStatus.completed).length
        : null;
    final receivedCount = receivedAsync.hasValue ? received.length : null;

    return TabBackToFeed(
      child: LayoutBuilder(
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
                                      context,
                                      ref,
                                      isPublisher,
                                      nombre: nombre,
                                      email: email,
                                      status: status,
                                      isWeb: true,
                                      avatarUrl: avatarUrl,
                                      pubCount: pubCount,
                                      receivedCount: receivedCount,
                                      totalReservations: totalReservations,
                                      completedCount: completedCount,
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    flex: 2,
                                    child: _buildActionsCard(
                                      context,
                                      ref,
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
                  _buildHeader(
                    context,
                    isPublisher,
                    isWeb: false,
                    nombre: nombre,
                    email: email,
                    status: status,
                    avatarUrl: avatarUrl,
                    pubCount: pubCount,
                    receivedCount: receivedCount,
                    totalReservations: totalReservations,
                    completedCount: completedCount,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildModeSelector(ref, isPublisher),
                          const SizedBox(height: 32),
                          _buildMenuMobile(context, ref, isPublisher),
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
      ),
    );
  }

  /// Empty-state para una sesión sin perfil (anónima que nunca completó su
  /// registro, o sin sesión todavía resuelta). Antes de este fix, el guard
  /// de `/profile` ni siquiera dejaba llegar acá a un anónimo (redirect en
  /// seco a /login); ahora sí, y esta pantalla lo recibe con un mensaje
  /// honesto en vez de asumir datos de un perfil que no existe.
  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 72,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aún no tienes una cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crea una cuenta o inicia sesión para ver tu perfil, tus '
                  'reservas y más.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E70CD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Crear cuenta o iniciar sesión',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  /// Chip de estado de cuenta: 3 valores posibles (Anónimo / Invitado /
  /// Cuenta activa) más el intermedio "Cargando…" mientras resuelve.
  Widget _buildAccountBadge(AccountStatus? status) {
    final (String label, Color bg, Color fg, IconData icon) = switch (status) {
      AccountStatus.active => (
        'Cuenta activa',
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
        Icons.verified_user,
      ),
      AccountStatus.guest => (
        'Invitado',
        const Color(0xFFFFF3E0),
        const Color(0xFF7A4B00),
        Icons.hourglass_bottom,
      ),
      AccountStatus.anon => (
        'Anónimo',
        const Color(0xFFE2E8F0),
        const Color(0xFF475569),
        Icons.person_outline,
      ),
      null => (
        'Cargando…',
        const Color(0xFFE2E8F0),
        const Color(0xFF475569),
        Icons.sync,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isPublisher, {
    required bool isWeb,
    required String nombre,
    required String email,
    required AccountStatus? status,
    String? avatarUrl,
    required int? pubCount,
    required int? receivedCount,
    required int? totalReservations,
    required int? completedCount,
  }) {
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
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, a, b) => const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status == AccountStatus.anon && email.isEmpty
                          ? 'Navegando sin registro'
                          : email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAccountBadge(status),
                  ],
                ),
              ),
            ],
          ),
          if (status == AccountStatus.anon) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/register'),
                icon: const Icon(Icons.edit_note, color: Colors.white),
                label: const Text(
                  'Completar registro',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          isPublisher
              ? _buildPublisherStatsMobile(pubCount)
              : _buildSolicitanteStatsMobile(totalReservations, completedCount),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(
    BuildContext context,
    WidgetRef ref,
    bool isPublisher, {
    required bool isWeb,
    required String nombre,
    required String email,
    required AccountStatus? status,
    String? avatarUrl,
    required int? pubCount,
    required int? receivedCount,
    required int? totalReservations,
    required int? completedCount,
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
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, a, b) => const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF94A3B8),
                        ),
                      )
                    : const Icon(
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
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      status == AccountStatus.anon && email.isEmpty
                          ? 'Navegando sin registro'
                          : email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildAccountBadge(status),
                        if (status == AccountStatus.anon) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () => context.go('/register'),
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text(
                              'Completar registro',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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
          isPublisher
              ? _buildPublisherStatsWeb(pubCount, receivedCount)
              : _buildSolicitanteStatsWeb(totalReservations, completedCount),
        ],
      ),
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    WidgetRef ref,
    bool isPublisher,
  ) {
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
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/');
            },
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

  Widget _buildSolicitanteStatsWeb(int? total, int? completed) => Row(
    children: [
      Expanded(
        child: _WebStatCard(total, 'Reservas Totales', Icons.calendar_today),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _WebStatCard(
          completed,
          'Completadas',
          Icons.check_circle_outline,
        ),
      ),
    ],
  );
  Widget _buildPublisherStatsWeb(int? pubs, int? received) => Row(
    children: [
      Expanded(
        child: _WebStatCard(pubs, 'Publicaciones', Icons.corporate_fare),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _WebStatCard(received, 'Reservas Recibidas', Icons.receipt_long),
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

  Widget _buildSolicitanteStatsMobile(int? total, int? completed) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildStatItem(total, 'Reservas'),
      _buildStatItem(completed, 'Completadas'),
    ],
  );
  Widget _buildPublisherStatsMobile(int? pubs) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [_buildStatItem(pubs, 'Publicaciones')],
  );
  // value == null: dato todavía sin cargar (ver comentario en el build()
  // sobre hasValue); se muestra un loading en vez de un "0" falso.
  Widget _buildStatItem(int? value, String label) => Column(
    children: [
      value == null
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              '$value',
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

  Widget _buildMenuMobile(
    BuildContext context,
    WidgetRef ref,
    bool isPublisher,
  ) {
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
        _buildMenuItem(Icons.logout, 'Cerrar sesión', '', () async {
          await ref.read(authNotifierProvider.notifier).signOut();
          if (context.mounted) context.go('/');
        }, isLogout: true),
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
  // value == null: dato todavía sin cargar (ver comentario en el build()
  // sobre hasValue); se muestra un loading en vez de un "0" falso.
  final int? value;
  final String label;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                value == null
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '$value',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
