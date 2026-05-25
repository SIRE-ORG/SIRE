import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReservationDetailScreen extends StatelessWidget {
  final String id;
  final String title;
  final String publisher;
  final String date;
  final String time;
  final String status;

  const ReservationDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.publisher,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPendiente = status.toLowerCase() == 'pendiente';
    Color statusBgColor;
    Color statusTextColor;

    if (status.toLowerCase() == 'completada') {
      statusBgColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF2E7D32);
    } else if (status.toLowerCase() == 'cancelada') {
      statusBgColor = const Color(0xFFF5F5F5);
      statusTextColor = const Color(0xFF757575);
    } else {
      statusBgColor = const Color(0xFFFFF3E0);
      statusTextColor = const Color(0xFFF57C00);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E70CD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detalle de reserva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DETALLE DE RESERVA', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 24),
                  _buildDetailRow('Publicación', title),
                  const SizedBox(height: 16),
                  _buildDetailRow('Publicador', publisher),
                  const SizedBox(height: 16),
                  _buildDetailRow('Fecha', date),
                  const SizedBox(height: 16),
                  _buildDetailRow('Horario', time),
                  const SizedBox(height: 16),
                  const Text('Estado', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
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
            const Spacer(),
            if (isPendiente)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    side: const BorderSide(color: Color(0xFFEF9A9A)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancelar reserva',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}