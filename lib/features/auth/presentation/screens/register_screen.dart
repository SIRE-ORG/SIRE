import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _enviarCodigo() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Ingresa tu correo electrónico');
      return;
    }

    setState(() => _cargando = true);
    try {
      await ref.read(authNotifierProvider.notifier).sendMagicLink(email: email);
    } catch (_) {
      // El código también se puede obtener vía generate_link aunque el envío
      // del correo falle (p. ej. rate limit). No bloqueamos el flujo.
    }
    if (!mounted) return;
    setState(() => _cargando = false);

    if (ref.read(authNotifierProvider).hasError) {
      _snack('Aviso: el correo no se envió; usa el código de generate_link.');
    }

    // Navegar SIEMPRE a verify-otp: el OTP llega por correo o se saca con
    // generate_link, así que el envío no debe bloquear el avance.
    context.go(
      '/verify-otp',
      extra: {
        'email': email,
        'name': _nombreCtrl.text.trim(),
        'phone': _telefonoCtrl.text.trim(),
      },
    );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registrarse',
            style: TextStyle(
              color: Color(0xFF1E70CD),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            label: 'Nombre completo',
            hintText: 'Ej: María González',
            controller: _nombreCtrl,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Correo',
            hintText: 'correo@gmail.com',
            keyboardType: TextInputType.emailAddress,
            controller: _emailCtrl,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Teléfono',
            hintText: '+56 9 1234 5678',
            keyboardType: TextInputType.phone,
            controller: _telefonoCtrl,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(
              text: _cargando ? 'Enviando código...' : 'Crear cuenta',
              onPressed: () {
                if (!_cargando) _enviarCodigo();
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Ya tienes cuenta?',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    color: Color(0xFF1E70CD),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
