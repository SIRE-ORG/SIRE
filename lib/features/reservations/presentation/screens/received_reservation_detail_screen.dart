import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/reservation.dart';
import '../providers/reservations_provider.dart';

class ReceivedReservationDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final String applicantName;
  final String publication;
  final String date;
  final String time;
  final String status;

  const ReceivedReservationDetailScreen({
    super.key,
    required this.id,
    required this.applicantName,
    required this.publication,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  ConsumerState<ReceivedReservationDetailScreen> createState() =>
      _ReceivedReservationDetailScreenState();
}

class _ReceivedReservationDetailScreenState
    extends ConsumerState<ReceivedReservationDetailScreen> {
  bool _processing = false;

  Future<void> _updateStatus(ReservationStatus newStatus) async {
    if (widget.id.isEmpty) {
      _showSnackBar('ID de reserva no disponible aún');
      return;
    }
    setState(() => _processing = true);
    try {
      await ref
          .read(reservationActionNotifierProvider.notifier)
          .updateStatus(id: widget.id, status: newStatus);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) _showSnackBar('No se pudo actualizar el estado');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isPendiente = widget.status.toLowerCase() == 'pendiente';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E70CD),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Detalle de reserva',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 600 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWeb ? 40.0 : 24.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DATOS DEL SOLICITANTE',
                            style: TextStyle(
                              color: Color(0xFF1E70CD),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildField('Nombre', widget.applicantName),
                          const SizedBox(height: 16),
                          _buildField(
                            'Correo',
                            '${widget.applicantName.toLowerCase().replaceAll(' ', '').replaceAll('é', 'e')}@mail.com',
                          ),
                          const SizedBox(height: 16),
                          _buildField('Teléfono', '+56912345678'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SLOT RESERVADO',
                            style: TextStyle(
                              color: Color(0xFF1E70CD),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildField('Publicación', widget.publication),
                          const SizedBox(height: 16),
                          _buildField('Fecha', widget.date),
                          const SizedBox(height: 16),
                          _buildField('Horario', widget.time),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isPendiente
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.status,
                              style: TextStyle(
                                color: isPendiente
                                    ? const Color(0xFFF57C00)
                                    : const Color(0xFF2E7D32),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showSnackBar('Contacto por correo no disponible aún'),
                            icon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF1E70CD),
                              size: 18,
                            ),
                            label: const Text(
                              'Correo',
                              style: TextStyle(color: Color(0xFF1E70CD)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1E70CD)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showSnackBar('Contacto por WhatsApp no disponible aún'),
                            icon: const Icon(
                              Icons.phone,
                              color: Color(0xFF2E7D32),
                              size: 18,
                            ),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(color: Color(0xFF2E7D32)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (isPendiente) ...[
                      _actionButton(
                        label: 'Marcar como COMPLETADA',
                        bg: const Color(0xFFE8F5E9),
                        border: const Color(0xFF4CAF50),
                        text: const Color(0xFF2E7D32),
                        onPressed: _processing
                            ? null
                            : () => _updateStatus(ReservationStatus.completed),
                      ),
                      const SizedBox(height: 12),
                      _actionButton(
                        label: 'Marcar como FALLIDA',
                        bg: const Color(0xFFFFF3E0),
                        border: const Color(0xFFFF9800),
                        text: const Color(0xFFF57C00),
                        onPressed: _processing
                            ? null
                            : () => _updateStatus(ReservationStatus.failed),
                      ),
                      const SizedBox(height: 12),
                      _actionButton(
                        label: 'Rechazar reserva',
                        bg: const Color(0xFFFFEBEE),
                        border: const Color(0xFFEF9A9A),
                        text: const Color(0xFFC62828),
                        onPressed: _processing
                            ? null
                            : () => _updateStatus(ReservationStatus.rejected),
                      ),
                      if (_processing) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Reserva gestionada',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required Color bg,
    required Color border,
    required Color text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          label,
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    ),
  );
}
