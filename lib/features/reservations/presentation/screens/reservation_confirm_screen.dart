import 'package:dio/dio.dart';
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
  // Defensa en profundidad: aunque el modal de éxito ya bloquea el back del
  // sistema (PopScope), si de todos modos quedara visible el fondo, el botón
  // Confirmar no debe permitir un segundo envío tras crear la reserva.
  bool _reservationCreated = false;
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

  /// SnackBar de error: rojo, con ícono, flotante. Los mensajes de fallo
  /// (sin conexión, correo tomado, slot ocupado, fecha inválida) usan este
  /// estilo para distinguirse de los avisos neutros de [_snack].
  void _snackError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// El interceptor de Dio envuelve la [AppException] tipada dentro de
  /// `DioException.error`; acá se desenvuelve para poder mapear el mensaje
  /// visible sin depender del transporte.
  Object _unwrap(Object e) => e is DioException ? (e.error ?? e) : e;

  Future<void> _handleConfirm(
    ReservationEligibility elig,
    String? profileEmail,
  ) async {
    if (!_formValido(elig)) {
      _snackError('Completa nombre, correo válido y teléfono');
      return;
    }

    final dateIso = _slotDateIso;
    if (dateIso == null) {
      _snackError(
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
        } catch (e) {
          if (_unwrap(e) is! ConflictException) rethrow;
          _snackError('Este correo ya tiene cuenta; inicia sesión');
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

      // F1: la elegibilidad (regla de negocio 4) depende del conteo de
      // reservas del guest; sin invalidarla acá quedaba cacheada con el
      // valor previo a esta reserva y un guest podía seguir reservando sin
      // activar su cuenta. `create()` solo invalida la lista de reservas,
      // nunca la elegibilidad.
      ref.invalidate(reservationEligibilityProvider);

      final email = elig == ReservationEligibility.needsGuestForm
          ? _correoCtrl.text.trim()
          : profileEmail;
      if (mounted) {
        setState(() => _reservationCreated = true);
        _showSuccessDialog(context, email);
      }
    } catch (e) {
      final err = _unwrap(e);
      if (err is NetworkException) {
        _snackError('Sin conexión. Revisa tu internet e intenta nuevamente.');
      } else if (err is ConflictException) {
        _snackError('Ese horario ya no está disponible. Elige otro horario.');
      } else {
        _snackError('No se pudo confirmar la reserva');
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
      _snackError('No se pudo determinar tu correo. Intenta más tarde.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .startActivation(email: email);
      if (!mounted) return;

      if (ref.read(authNotifierProvider).hasError) {
        _snackError('No se pudo iniciar la activación; intenta más tarde');
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
        // F1: `barrierDismissible: false` solo evita el dismiss por tap
        // fuera; el back del sistema (Android) sigue haciendo
        // Navigator.maybePop() sobre esta ruta modal y la cerraba igual,
        // dejando la pantalla de fondo montada con elegibilidad cacheada.
        // PopScope(canPop: false) bloquea también ese gesto.
        return PopScope(
          canPop: false,
          child: Center(
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
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF2E7D32),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                      'Crea tu contraseña para guardar tus reservas, seguir '
                      'su estado y reservar más rápido la próxima vez.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (guestEmail != null && guestEmail.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Te enviaremos un código a $guestEmail.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lock_clock, color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Activa tu cuenta para volver a reservar',
                      style: TextStyle(
                        color: Color(0xFF7A4B00),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Ya hiciste una reserva como invitado. Crea una contraseña '
                'para proteger tus datos y seguir reservando; toma menos de '
                'un minuto.',
                style: TextStyle(
                  color: Color(0xFF7A4B00),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CustomButton(
            text: 'Activar cuenta',
            loading: _loading,
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
          Row(
            children: const [
              Icon(
                Icons.person_add_alt_1,
                color: Color(0xFF1E70CD),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Es tu primera reserva: déjanos tus datos de contacto',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Solo los pediremos esta vez; el dueño del recinto los usará '
            'para coordinar contigo.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 20),
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
        ] else ...[
          Row(
            children: const [
              Icon(
                Icons.check_circle_outline,
                color: Color(0xFF2E7D32),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tu cuenta está lista: revisa el resumen y confirma.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CustomButton(
            text: 'Confirmar Reserva',
            loading: _loading,
            onPressed: (_loading || _reservationCreated || !_formValido(elig))
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
            onPressed: () {
              // F2: el error observado acá viene cacheado "río arriba"
              // (currentProfileProvider/authStatusProvider como AsyncError);
              // invalidar solo reservationEligibilityProvider relanzaba el
              // mismo error sin reintentar la llamada real. Se invalida la
              // raíz y la cascada de `ref.watch` recomputa el resto.
              ref.invalidate(currentProfileProvider);
              ref.invalidate(reservationEligibilityProvider);
            },
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
