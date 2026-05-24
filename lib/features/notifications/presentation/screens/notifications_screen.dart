import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E70CD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationCard(
            title: 'Nueva reserva recibida',
            description: 'Carlos Perez reservó Cancha de fútbol • Sab 2 may 13:00',
            time: 'Hace 17 min',
            icon: Icons.calendar_today,
            color: const Color(0xFF1E70CD),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'Nueva reserva recibida',
            description: 'Ana Ruiz reservó Cancha de fútbol • Vie 15 may 09:00',
            time: 'Hace 1 hora',
            icon: Icons.calendar_today,
            color: const Color(0xFF1E70CD),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'Reserva completada',
            description: 'Tu reserva en Consultorio de kinesiología fue completada.',
            time: 'Mar 27 abr',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'Reserva cancelada',
            description: 'Pedro Soto canceló su reserva del Mar 5 de may.',
            time: 'Mar 5 may',
            icon: Icons.cancel_outlined,
            color: const Color(0xFFD32F2F),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'Bienvenido a SIRE',
            description: 'Explora publicaciones cerca de ti en Temuco.',
            time: 'Hace 7 días',
            icon: Icons.notifications_active_outlined,
            color: const Color(0xFFF57C00),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text(description, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.3)),
                          const SizedBox(height: 8),
                          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}