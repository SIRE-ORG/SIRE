import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublisher = ref.watch(isPublisherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),
          _buildCategories(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPlaceCard('Cancha de fútbol sintética', 'Club Deportivo Temuco • Temuco', 'Deporte', '4.7', '(27)', onTap: () => context.push('/publication/1')),
                const SizedBox(height: 16),
                _buildPlaceCard('Consultorio de kinesiología', 'Clínica Santa María • Temuco', 'Salud', '4.8', '(31)', onTap: () => context.push('/publication/2')),
                const SizedBox(height: 16),
                _buildPlaceCard('Salón para baile', 'Espacio El Ático • Temuco', 'Eventos', '4.3', '(17)', onTap: () => context.push('/publication/3')),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, isPublisher),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E70CD),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SIRE', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Temuco, La Araucanía', style: TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 8),
                Text('Buscar publicaciones...', style: TextStyle(color: Colors.grey)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildChip('Todos', true),
          _buildChip('Deporte', false),
          _buildChip('Eventos', false),
          _buildChip('Recreación', false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E70CD) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF1E70CD) : Colors.grey.shade400),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPlaceCard(String title, String subtitle, String category, String rating, String reviews, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
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
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E70CD), borderRadius: BorderRadius.circular(12)),
                        child: Text(category, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(reviews, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ],
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