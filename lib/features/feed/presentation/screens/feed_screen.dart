import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../publications/domain/entities/publication.dart';
import '../../domain/entities/publication_summary.dart';
import '../providers/feed_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String _selectedCategory = 'Todos';

  // Solo categorías que el backend acepta (enum congelado vía Zod:
  // DEPORTE|EVENTOS|RECREACION|OTROS, ver docs/api-status.md). Un chip fuera
  // de este set haría que `_categoryEnum` devuelva null y `_filterLocally`
  // lo trate como "sin filtro" (mostraba todo bajo el chip "Salud").
  static const _categories = [
    'Todos',
    'Deporte',
    'Eventos',
    'Recreación',
    'Otros',
  ];

  PublicationCategory? _categoryEnum(String label) {
    switch (label) {
      case 'Deporte':
        return PublicationCategory.deporte;
      case 'Eventos':
        return PublicationCategory.eventos;
      case 'Recreación':
        return PublicationCategory.recreacion;
      case 'Otros':
        return PublicationCategory.otros;
      default:
        return null;
    }
  }

  String _categoryLabel(PublicationCategory cat) {
    switch (cat) {
      case PublicationCategory.deporte:
        return 'Deporte';
      case PublicationCategory.eventos:
        return 'Eventos';
      case PublicationCategory.recreacion:
        return 'Recreación';
      case PublicationCategory.otros:
        return 'Otros';
    }
  }

  List<PublicationSummary> _filterLocally(List<PublicationSummary> items) {
    if (_selectedCategory == 'Todos') return items;
    final cat = _categoryEnum(_selectedCategory);
    if (cat == null) return items;
    return items.where((p) => p.category == cat).toList();
  }

  void _handleNotificationsClick(BuildContext context, bool isWeb) {
    if (!isWeb) {
      context.push('/notifications');
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 80, right: 32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 380,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const NotificationsScreen(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPublisher = ref.watch(isPublisherProvider);
    final feedAsync = ref.watch(feedNotifierProvider);

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
                  child: Column(
                    children: [
                      _buildHeader(context, isWeb: true),
                      _buildCategories(),
                      Expanded(
                        child: feedAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1E70CD),
                            ),
                          ),
                          error: (e, _) => _buildError(context),
                          data: (feed) =>
                              _buildGrid(context, _filterLocally(feed.items)),
                        ),
                      ),
                    ],
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
                _buildHeader(context, isWeb: false),
                _buildCategories(),
                Expanded(
                  child: feedAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E70CD),
                      ),
                    ),
                    error: (e, _) => _buildError(context),
                    data: (feed) =>
                        _buildList(context, _filterLocally(feed.items)),
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

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No se pudieron cargar las publicaciones',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.invalidate(feedNotifierProvider),
            child: const Text('Reintentar'),
          ),
        ],
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
          _buildSidebarItem(context, Icons.home, 'Inicio', () {}),
          if (!isPublisher)
            _buildSidebarItem(
              context,
              Icons.calendar_today,
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
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isWeb}) {
    return Container(
      padding: EdgeInsets.only(
        top: isWeb ? 40 : 60,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: isWeb ? Colors.white : const Color(0xFF1E70CD),
        borderRadius: isWeb
            ? BorderRadius.zero
            : const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
        boxShadow: isWeb
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isWeb ? 'Explorar' : 'SIRE',
                style: TextStyle(
                  color: isWeb ? const Color(0xFF1E70CD) : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              NotificationBell(
                color: isWeb ? const Color(0xFF1E70CD) : Colors.white,
                onPressed: () => _handleNotificationsClick(context, isWeb),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: isWeb ? Colors.grey : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Temuco, La Araucanía',
                style: TextStyle(color: isWeb ? Colors.grey : Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(
              color: isWeb ? const Color(0xFFF5F5F5) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar publicaciones...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(children: _categories.map(_buildChip).toList()),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = label);
        ref
            .read(feedNotifierProvider.notifier)
            .setCategory(_categoryEnum(label));
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E70CD) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E70CD) : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<PublicationSummary> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No hay publicaciones en esta categoría',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildPlaceCard(
          item.title,
          item.ownerName,
          _categoryLabel(item.category),
          imageUrl: item.imageUrl,
          onTap: () => context.push('/publication/${item.id}'),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<PublicationSummary> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No hay publicaciones en esta categoría',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildPlaceCard(
          item.title,
          item.ownerName,
          _categoryLabel(item.category),
          imageUrl: item.imageUrl,
          onTap: () => context.push('/publication/${item.id}'),
        );
      },
    );
  }

  Widget _buildPlaceCard(
    String title,
    String subtitle,
    String category, {
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(Icons.image, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E70CD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Colors.white),
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
