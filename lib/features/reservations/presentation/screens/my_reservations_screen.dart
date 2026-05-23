import 'package:flutter/material.dart';

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

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
              children: [
                _buildReservationCard(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFF1E70CD), width: 3)),
                    ),
                    child: const Center(
                      child: Text('Activas', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                    ),
                    child: const Center(
                      child: Text('Historial', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
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

  Widget _buildReservationCard() {
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
          const Text('Cancha de fútbol sintética', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Sab 2 may • 13:00 - 14:00', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Pendiente', style: TextStyle(color: Color(0xFFF57C00), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
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
            const Icon(Icons.home_outlined, color: Colors.white),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today, color: Colors.white),
            ),
            const Icon(Icons.person_outline, color: Colors.white),
          ],
        ),
      ),
    );
  }
}