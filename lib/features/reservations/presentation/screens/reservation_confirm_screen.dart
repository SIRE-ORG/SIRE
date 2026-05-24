import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ReservationConfirmScreen extends StatelessWidget {
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
        title: const Text('Confirmar Reserva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Text(
                                '$date • $time',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const CustomTextField(
                      label: 'Nombre Completo',
                      hintText: 'Ej: María Torres',
                    ),
                    const SizedBox(height: 16),
                    const CustomTextField(
                      label: 'Correo',
                      hintText: 'Ej: mariatorres@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    const CustomTextField(
                      label: 'Teléfono',
                      hintText: 'Ej: +56911223344',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomButton(
                text: 'Confirmar Reserva',
                onPressed: () => _showSuccessModal(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  '¡Reserva confirmada!',
                  style: TextStyle(color: Color(0xFF1E70CD), fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crea tu contraseña para gestionar tus reservas fácilmente. Puedes hacerlo ahora o más tarde.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
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
                CustomButton(
                  text: 'Crear contraseña',
                  onPressed: () {
                    context.pop();
                    context.go('/my-reservations');
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    context.pop();
                    context.go('/my-reservations');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Color(0xFF1E70CD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ahora no',
                    style: TextStyle(
                      color: Color(0xFF1E70CD),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}