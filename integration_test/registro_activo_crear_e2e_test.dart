// E2E — Cadena OTP: sendMagicLink → verifyOtp → registerGuest → activate → createPublication.
//
// Usa service_role para obtener el código OTP sin bandeja real ni deep link.
// Se ejecuta SOLO en Windows con la key de service_role definida:
//   flutter test integration_test/registro_activo_crear_e2e_test.dart -d windows \
//     --dart-define=SIRE_SERVICE_ROLE_KEY=<service_role_key>
//
// Sin SIRE_SERVICE_ROLE_KEY el test se salta automáticamente (skip).
// Email único por corrida (pi-e2e-<timestamp>@sire.cl).

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_real_impl.dart';
import 'package:sire/features/publications/data/models/create_publication_request_model.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _serviceRoleKey = String.fromEnvironment('SIRE_SERVICE_ROLE_KEY');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_serviceRoleKey.isEmpty) {
    testWidgets(
      'E2E inactivo — Define SIRE_SERVICE_ROLE_KEY para activar',
      (_) async {},
      skip: true,
    );
    return;
  }

  testWidgets('cadena OTP → guest → active → crear publicación', (_) async {
    await dotenv.load(fileName: '.env');
    final supabaseUrl = dotenv.env['SUPABASE_URL']!;
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;

    await Supabase.initialize(url: supabaseUrl, anonKey: anonKey);
    final supabase = Supabase.instance.client;
    final email = 'pi-e2e-${DateTime.now().millisecondsSinceEpoch}@sire.cl';
    const password = 'E2eTest123!';
    const name = '[PI-E2E]';
    const phone = '+56900000000';

    // ── Admin client para generateLink y limpieza ──
    final admin = SupabaseClient(supabaseUrl, _serviceRoleKey);

    // ── 1. Generar código OTP via admin (sin enviar correo real) ──
    final linkResponse = await admin.auth.admin.generateLink(
      type: GenerateLinkType.magiclink,
      email: email,
    );
    final otp = linkResponse.properties.emailOtp;
    expect(otp.length, greaterThanOrEqualTo(6));

    // ── 2. verifyOtp (crea sesión) ──
    await supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
    final uid = supabase.auth.currentUser!.id;
    expect(uid, isNotEmpty);

    final dio = DioClient.createSync().dio; // AuthInterceptor inyecta x-user-id

    // ── 3. registerGuest (perfil guest) ──
    final reg = await dio.post(
      ApiConstants.authRegisterGuest,
      data: {'id': uid, 'email': email, 'name': name, 'phone': phone},
    );
    expect(
      (reg.data['data'] as Map)['accountStatus'],
      'guest',
      reason: 'El perfil debe quedar en estado guest',
    );

    // ── 4. activate: setear contraseña + account-status ──
    await supabase.auth.updateUser(UserAttributes(password: password));
    await dio.patch(ApiConstants.authAccountStatus);
    final me = await dio.get(ApiConstants.authMe);
    expect(
      (me.data['data'] as Map)['accountStatus'],
      'active',
      reason: 'Tras activar, el perfil debe estar active',
    );

    // ── 5. Crear publicación ──
    final ds = PublicationsRemoteDatasourceRealImpl(
      dio: dio,
      supabase: supabase,
    );
    final region = 'PI-E2E-${DateTime.now().millisecondsSinceEpoch}';
    final detalle = await ds.createPublication(
      body: CreatePublicationRequestModel(
        title: '[PI-E2E] creada por usuario recién activado (OTP)',
        description: 'cadena OTP → guest → active → crear',
        category: PublicationCategory.deporte,
        region: region,
        availability: const AvailabilityConfig(
          slotDurationMinutes: 60,
          sameScheduleAllDays: true,
          defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
          dayOverrides: [
            DayOverride(
              dayOfWeek: DayOfWeek.sunday,
              isClosed: true,
              schedules: [],
            ),
          ],
        ),
      ),
    );
    expect(detalle.id, isNotEmpty); // ← cadena completa OK.

    // ── 6. Limpieza ──
    try {
      await dio.delete(ApiConstants.publicationByIdLive(detalle.id));
    } catch (_) {}
    try {
      await admin.auth.admin.deleteUser(uid);
    } catch (_) {}
    await supabase.auth.signOut();
  });
}
