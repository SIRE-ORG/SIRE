import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Mis publicaciones', onTap: () => context.push('/my-publications')),
                  const SizedBox(height: 16),
                  _buildPublicationCard('Cancha de fútbol sintética', 'Deporte - Temuco', 'Activa', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                  const SizedBox(height: 12),
                  _buildPublicationCard('Consultorio de kinesiología', 'Salud - Temuco', 'Activa', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                  const SizedBox(height: 12),
                  _buildPublicationCard('Salón para baile', 'Eventos - Temuco', 'Pausada', const Color(0xFFF5F5F5), const Color(0xFF757575)),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Reservas recibidas', onTap: () => context.push('/received-reservations')),
                  const SizedBox(height: 16),
                  _buildReservationCard('Carlos Pérez', 'Cancha de fútbol sintética • Jue 15 may • 14:00-15:00', 'Nueva', const Color(0xFFE3F2FD), const Color(0xFF1E70CD)),
                  const SizedBox(height: 12),
                  _buildReservationCard('Carlos Pérez', 'Cancha de fútbol sintética • Jue 15 may • 14:00-15:00', 'Nueva', const Color(0xFFE3F2FD), const Color(0xFF1E70CD)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/publication/create'),
        backgroundColor: const Color(0xFF1E70CD),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E70CD),
      ),
      child: const Text(
        'Mi Panel',
        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatBox('2', 'Publicaciones\nActivas', const Color(0xFFE3F2FD), const Color(0xFF1E70CD))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox('2', 'Pendientes\npor revisar', const Color(0xFFFFF3E0), const Color(0xFFF57C00))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox('1', 'Completadas\n', const Color(0xFFE8F5E9), const Color(0xFF2E7D32))),
      ],
    );
  }

  Widget _buildStatBox(String number, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(number, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        GestureDetector(
          onTap: onTap,
          child: const Text('Ver todas >', style: TextStyle(color: Color(0xFF1E70CD), fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPublicationCard(String title, String subtitle, String status, Color statusBg, Color statusText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(16)),
            child: Text(status, style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(String title, String subtitle, String status, Color statusBg, Color statusText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(16)),
            child: Text(status, style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 80, right: 80),
        height: 60,
        decoration: BoxDecoration(color: const Color(0xFF1E70CD), borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(onTap: () => context.go('/feed'), child: const Icon(Icons.home_outlined, color: Colors.white)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.bar_chart, color: Colors.white),
            ),
            InkWell(onTap: () => context.go('/profile'), child: const Icon(Icons.person_outline, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}