import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/reservation_eligibility.dart';
import '../../domain/usecases/create_reservation_usecase.dart';
import '../providers/reservation_eligibility_provider.dart';
import '../providers/reservations_provider.dart';

/// Patrón de fecha que [publication_detail_screen] envía en el query param
/// `date`: YYYY-MM-DD (la fecha del slot elegido, no un texto libre).
final RegExp _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

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

  bool _formValido(ReservationEligibility elig) {
    if (elig != ReservationEligibility.needsGuestForm) return true;
    return _nombreCtrl.text.trim().isNotEmpty &&
        _emailValido &&
        _telefonoCtrl.text.trim().isNotEmpty;
  }

  /// La fecha de la reserva es la del slot elegido (`widget.date`), NUNCA un
  /// DatePicker propio del formulario. Se parsea de forma defensiva: si no
  /// calza con YYYY-MM-DD, se trata como error controlado (nunca se cae a
  /// `DateTime.now()` silenciosamente).
  String? get _slotDateIso {
    final raw = widget.date.trim();
    return _isoDatePattern.hasMatch(raw) ? raw : null;
  }

  /// Fecha para mostrar en el resumen: dd/MM/yyyy si `widget.date` es ISO;
  /// si no (p. ej. datos de prueba legacy), se muestra tal cual llegó.
  String get _displayDate {
    final iso = _slotDateIso;
    if (iso == null) return widget.date.isNotEmpty ? widget.date : 'Hoy';
    final parts = iso.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleConfirm(
    ReservationEligibility elig,
    String? profileEmail,
  ) async {
    if (!_formValido(elig)) {
      _snack('Completa nombre, correo válido y teléfono');
      return;
    }

    final dateIso = _slotDateIso;
    if (dateIso == null) {
      _snack(
        'No se pudo determinar la fecha de la reserva. Vuelve a '
        'seleccionar un horario.',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (elig == ReservationEligibility.needsGuestForm) {
        try {
          await ref
              .read(authNotifierProvider.notifier)
              .registerGuest(
                name: _nombreCtrl.text.trim(),
                email: _correoCtrl.text.trim(),
                phone: _telefonoCtrl.text.trim(),
              );
        } on ConflictException {
          _snack('Este correo ya tiene cuenta; inicia sesión');
          return;
        }
      }

      final parts = widget.time.split('-');
      final startTime = (parts.isNotEmpty && parts[0].trim().contains(':'))
          ? parts[0].trim()
          : '10:00';
      final endTime = (parts.length > 1 && parts[1].trim().contains(':'))
          ? parts[1].trim()
          : '11:00';
      await ref
          .read(reservationActionNotifierProvider.notifier)
          .create(
            params: CreateReservationParams(
              publicationId: widget.id,
              date: dateIso,
              startTime: startTime,
              endTime: endTime,
            ),
          );

      final email = elig == ReservationEligibility.needsGuestForm
          ? _correoCtrl.text.trim()
          : profileEmail;
      if (mounted) _showSuccessDialog(context, email);
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

  /// Paso 1 de la activación (fase 3): adjunta [email] al usuario Supabase y
  /// navega a verificar el OTP de cambio de correo. Compartido por el modal
  /// de éxito ("Crear contraseña") y el aviso de `needsActivation`
  /// ("Activar cuenta"). Usa el `context` propio del State (no uno recibido
  /// por parámetro) para que el guard `mounted` sea válido tras el `await`.
  Future<void> _goToActivation(String? email) async {
    if (email == null || email.isEmpty) {
      _snack('No se pudo determinar tu correo. Intenta más tarde.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .startActivation(email: email);
      if (!mounted) return;

      if (ref.read(authNotifierProvider).hasError) {
        _snack('No se pudo iniciar la activación; intenta más tarde');
        return;
      }

      context.go(
        '/verify-otp',
        extra: {'email': email, 'otpType': 'emailChange'},
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(BuildContext context, String? guestEmail) {
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      text: 'Crear contraseña',
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _goToActivation(guestEmail);
                      },
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

  Widget _buildSummaryBanner() {
    return Container(
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
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$_displayDate • ${widget.time.isNotEmpty ? widget.time : "11:00"}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsActivationNotice(String? profileEmail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: const Text(
            'Ya hiciste una reserva como invitado. Activa tu cuenta con una '
            'contraseña para poder reservar de nuevo.',
            style: TextStyle(color: Color(0xFF7A4B00), fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CustomButton(
            text: _loading ? 'Activando...' : 'Activar cuenta',
            onPressed: _loading ? null : () => _goToActivation(profileEmail),
          ),
        ),
      ],
    );
  }

  Widget _buildFormAndConfirm(
    BuildContext context,
    ReservationEligibility elig,
    String? profileEmail,
  ) {
    final needsForm = elig == ReservationEligibility.needsGuestForm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsForm) ...[
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
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CustomButton(
            text: _loading ? 'Confirmando...' : 'Confirmar Reserva',
            onPressed: (_loading || !_formValido(elig))
                ? null
                : () => _handleConfirm(elig, profileEmail),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función no disponible aún')),
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
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReservationEligibility elig,
    String? profileEmail,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryBanner(),
        const SizedBox(height: 32),
        if (elig == ReservationEligibility.needsActivation)
          _buildNeedsActivationNotice(profileEmail)
        else
          _buildFormAndConfirm(context, elig, profileEmail),
      ],
    );
  }

  Widget _buildEligibilityError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No se pudo verificar tu cuenta para continuar',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.invalidate(reservationEligibilityProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eligibilityAsync = ref.watch(reservationEligibilityProvider);
    // Watch (no solo read) para que el provider no se auto-elimine entre el
    // build y el tap de un botón: sin esto, currentProfileProvider (autoDispose
    // y sin otro watcher en este árbol) podía quedar sin resolver a tiempo.
    final profileEmail = ref.watch(currentProfileProvider).valueOrNull?.email;

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
                  child: eligibilityAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E70CD),
                        ),
                      ),
                    ),
                    error: (e, _) => _buildEligibilityError(),
                    data: (elig) => _buildBody(context, elig, profileEmail),
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
