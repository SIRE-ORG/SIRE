// PI-AUTH-01 / PI-AUTH-02 - Integración de la fuente de datos real de auth.
//
// getProfile consume GET /auth/me (el atajo sobre /users/profiles murió al
// registrarse authRoutes en el backend). emailVerified no existe en la tabla
// profiles: se deriva de la sesión Supabase, y eso es parte del contrato
// interno que estas pruebas fijan.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/api_constants.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:sire/features/auth/data/datasources/auth_remote_datasource_real_impl.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_doubles.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    dio.interceptors.add(ErrorInterceptor());
  });

  AuthRemoteDatasourceRealImpl datasourceCon({
    bool conUsuario = true,
    bool emailConfirmado = true,
  }) => AuthRemoteDatasourceRealImpl(
    dio: dio,
    supabase: supabaseWithUser(
      conUsuario
          ? fakeUser(id: 'user-1', emailConfirmed: emailConfirmado)
          : null,
    ),
  );

  group('getProfile (PI-AUTH-01)', () {
    test(
      '200 de /auth/me -> perfil con emailVerified derivado de Supabase',
      () async {
        adapter.onGet(
          ApiConstants.authMe,
          (server) => server.reply(200, {
            'data': profileJson(id: 'user-1', accountStatus: 'guest'),
          }),
        );

        final model = await datasourceCon().getProfile();

        expect(model.userId, 'user-1');
        expect(model.email, 'dani@sire.cl');
        expect(model.name, 'Dani');
        // emailVerified no viene del backend: lo aporta la sesión Supabase.
        expect(model.emailVerified, isTrue);
        expect(model.toEntity().accountStatus, AccountStatus.guest);
      },
    );

    test('name null en profiles degrada a string vacío', () async {
      adapter.onGet(
        ApiConstants.authMe,
        (server) => server.reply(200, {'data': profileJson(name: null)}),
      );

      final model = await datasourceCon().getProfile();

      expect(model.name, '');
    });

    test('404 (perfil no existe en profiles) -> NotFoundException', () async {
      adapter.onGet(
        ApiConstants.authMe,
        (server) =>
            server.reply(404, errorBody('NOT_FOUND', 'Perfil no encontrado')),
      );

      try {
        await datasourceCon().getProfile();
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(e.error, isA<NotFoundException>());
      }
    });

    test(
      'sin sesión Supabase -> UnauthorizedException sin tocar la red',
      () async {
        await expectLater(
          datasourceCon(conUsuario: false).getProfile(),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );
  });

  group('updateAccountStatus', () {
    test('PATCH /auth/account-status se completa con 200', () async {
      adapter.onPatch(
        ApiConstants.authAccountStatus,
        (server) =>
            server.reply(200, {'data': profileJson(accountStatus: 'active')}),
      );

      await expectLater(datasourceCon().updateAccountStatus(), completes);
    });

    test('sin sesión -> UnauthorizedException', () async {
      await expectLater(
        datasourceCon(conUsuario: false).updateAccountStatus(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('flujos no integrables aún (PI-AUTH-02)', () {
    test(
      'registerGuest con sesión -> POST real y respuesta correcta',
      () async {
        const name = 'Dani';
        const email = 'dani@sire.cl';

        adapter.onPost(
          ApiConstants.authRegisterGuest,
          (server) => server.reply(200, {
            'data': profileJson(id: 'user-1', accountStatus: 'guest'),
          }),
          data: {
            'id': 'user-1',
            'email': email,
            'name': name,
            'phone': '+56911111111',
          },
        );

        final result = await datasourceCon().registerGuest(
          name: name,
          email: email,
          phone: '+56911111111',
        );

        expect(result.userId, 'user-1');
        expect(result.accountStatus, 'guest');
        expect(result.userCreated, isTrue);
        expect(result.token, isNull);
      },
    );

    test('registerGuest sin sesión -> UnauthorizedException', () async {
      await expectLater(
        datasourceCon(conUsuario: false).registerGuest(
          name: 'Dani',
          email: 'dani@sire.cl',
          phone: '+56911111111',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('updateProfile -> error controlado ENDPOINT_NOT_AVAILABLE', () {
      try {
        datasourceCon().updateProfile(name: 'Otro');
        fail('Se esperaba un ServerException');
      } on ServerException catch (e) {
        expect(e.code, 'ENDPOINT_NOT_AVAILABLE');
        expect(e.message, contains('no implementado en el backend'));
      }
    });
  });
}
