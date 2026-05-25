import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String _selectedCategory = 'Todos';

  final List<Map<String, dynamic>> _allPublications = [
    {'title': 'Cancha de fútbol sintética', 'subtitle': 'Club Deportivo Temuco', 'category': 'Deporte', 'id': '1'},
    {'title': 'Consultorio de kinesiología', 'subtitle': 'Clínica Santa María', 'category': 'Salud', 'id': '2'},
    {'title': 'Salón para baile', 'subtitle': 'Espacio El Ático', 'category': 'Eventos', 'id': '3'},
    {'title': 'Piscina municipal', 'subtitle': 'Municipalidad de Temuco', 'category': 'Recreación', 'id': '4'},
  ];

  List<Map<String, dynamic>> get _filteredPublications {
    if (_selectedCategory == 'Todos') return _allPublications;
    return _allPublications.where((pub) => pub['category'] == _selectedCategory).toList();
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
                      color: Colors.black.withOpacity(0.1),
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
                        child: _buildGrid(context),
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
                  child: _buildList(context),
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
          const Text('SIRE', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          _buildSidebarItem(context, Icons.home, 'Inicio', () {}),
          if (!isPublisher)
            _buildSidebarItem(context, Icons.calendar_today, 'Mis Reservas', () => context.go('/my-reservations'))
          else
            _buildSidebarItem(context, Icons.bar_chart, 'Dashboard', () => context.go('/dashboard')),
          _buildSidebarItem(context, Icons.person, 'Perfil', () => context.go('/profile')),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
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
        borderRadius: isWeb ? BorderRadius.zero : const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: isWeb ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isWeb ? 'Explorar' : 'SIRE',
                style: TextStyle(color: isWeb ? const Color(0xFF1E70CD) : Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              GestureDetector(
                onTap: () => _handleNotificationsClick(context, isWeb),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isWeb ? Colors.grey.shade100 : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_none, color: isWeb ? const Color(0xFF1E70CD) : Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: isWeb ? Colors.grey : Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Temuco, La Araucanía', style: TextStyle(color: isWeb ? Colors.grey : Colors.white)),
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
      child: Row(
        children: [
          _buildChip('Todos'),
          _buildChip('Deporte'),
          _buildChip('Eventos'),
          _buildChip('Recreación'),
          _buildChip('Salud'),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E70CD) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1E70CD) : Colors.grey.shade400),
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

  Widget _buildList(BuildContext context) {
    final items = _filteredPublications;
    
    if (items.isEmpty) {
      return const Center(
        child: Text('No hay publicaciones en esta categoría', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildPlaceCard(
          item['title'],
          item['subtitle'],
          item['category'],
          onTap: () => context.push('/publication/${item['id']}'),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context) {
    final items = _filteredPublications;

    if (items.isEmpty) {
      return const Center(
        child: Text('No hay publicaciones en esta categoría', style: TextStyle(color: Colors.grey)),
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
          item['title'],
          item['subtitle'],
          item['category'],
          onTap: () => context.push('/publication/${item['id']}'),
        );
      },
    );
  }

  Widget _buildPlaceCard(String title, String subtitle, String category, {VoidCallback? onTap}) {
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
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1E70CD), borderRadius: BorderRadius.circular(12)),
                    child: Text(category, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
        decoration: BoxDecoration(color: const Color(0xFF1E70CD), borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.home, color: Colors.white),
            ),
            if (!isPublisher)
              InkWell(onTap: () => context.go('/my-reservations'), child: const Icon(Icons.calendar_today_outlined, color: Colors.white))
            else
              InkWell(onTap: () => context.go('/dashboard'), child: const Icon(Icons.bar_chart, color: Colors.white)),
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