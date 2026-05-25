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

  void _showDetailPanel(BuildContext context, Map<String, String> data) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 450,
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: _buildDetailContent(context, data),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, a1, a2, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(a1),
        child: child,
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, Map<String, String> data) {
    final isPendiente = data['status']?.toLowerCase() == 'pendiente';

    return Column(
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
              const Text('Detalle de Reserva Recibida', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DATOS DEL SOLICITANTE', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 16),
                _infoTile('Nombre', data['name'] ?? ''),
                _infoTile('Correo', 'carlosperez@mail.com'),
                _infoTile('Teléfono', '+56912345678'),
                const SizedBox(height: 32),
                const Text('SLOT RESERVADO', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 16),
                _infoTile('Publicación', data['pub'] ?? ''),
                _infoTile('Fecha', data['date'] ?? ''),
                _infoTile('Horario', data['time'] ?? ''),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.email_outlined, color: Color(0xFF1E70CD), size: 18),
                        label: const Text('Correo', style: TextStyle(color: Color(0xFF1E70CD))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1E70CD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone, color: Color(0xFF2E7D32), size: 18),
                        label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF2E7D32))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isPendiente) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5E9),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFF4CAF50))),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Marcar como COMPLETADA', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF3E0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFFF9800))),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Marcar como FALLIDA', style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFEF9A9A))),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Rechazar reserva', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('Reserva gestionada', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
                  )
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))]));

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
                            children: (_showPendientes ? _buildPendientesList(true) : _buildHistorialList(true))
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
        }

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
                    children: (_showPendientes ? _buildPendientesList(false) : _buildHistorialList(false))
                        .map((widget) => Padding(padding: const EdgeInsets.only(bottom: 12), child: widget))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context, isPublisher),
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
          const Text('SIRE', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          _buildSidebarItem(context, Icons.home_outlined, 'Inicio', () => context.go('/feed')),
          _buildSidebarItem(context, Icons.bar_chart, 'Dashboard', () => context.go('/dashboard'), isActive: true),
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
      decoration: BoxDecoration(color: isWeb ? Colors.white : const Color(0xFF1E70CD), boxShadow: isWeb ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : []),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (!isWeb)
                  GestureDetector(onTap: () => context.pop(), child: const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20))),
                Text('Reservas recibidas', style: TextStyle(color: isWeb ? const Color(0xFF1E70CD) : Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _tabItem('Pendientes', _showPendientes, () => setState(() => _showPendientes = true)),
                _tabItem('Historial', !_showPendientes, () => setState(() => _showPendientes = false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String t, bool active, VoidCallback onTap) => Expanded(child: InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? const Color(0xFF1E70CD) : Colors.grey.shade300, width: active ? 3 : 1))), child: Center(child: Text(t, style: TextStyle(color: active ? const Color(0xFF1E70CD) : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.w500))))));

  List<Widget> _buildPendientesList(bool isWeb) {
    return [
      _buildReservationCard(name: 'Carlos Pérez', publication: 'Cancha de futbol sintetica', date: 'Jue 15 may', time: '14:00-15:00', status: 'Pendiente', statusBg: const Color(0xFFFFF3E0), statusText: const Color(0xFFF57C00), isWeb: isWeb),
      _buildReservationCard(name: 'Ana Ruiz', publication: 'Cancha de futbol sintetica', date: 'Vie 16 may', time: '9:00-10:00', status: 'Pendiente', statusBg: const Color(0xFFFFF3E0), statusText: const Color(0xFFF57C00), isWeb: isWeb),
    ];
  }

  List<Widget> _buildHistorialList(bool isWeb) {
    return [
      _buildReservationCard(name: 'Pedro Soto', publication: 'Cancha de futbol sintetica', date: 'Lun 5 may', time: '10:00-11:00', status: 'Completada', statusBg: const Color(0xFFE8F5E9), statusText: const Color(0xFF2E7D32), isWeb: isWeb),
    ];
  }

  Widget _buildReservationCard({required String name, required String publication, required String date, required String time, required String status, required Color statusBg, required Color statusText, required bool isWeb}) {
    final data = {'name': name, 'pub': publication, 'date': date, 'time': time, 'status': status};

    return GestureDetector(
      onTap: () {
        if (isWeb) {
          _showDetailPanel(context, data);
        } else {
          final uri = Uri(path: '/received-reservation/detail', queryParameters: data);
          context.push(uri.toString());
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('$publication\n$date • $time', style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(16)), child: Text(status, style: TextStyle(color: statusText, fontSize: 12, fontWeight: FontWeight.bold))),
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
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.bar_chart, color: Colors.white)),
            InkWell(onTap: () => context.go('/profile'), child: const Icon(Icons.person_outline, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}