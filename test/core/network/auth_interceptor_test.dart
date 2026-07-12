// PI-PUB-03 (parte b) - Inyección de la cabecera de identidad.
//
// El header x-user-id no lo pone cada datasource: lo inyecta el
// AuthInterceptor del core leyendo la sesión Supabase. Se prueba aquí, donde
// realmente vive, con la costura sessionReader para no inicializar Supabase.
//
// NOTA: mocktail 1.0.4 + http_mock_adapter 0.6.1 colisionan al usar when()
// sobre Session/User (el flag _whenInProgress de mocktail se corrompe). Para
// este archivo se extiende Mock sin llamar a when(), delegando en overrides
// explícitos. Los dobles con when() (test_doubles.dart) siguen disponibles
// para las demás suites.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/core/network/dio_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Fakes manuales de Session / User derivando de Mock pero sin when()
// ---------------------------------------------------------------------------

class _FakeUser extends Mock implements User {
  @override
  String get id => 'user-7';
}

class _FakeSession extends Mock implements Session {
  @override
  String get accessToken => 'jwt-77';
  @override
  User get user => _FakeUser();
}

void main() {
  group('AuthInterceptor', () {
    test('con sesión activa inyecta Authorization y x-user-id', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      final adapter = DioAdapter(dio: dio);
      final sesion = _FakeSession();
      dio.interceptors.add(AuthInterceptor(sessionReader: () => sesion));

      // El matcher de headers actúa como aserción: sin las cabeceras exactas
      // no hay mock que responda y la petición falla.
      adapter.onGet(
        '/publications/publications/mine',
        (server) => server.reply(200, {'data': <dynamic>[]}),
        headers: {'Authorization': 'Bearer jwt-77', 'x-user-id': 'user-7'},
      );

      final response = await dio.get('/publications/publications/mine');

      expect(response.statusCode, 200);
    });

    test('sin sesión no inyecta cabeceras de identidad', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      final adapter = DioAdapter(dio: dio);
      RequestOptions? enviada;
      dio.interceptors.addAll([
        AuthInterceptor(sessionReader: () => null),
        InterceptorsWrapper(
          onRequest: (options, handler) {
            enviada = options;
            handler.next(options);
          },
        ),
      ]);

      adapter.onGet(
        '/publications/publications',
        (server) => server.reply(200, {'data': <dynamic>[]}),
      );

      await dio.get('/publications/publications');

      expect(enviada, isNotNull);
      expect(enviada!.headers.containsKey('Authorization'), isFalse);
      expect(enviada!.headers.containsKey('x-user-id'), isFalse);
    });
  });
}
