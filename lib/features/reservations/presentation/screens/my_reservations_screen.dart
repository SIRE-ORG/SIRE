import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  bool _showActivas = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _showActivas ? _buildActivasList() : _buildHistorialList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 0, right: 0),
      decoration: const BoxDecoration(
        color: Color(0xFF1E70CD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Mis Reservas', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showActivas = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _showActivas ? const Color(0xFF1E70CD) : Colors.grey.shade300,
                            width: _showActivas ? 3 : 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Activas',
                          style: TextStyle(
                            color: _showActivas ? const Color(0xFF1E70CD) : Colors.grey,
                            fontWeight: _showActivas ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showActivas = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_showActivas ? const Color(0xFF1E70CD) : Colors.grey.shade300,
                            width: !_showActivas ? 3 : 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Historial',
                          style: TextStyle(
                            color: !_showActivas ? const Color(0xFF1E70CD) : Colors.grey,
                            fontWeight: !_showActivas ? FontWeight.bold : FontWeight.w500,
                          ),
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

  List<Widget> _buildActivasList() {
    return [
      GestureDetector(
        onTap: () => context.push('/reservation/1'),
        child: _buildReservationCard(
          'Cancha de fútbol sintética',
          'Sab 2 may • 13:00 - 14:00',
          'Pendiente',
          const Color(0xFFFFF3E0),
          const Color(0xFFF57C00),
        ),
      ),
    ];
  }

  List<Widget> _buildHistorialList() {
    return [
      _buildReservationCard(
        'Consultorio de kinesiología',
        'Mar 5 may • 11:00 - 12:00',
        'Completada',
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
      ),
      const SizedBox(height: 16),
      _buildReservationCard(
        'Salón para baile',
        'Jue 14 may • 15:00 - 16:00',
        'Cancelada',
        const Color(0xFFF5F5F5),
        const Color(0xFF757575),
      ),
    ];
  }

  Widget _buildReservationCard(String title, String subtitle, String status, Color statusBg, Color statusText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(status, style: TextStyle(color: statusText, fontSize: 12, fontWeight: FontWeight.bold)),
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
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today, color: Colors.white),
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