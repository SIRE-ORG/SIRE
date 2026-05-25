import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        if (isWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: Row(
              children: [
                _buildLeftPanel(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: _buildForm(context, isWeb: true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E70CD)),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildForm(context, isWeb: false),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftPanel() {
    return Expanded(
      child: Container(
        color: const Color(0xFF1E70CD),
        child: Center(
          child: Image.asset(
            'assets/images/Logo_SIRE.png',
            width: 250,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isWeb}) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 40 : 24),
      decoration: isWeb
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrarse', style: TextStyle(color: Color(0xFF1E70CD), fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          const CustomTextField(label: 'Nombre completo', hintText: 'Ej: María González'),
          const SizedBox(height: 16),
          const CustomTextField(label: 'Correo', hintText: 'correo@gmail.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          const CustomTextField(label: 'Teléfono', hintText: '+56 9 1234 5678', keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          const CustomTextField(label: 'Contraseña', hintText: 'Mínimo 8 caracteres', isPassword: true),
          const SizedBox(height: 16),
          const CustomTextField(label: 'Confirmar contraseña', hintText: 'Repite tu contraseña', isPassword: true),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(text: 'Crear cuenta', onPressed: () => context.go('/feed')),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿Ya tienes cuenta?', style: TextStyle(color: Colors.grey, fontSize: 14)),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Iniciar sesión', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}