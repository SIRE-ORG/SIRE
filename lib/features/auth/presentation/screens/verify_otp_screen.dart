import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _codigoCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _verificar() async {
    final code = _codigoCtrl.text.trim();
    if (code.length < 6) {
      _snack('Ingresa el código de 6 dígitos');
      return;
    }

    // Obtener datos del paso anterior vía GoRouter extra. `otpType:
    // 'emailChange'` marca el camino de activación de un guest anónimo
    // (welcome -> reserva -> "Crear contraseña"/"Activar cuenta"); cualquier
    // otro valor (o su ausencia) es el registro directo de siempre.
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>;
    final email = extra['email'] as String;
    final name = extra['name'] as String? ?? '';
    final phone = extra['phone'] as String? ?? '';
    final isEmailChange = extra['otpType'] == 'emailChange';

    setState(() => _cargando = true);
    try {
      final auth = ref.read(authNotifierProvider.notifier);

      await auth.verifyOtp(
        email: email,
        token: code,
        type: isEmailChange ? OtpType.emailChange : OtpType.email,
      );
      if (!mounted) return;

      if (ref.read(authNotifierProvider).hasError) {
        _snack(
          'Código inválido o expirado: ${ref.read(authNotifierProvider).error}',
        );
        setState(() => _cargando = false);
        return;
      }

      // Registro directo: con sesión ya activa, registrar el perfil guest.
      // El camino de activación de un guest anónimo ya tiene perfil (se creó
      // en la reserva), así que salta este paso.
      if (!isEmailChange) {
        await auth.registerGuest(name: name, email: email, phone: phone);
        if (!mounted) return;

        if (ref.read(authNotifierProvider).hasError) {
          _snack(
            'Registro de perfil falló: ${ref.read(authNotifierProvider).error}',
          );
          setState(() => _cargando = false);
          return;
        }
      }

      // Ir a activación (sin contraseña predefinida).
      if (!mounted) return;
      context.go('/activate-account');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verificar código',
                  style: TextStyle(
                    color: Color(0xFF1E70CD),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ingresa el código de 6 dígitos que enviamos a tu correo.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Código',
                  hintText: '000000',
                  keyboardType: TextInputType.number,
                  controller: _codigoCtrl,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CustomButton(
                    text: _cargando ? 'Verificando...' : 'Verificar',
                    onPressed: () {
                      if (!_cargando) _verificar();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
