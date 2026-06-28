import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    setState(() => _cargando = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      if (!mounted) return;

      if (ref.read(authNotifierProvider).hasError) {
        _snack(
          'No se pudo iniciar sesión: ${ref.read(authNotifierProvider).error}',
        );
        return;
      }

      context.go('/feed');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Bienvenido a SIRE',
            style: TextStyle(
              color: Color(0xFF1E70CD),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          CustomTextField(
            label: 'Correo',
            hintText: 'correo@gmail.com',
            keyboardType: TextInputType.emailAddress,
            controller: _emailCtrl,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Contraseña',
            hintText: 'Tu contraseña',
            isPassword: true,
            controller: _passwordCtrl,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(
              text: _cargando ? 'Ingresando...' : 'Iniciar sesión',
              onPressed: () {
                if (!_cargando) _login();
              },
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Olvidé mi contraseña',
                style: TextStyle(color: Color(0xFF1E70CD), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            '¿No tienes cuenta?',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => context.push('/register'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E70CD), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Registrarse',
                style: TextStyle(
                  color: Color(0xFF1E70CD),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
