import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/app_exception.dart';
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
  bool _reenviando = false;

  /// Segundos que faltan para habilitar "Reenviar código". Parte en 60 al
  /// abrir la pantalla y se reinicia tras cada reenvío EXITOSO (si el
  /// reenvío falla se queda en 0, para poder reintentar de inmediato).
  int _segundosParaReenvio = 60;
  Timer? _reenvioTimer;

  @override
  void initState() {
    super.initState();
    _iniciarContadorReenvio();
  }

  @override
  void dispose() {
    _reenvioTimer?.cancel();
    _codigoCtrl.dispose();
    super.dispose();
  }

  void _iniciarContadorReenvio() {
    _reenvioTimer?.cancel();
    _segundosParaReenvio = 60;
    _reenvioTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _segundosParaReenvio--;
        if (_segundosParaReenvio <= 0) timer.cancel();
      });
    });
  }

  String get _contadorReenvio {
    final min = _segundosParaReenvio ~/ 60;
    final seg = _segundosParaReenvio % 60;
    return '$min:${seg.toString().padLeft(2, '0')}';
  }

  Future<void> _reenviar() async {
    final data = _routeData(context);
    final email = data['email'] as String? ?? '';
    if (email.isEmpty) {
      _snack('No encontramos tu correo. Vuelve al paso anterior.');
      return;
    }
    final isEmailChange = data['otpType'] == 'emailChange';

    setState(() => _reenviando = true);
    try {
      // Reusa la acción que originó el OTP en cada contexto: magic link en
      // el registro directo, updateEmail (el OTP de cambio de correo de
      // startActivation) en la activación de un guest anónimo.
      final auth = ref.read(authNotifierProvider.notifier);
      if (isEmailChange) {
        await auth.startActivation(email: email);
      } else {
        await auth.sendMagicLink(email: email);
      }
      if (!mounted) return;

      final estado = ref.read(authNotifierProvider);
      if (estado.hasError) {
        _snack(
          estado.error is NetworkException
              ? 'Sin conexión. Revisa tu internet e intenta nuevamente.'
              : 'No pudimos reenviar el código. Intenta nuevamente.',
        );
        // El contador NO se reinicia: el usuario puede reintentar de una.
        return;
      }

      _snack('Código reenviado a $email');
      setState(_iniciarContadorReenvio);
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// `extra` puede venir null (p. ej. deep link directo a /verify-otp);
  /// se degrada a mapa vacío en vez de reventar con un cast.
  Map<String, dynamic> _routeData(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    return extra is Map<String, dynamic> ? extra : const <String, dynamic>{};
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
    final data = _routeData(context);
    final email = data['email'] as String? ?? '';
    if (email.isEmpty) {
      _snack('No encontramos tu correo. Vuelve al paso anterior.');
      return;
    }
    final name = data['name'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';
    final isEmailChange = data['otpType'] == 'emailChange';

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
    // La pantalla se comparte entre el registro directo (otpType `email`) y
    // la activación post-reserva de un guest anónimo (otpType `emailChange`);
    // el título y la instrucción cambian según el contexto.
    final data = _routeData(context);
    final isActivation = data['otpType'] == 'emailChange';
    final email = data['email'] as String? ?? '';
    final destino = email.isNotEmpty ? email : 'tu correo';

    final titulo = isActivation ? 'Activa tu cuenta' : 'Verificar código';
    final instruccion = isActivation
        ? 'Te enviamos un código de 6 dígitos a $destino. Ingrésalo para '
              'verificar tu correo; después solo falta crear tu contraseña.'
        : 'Ingresa el código de 6 dígitos que enviamos a $destino.';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E70CD)),
          // El camino de activación llega acá vía context.go() (pila vacía):
          // sin el guard, pop() revienta con "There is nothing to pop".
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(isActivation ? '/my-reservations' : '/register'),
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
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF1E70CD),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  instruccion,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Código',
                  hintText: '000000',
                  keyboardType: TextInputType.number,
                  controller: _codigoCtrl,
                ),
                const SizedBox(height: 8),
                // Reenvío del código: deshabilitado con cuenta regresiva de
                // 60s desde que se abre la pantalla; se habilita al llegar
                // a 0 y el contador reinicia tras un reenvío exitoso.
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: (_segundosParaReenvio > 0 || _reenviando)
                        ? null
                        : _reenviar,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: const Color(0xFF1E70CD),
                    ),
                    child: Text(
                      _segundosParaReenvio > 0
                          ? 'Reenviar código ($_contadorReenvio)'
                          : 'Reenviar código',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CustomButton(
                    text: 'Verificar',
                    loading: _cargando,
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
