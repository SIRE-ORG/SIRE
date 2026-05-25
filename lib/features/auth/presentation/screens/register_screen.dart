import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout(context);
          }
          return _buildMobileLayout(context);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF1E70CD),
            child: Center(
              child: Image.asset('assets/images/Logo_SIRE.png', width: 250),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildFormContent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildFormContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registrarse',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E70CD),
            ),
          ),
          const SizedBox(height: 24),
          const CustomTextField(
            label: 'Nombre completo',
            hintText: 'Ej: María González',
          ),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Correo',
            hintText: 'correo@gmail.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Teléfono',
            hintText: '+56 9 1234 5678',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
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
            text: 'Crear cuenta',
            onPressed: () {
              context.go('/feed');
            },
          ),
        ],
      ),
    );
  }
}
