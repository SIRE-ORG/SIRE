import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';

class MyPublicationsScreen extends ConsumerStatefulWidget {
  const MyPublicationsScreen({super.key});

  @override
  ConsumerState<MyPublicationsScreen> createState() =>
      _MyPublicationsScreenState();
}

class _MyPublicationsScreenState extends ConsumerState<MyPublicationsScreen> {
  final List<Map<String, dynamic>> _publications = [
    {
      'id': '1',
      'title': 'Cancha de fútbol sintética',
      'subtitle': 'Deporte - Temuco',
      'status': 'Activa',
    },
    {
      'id': '2',
      'title': 'Consultorio de kinesiología',
      'subtitle': 'Salud - Temuco',
      'status': 'Activa',
    },
    {
      'id': '3',
      'title': 'Salon para baile',
      'subtitle': 'Eventos - Temuco',
      'status': 'Pausada',
    },
  ];

  void _toggleStatus(int index) {
    setState(() {
      if (_publications[index]['status'] == 'Activa') {
        _publications[index]['status'] = 'Pausada';
      } else {
        _publications[index]['status'] = 'Activa';
      }
    });
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
                      _buildHeader(context, isWeb),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: Wrap(
                                spacing: 24,
                                runSpacing: 24,
                                children: _publications.asMap().entries.map((
                                  entry,
                                ) {
                                  int index = entry.key;
                                  var pub = entry.value;
                                  return SizedBox(
                                    width: 450,
                                    child: _buildPublicationCard(pub, index),
                                  );
                                }).toList(),
                              ),
                            ),
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

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Column(
            children: [
              _buildHeader(context, isWeb),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _publications.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPublicationCard(entry.value, entry.key),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context, isPublisher),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/publication/create'),
            backgroundColor: const Color(0xFF1E70CD),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
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
            () => context.go('/dashboard'),
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

  Widget _buildHeader(BuildContext context, bool isWeb) {
    return Container(
      padding: EdgeInsets.only(
        top: isWeb ? 40 : 60,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: isWeb ? Colors.white : const Color(0xFF1E70CD),
        boxShadow: isWeb
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isWeb)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                ),
              Text(
                'Mis publicaciones',
                style: TextStyle(
                  color: isWeb ? const Color(0xFF1E70CD) : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (isWeb)
            ElevatedButton.icon(
              onPressed: () => context.push('/publication/create'),
              icon: const Icon(Icons.add),
              label: const Text(
                'Crear publicación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E70CD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPublicationCard(Map<String, dynamic> pub, int index) {
    final isActive = pub['status'] == 'Activa';
    final statusBg = isActive
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFF5F5F5);
    final statusText = isActive
        ? const Color(0xFF2E7D32)
        : const Color(0xFF757575);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pub['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pub['subtitle'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  pub['status'],
                  style: TextStyle(
                    color: statusText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.push('/publication/${pub['id']}/edit'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E70CD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Editar',
                    style: TextStyle(
                      color: Color(0xFF1E70CD),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _toggleStatus(index),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isActive ? 'Pausar' : 'Activar',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    side: const BorderSide(color: Color(0xFFEF9A9A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
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
