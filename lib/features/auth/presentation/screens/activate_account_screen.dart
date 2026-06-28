import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class ActivateAccountScreen extends ConsumerStatefulWidget {
  const ActivateAccountScreen({super.key});

  @override
  ConsumerState<ActivateAccountScreen> createState() =>
      _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends ConsumerState<ActivateAccountScreen> {
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _activar() async {
    final pwd = _passwordCtrl.text.trim();
    if (pwd.length < 8) {
      _snack('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setState(() => _cargando = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .activateAccount(password: pwd);
      if (!mounted) return;

      if (ref.read(authNotifierProvider).hasError) {
        _snack('No se pudo activar: ${ref.read(authNotifierProvider).error}');
        return;
      }

      _snack('Cuenta activada');
      context.go('/publication/create');
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
                  'Activar cuenta',
                  style: TextStyle(
                    color: Color(0xFF1E70CD),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Establece una contraseña para activar tu cuenta.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Contraseña',
                  hintText: 'Mínimo 8 caracteres',
                  isPassword: true,
                  controller: _passwordCtrl,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CustomButton(
                    text: _cargando ? 'Activando...' : 'Activar cuenta',
                    onPressed: () {
                      if (!_cargando) _activar();
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
