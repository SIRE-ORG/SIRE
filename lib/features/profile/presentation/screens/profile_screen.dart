import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublisher = ref.watch(isPublisherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(isPublisher),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildModeSelector(ref, isPublisher),
                  const SizedBox(height: 32),
                  _buildMenu(context, isPublisher),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, isPublisher),
    );
  }

  Widget _buildHeader(bool isPublisher) {
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('María González', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('maria@correo.com', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Temuco, La Araucanía', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          isPublisher ? _buildPublisherStats() : _buildSolicitanteStats(),
        ],
      ),
    );
  }

  Widget _buildSolicitanteStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('4', 'Reservas'),
        _buildStatItem('2', 'Completadas'),
      ],
    );
  }

  Widget _buildPublisherStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('4', 'Publicaciones'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildModeSelector(WidgetRef ref, bool isPublisher) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Modo de Uso', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(isPublisherProvider.notifier).state = false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isPublisher ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !isPublisher ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                    ),
                    child: Center(
                      child: Text('Solicitante', style: TextStyle(color: !isPublisher ? const Color(0xFF1E70CD) : const Color(0xFF64748B), fontWeight: !isPublisher ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(isPublisherProvider.notifier).state = true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isPublisher ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isPublisher ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                    ),
                    child: Center(
                      child: Text('Publicador', style: TextStyle(color: isPublisher ? const Color(0xFF1E70CD) : const Color(0xFF64748B), fontWeight: isPublisher ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context, bool isPublisher) {
    return Column(
      children: [
        _buildMenuItem(Icons.edit_outlined, 'Editar perfil', 'Nombre, teléfono, foto', () => context.push('/profile/edit')),
        const SizedBox(height: 12),
        if (!isPublisher)
          _buildMenuItem(Icons.calendar_today_outlined, 'Mis reservas', 'Ver historial completo', () => context.go('/my-reservations'))
        else
          _buildMenuItem(Icons.dashboard_outlined, 'Mis publicaciones', 'Ver publicaciones subidas', () => context.go('/dashboard')),
        const SizedBox(height: 12),
        _buildMenuItem(Icons.logout, 'Cerrar sesión', '', () => context.go('/'), isLogout: true),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isLogout = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isLogout ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: isLogout ? Colors.red : const Color(0xFF1E70CD), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isLogout ? Colors.red : const Color(0xFF1E293B))),
                  if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
        decoration: BoxDecoration(color: const Color(0xFF1E70CD), borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(onTap: () => context.go('/feed'), child: const Icon(Icons.home_outlined, color: Colors.white)),
            if (!isPublisher)
              InkWell(onTap: () => context.go('/my-reservations'), child: const Icon(Icons.calendar_today_outlined, color: Colors.white))
            else
              InkWell(onTap: () => context.go('/dashboard'), child: const Icon(Icons.bar_chart, color: Colors.white)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}