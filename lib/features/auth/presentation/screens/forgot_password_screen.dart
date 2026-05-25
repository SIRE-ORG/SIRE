import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        if (isWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF1E70CD),
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildForm(context, isWeb: true),
              ),
            ),
          );
        }

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
              'Recuperar contraseña',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildForm(context, isWeb: false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, {required bool isWeb}) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWeb) ...[
          const Text(
            'Recuperar contraseña',
            style: TextStyle(
              color: Color(0xFF1E70CD),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer el acceso a tu cuenta.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        const CustomTextField(
          label: 'Correo electrónico',
          hintText: 'Ej: mariatorres@gmail.com',
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: isWeb ? 40 : 0),
        if (isWeb)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(
              text: 'Enviar enlace',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace de recuperación enviado al correo'),
                  ),
                );
                context.pop();
              },
            ),
          ),
      ],
    );

    if (isWeb) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: content,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Expanded(child: content),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CustomButton(
            text: 'Enviar enlace',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enlace de recuperación enviado al correo'),
                ),
              );
              context.pop();
            },
          ),
        ),
      ],
    );
  }
}
