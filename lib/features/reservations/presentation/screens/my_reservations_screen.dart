import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';

class MyReservationsScreen extends ConsumerStatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  ConsumerState<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends ConsumerState<MyReservationsScreen> {
  bool _showActivas = true;

  void _handleReservationTap(BuildContext context, bool isWeb, Map<String, String> data) {
    if (!isWeb) {
      final uri = Uri(
        path: '/reservation/${data['id']}',
        queryParameters: data,
      );
      context.push(uri.toString());
      return;
    }

    final isPendiente = data['status']?.toLowerCase() == 'pendiente';
    Color statusBgColor = const Color(0xFFFFF3E0);
    Color statusTextColor = const Color(0xFFF57C00);

    if (data['status']?.toLowerCase() == 'completada') {
      statusBgColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF2E7D32);
    } else if (data['status']?.toLowerCase() == 'cancelada') {
      statusBgColor = const Color(0xFFF5F5F5);
      statusTextColor = const Color(0xFF757575);
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar detalle',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 400,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(-5, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E70CD),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Detalle de Reserva', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Publicación', data['title'] ?? ''),
                            const SizedBox(height: 24),
                            _buildDetailRow('Publicador', data['publisher'] ?? ''),
                            const SizedBox(height: 24),
                            _buildDetailRow('Fecha', data['date'] ?? ''),
                            const SizedBox(height: 24),
                            _buildDetailRow('Horario', data['time'] ?? ''),
                            const SizedBox(height: 24),
                            const Text('Estado', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
                              child: Text(data['status'] ?? '', style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isPendiente)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFEBEE),
                              side: const BorderSide(color: Color(0xFFEF9A9A)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cancelar reserva', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w500)),
      ],
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
                      _buildHeader(isWeb: true),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: (_showActivas ? _buildActivasList(isWeb) : _buildHistorialList(isWeb))
                                .map((widget) => SizedBox(width: 400, child: widget))
                                .toList(),
                          ),
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
                _buildHeader(isWeb: false),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: (_showActivas ? _buildActivasList(isWeb) : _buildHistorialList(isWeb))
                          .map((widget) => Padding(padding: const EdgeInsets.only(bottom: 12), child: widget))
                          .toList(),
                    ),
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

  Widget _buildSidebar(BuildContext context, bool isPublisher) {
    return Container(
      width: 250,
      color: const Color(0xFF1E70CD),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('SIRE', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          _buildSidebarItem(context, Icons.home_outlined, 'Inicio', () => context.go('/feed')),
          if (!isPublisher)
            _buildSidebarItem(context, Icons.calendar_today, 'Mis Reservas', () {}, isActive: true),
          _buildSidebarItem(context, Icons.person_outline, 'Perfil', () => context.go('/profile')),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
    );
  }

  Widget _buildHeader({required bool isWeb}) {
    return Container(
      padding: EdgeInsets.only(top: isWeb ? 40 : 60, left: 0, right: 0),
      decoration: BoxDecoration(
        color: isWeb ? Colors.white : const Color(0xFF1E70CD),
        boxShadow: isWeb ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Mis Reservas',
              style: TextStyle(
                color: isWeb ? const Color(0xFF1E70CD) : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
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
                        color: Colors.transparent,
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
                        color: Colors.transparent,
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

  List<Widget> _buildActivasList(bool isWeb) {
    return [
      _buildReservationCard(
        title: 'Cancha de fútbol sintética',
        date: 'Hoy',
        time: '11:00 - 12:00',
        status: 'Pendiente',
        statusColor: const Color(0xFFFFF3E0),
        statusTextColor: const Color(0xFFF57C00),
        onTap: () => _handleReservationTap(context, isWeb, {
          'id': '1',
          'title': 'Cancha de fútbol sintética',
          'publisher': 'Club Deportivo Temuco',
          'date': 'Hoy',
          'time': '11:00 - 12:00',
          'status': 'Pendiente',
        }),
      ),
    ];
  }

  List<Widget> _buildHistorialList(bool isWeb) {
    return [
      _buildReservationCard(
        title: 'Consultorio de kinesiología',
        date: 'Mar 5 may',
        time: '11:00 - 12:00',
        status: 'Completada',
        statusColor: const Color(0xFFE8F5E9),
        statusTextColor: const Color(0xFF2E7D32),
        onTap: () => _handleReservationTap(context, isWeb, {
          'id': '2',
          'title': 'Consultorio de kinesiología',
          'publisher': 'Clínica Santa María',
          'date': 'Mar 5 may',
          'time': '11:00 - 12:00',
          'status': 'Completada',
        }),
      ),
      _buildReservationCard(
        title: 'Salón para baile',
        date: 'Jue 14 may',
        time: '15:00 - 16:00',
        status: 'Cancelada',
        statusColor: const Color(0xFFF5F5F5),
        statusTextColor: const Color(0xFF757575),
        onTap: () => _handleReservationTap(context, isWeb, {
          'id': '3',
          'title': 'Salón para baile',
          'publisher': 'Espacio El Ático',
          'date': 'Jue 14 may',
          'time': '15:00 - 16:00',
          'status': 'Cancelada',
        }),
      ),
    ];
  }

  Widget _buildReservationCard({
    required String title,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('$date • $time', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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