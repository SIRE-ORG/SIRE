import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';

class ReceivedReservationsScreen extends ConsumerStatefulWidget {
  const ReceivedReservationsScreen({super.key});

  @override
  ConsumerState<ReceivedReservationsScreen> createState() => _ReceivedReservationsScreenState();
}

class _ReceivedReservationsScreenState extends ConsumerState<ReceivedReservationsScreen> {
  bool _showPendientes = true;

  @override
  Widget build(BuildContext context) {
    final isPublisher = ref.watch(isPublisherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _showPendientes ? _buildPendientesList() : _buildHistorialList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, isPublisher),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Text('Reservas recibidas', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showPendientes = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _showPendientes ? const Color(0xFF1E70CD) : Colors.grey.shade300,
                            width: _showPendientes ? 3 : 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Pendientes',
                          style: TextStyle(
                            color: _showPendientes ? const Color(0xFF1E70CD) : Colors.grey,
                            fontWeight: _showPendientes ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showPendientes = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_showPendientes ? const Color(0xFF1E70CD) : Colors.grey.shade300,
                            width: !_showPendientes ? 3 : 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Historial',
                          style: TextStyle(
                            color: !_showPendientes ? const Color(0xFF1E70CD) : Colors.grey,
                            fontWeight: !_showPendientes ? FontWeight.bold : FontWeight.w500,
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

  List<Widget> _buildPendientesList() {
    return [
      _buildReservationCard(
        name: 'Carlos Pérez',
        publication: 'Cancha de futbol sintetica',
        date: 'Jue 15 may',
        time: '14:00-15:00',
        status: 'Pendiente',
        statusBg: const Color(0xFFFFF3E0),
        statusText: const Color(0xFFF57C00),
      ),
      const SizedBox(height: 12),
      _buildReservationCard(
        name: 'Ana Ruiz',
        publication: 'Cancha de futbol sintetica',
        date: 'Vie 16 may',
        time: '9:00-10:00',
        status: 'Pendiente',
        statusBg: const Color(0xFFFFF3E0),
        statusText: const Color(0xFFF57C00),
      ),
    ];
  }

  List<Widget> _buildHistorialList() {
    return [
      _buildReservationCard(
        name: 'Pedro Soto',
        publication: 'Cancha de futbol sintetica',
        date: 'Lun 5 may',
        time: '10:00-11:00',
        status: 'Completada',
        statusBg: const Color(0xFFE8F5E9),
        statusText: const Color(0xFF2E7D32),
      ),
    ];
  }

  Widget _buildReservationCard({
    required String name,
    required String publication,
    required String date,
    required String time,
    required String status,
    required Color statusBg,
    required Color statusText,
  }) {
    return GestureDetector(
      onTap: () {
        final uri = Uri(
          path: '/received-reservation/detail',
          queryParameters: {
            'name': name,
            'pub': publication,
            'date': date,
            'time': time,
            'status': status,
          },
        );
        context.push(uri.toString());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('$publication - $date\n$time', style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(status, style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.bold)),
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
            InkWell(
              onTap: () => context.go('/feed'),
              child: const Icon(Icons.home_outlined, color: Colors.white),
            ),
            if (!isPublisher)
              InkWell(
                onTap: () => context.go('/my-reservations'),
                child: const Icon(Icons.calendar_today_outlined, color: Colors.white),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
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