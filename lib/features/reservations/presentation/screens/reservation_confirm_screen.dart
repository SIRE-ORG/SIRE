import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/usecases/create_reservation_usecase.dart';
import '../providers/reservations_provider.dart';

class ReservationConfirmScreen extends ConsumerStatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String time;

  const ReservationConfirmScreen({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
  });

  @override
  ConsumerState<ReservationConfirmScreen> createState() =>
      _ReservationConfirmScreenState();
}

class _ReservationConfirmScreenState
    extends ConsumerState<ReservationConfirmScreen> {
  bool _loading = false;
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_nombreCtrl, _correoCtrl, _telefonoCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  bool get _emailValido =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_correoCtrl.text.trim());

  bool get _formValido =>
      _nombreCtrl.text.trim().isNotEmpty &&
      _emailValido &&
      _telefonoCtrl.text.trim().isNotEmpty;

  Future<void> _handleConfirm() async {
    if (!_formValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa nombre, correo válido y teléfono'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final parts = widget.time.contains('-')
          ? widget.time.split('-')
          : [widget.time, widget.time];
      await ref
          .read(reservationActionNotifierProvider.notifier)
          .create(
            params: CreateReservationParams(
              publicationId: widget.id,
              date: widget.date,
              startTime: parts[0].trim(),
              endTime: parts.length > 1 ? parts[1].trim() : parts[0].trim(),
            ),
          );
      if (mounted) _showSuccessDialog(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo confirmar la reserva')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¡Reserva confirmada!',
                    style: TextStyle(
                      color: Color(0xFF1E70CD),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Crea tu contraseña para gestionar tus reservas fácilmente. Puedes hacerlo ahora o más tarde.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CustomTextField(
                    label: 'Contraseña',
                    hintText: 'Mínimo 8 caracteres',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  const CustomTextField(
                    label: 'Confirmar contraseña',
                    hintText: 'Repite tu contraseña',
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      text: 'Crear contraseña',
                      onPressed: () => context.go('/my-reservations'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => context.go('/my-reservations'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E70CD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Ahora no',
                        style: TextStyle(
                          color: Color(0xFF1E70CD),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Confirmar Reserva',
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
                child: Container(
                  padding: EdgeInsets.all(isWeb ? 40 : 0),
                  decoration: isWeb
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title.isNotEmpty
                                        ? widget.title
                                        : 'Cancha de fútbol sintética',
                                    style: const TextStyle(
                                      color: Color(0xFF1E70CD),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle.isNotEmpty
                                        ? widget.subtitle
                                        : 'Club Deportivo Temuco',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${widget.date.isNotEmpty ? widget.date : "Hoy"} • ${widget.time.isNotEmpty ? widget.time : "11:00"}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'Nombre Completo',
                        hintText: 'Ej: María Torres',
                        controller: _nombreCtrl,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Correo',
                        hintText: 'Ej: mariatorres@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        controller: _correoCtrl,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Teléfono',
                        hintText: 'Ej: +56911223344',
                        keyboardType: TextInputType.phone,
                        controller: _telefonoCtrl,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: CustomButton(
                          text: _loading
                              ? 'Confirmando...'
                              : 'Confirmar Reserva',
                          onPressed: (_loading || !_formValido)
                              ? null
                              : _handleConfirm,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función no disponible aún'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF9A9A)),
                            backgroundColor: const Color(0xFFFFEBEE),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
