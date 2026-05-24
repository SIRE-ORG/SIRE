import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReceivedReservationDetailScreen extends StatelessWidget {
  final String applicantName;
  final String publication;
  final String date;
  final String time;
  final String status;

  const ReceivedReservationDetailScreen({
    super.key,
    required this.applicantName,
    required this.publication,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPendiente = status.toLowerCase() == 'pendiente';
    final email = '${applicantName.toLowerCase().replaceAll(' ', '').replaceAll('é', 'e')}@mail.com';
    final phone = '+56912345678';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATOS DEL SOLICITANTE', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 16),
                  _buildField('Nombre', applicantName),
                  const SizedBox(height: 12),
                  _buildField('Correo', email),
                  const SizedBox(height: 12),
                  _buildField('Teléfono', phone),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SLOT RESERVADO', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 16),
                  _buildField('Publicación', publication),
                  const SizedBox(height: 12),
                  _buildField('Fecha', date),
                  const SizedBox(height: 12),
                  _buildField('Horario', time),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPendiente ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isPendiente ? const Color(0xFFF57C00) : const Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isPendiente) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF4CAF50)),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFFF9800)),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFEF9A9A)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Rechazar reserva', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
      ],
    );
  }
}