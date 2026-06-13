// PI-ERR-01 / PI-ERR-02 — Manejo de errores transversal (RNF-02, RNF-06).
//
// Monta el ErrorInterceptor real de producción sobre un Dio y verifica que
// cada código de error del contrato se traduce al AppException tipado que la
// capa de dominio espera. La convención del proyecto: el error tipado viaja
// en DioException.error; quien consume revisa `e.error is AppException`.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/core/network/dio_client.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('PI-ERR-02: códigos del contrato → fallos tipados del dominio', () {
    late Dio dio;
    late DioAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      adapter = DioAdapter(dio: dio);
      dio.interceptors.add(ErrorInterceptor());
    });

    Future<AppException> errorDe(
      Future<Response<dynamic>> Function() call,
    ) async {
      try {
        await call();
        fail('Se esperaba un DioException');
      } on DioException catch (e) {
        expect(
          e.error,
          isA<AppException>(),
          reason: 'el interceptor debe envolver un AppException tipado',
        );
        return e.error as AppException;
      }
    }

    test('400 con fields → ValidationException con los campos', () async {
      adapter.onPost(
        '/publications',
        (server) => server.reply(
          400,
          errorBody(
            'VALIDATION_ERROR',
            'Faltan campos',
            fields: {'title': 'requerido'},
          ),
        ),
        data: Matchers.any,
      );

      final err = await errorDe(() => dio.post('/publications', data: {}));

      expect(err, isA<ValidationException>());
      expect((err as ValidationException).fields['title'], 'requerido');
    });

    test('401 → UnauthorizedException', () async {
      adapter.onGet(
        '/protegido',
        (server) =>
            server.reply(401, errorBody('UNAUTHORIZED', 'Falta header')),
      );

      expect(
        await errorDe(() => dio.get('/protegido')),
        isA<UnauthorizedException>(),
      );
    });

    test('403 → ServerException FORBIDDEN con mensaje del backend', () async {
      adapter.onPut(
        '/publications/pub-1',
        (server) =>
            server.reply(403, errorBody('FORBIDDEN', 'No eres el dueño')),
        data: Matchers.any,
      );

      final err = await errorDe(() => dio.put('/publications/pub-1', data: {}));

      expect(err, isA<ServerException>());
      err as ServerException;
      expect(err.code, 'FORBIDDEN');
      expect(err.message, 'No eres el dueño');
    });

    test('404 → NotFoundException con el code del backend', () async {
      adapter.onGet(
        '/publications/no-existe',
        (server) => server.reply(404, errorBody('NOT_FOUND', 'No existe')),
      );

      final err = await errorDe(() => dio.get('/publications/no-existe'));

      expect(err, isA<NotFoundException>());
      expect((err as NotFoundException).code, 'NOT_FOUND');
    });

    test('409 → ConflictException con el code del backend', () async {
      adapter.onPost(
        '/reservations',
        (server) => server.reply(409, errorBody('SLOT_TAKEN', 'Slot ocupado')),
        data: Matchers.any,
      );

      final err = await errorDe(() => dio.post('/reservations', data: {}));

      expect(err, isA<ConflictException>());
      expect((err as ConflictException).code, 'SLOT_TAKEN');
    });

    test(
      '500 → ServerException conservando code y message del backend',
      () async {
        adapter.onGet(
          '/publications',
          (server) => server.reply(
            500,
            errorBody(
              'INTERNAL_SERVER_ERROR',
              'Error al obtener las publicaciones',
            ),
          ),
        );

        final err = await errorDe(() => dio.get('/publications'));

        expect(err, isA<ServerException>());
        err as ServerException;
        // Regresión: antes el fallback aplanaba a UNKNOWN y se perdía el code.
        expect(err.code, 'INTERNAL_SERVER_ERROR');
        expect(err.message, 'Error al obtener las publicaciones');
      },
    );
  });

  group('PI-ERR-01: backend inaccesible → error de red limpio', () {
    test('puerto cerrado real en localhost → NetworkException', () async {
      // Socket real contra un puerto sin servicio: ejercita el camino completo
      // de connectionError/connectTimeout sin simulación.
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:59993',
          connectTimeout: const Duration(seconds: 3),
        ),
      );
      dio.interceptors.add(ErrorInterceptor());

      try {
        await dio.get('/publications');
        fail('Se esperaba fallo de conexión');
      } on DioException catch (e) {
        expect(e.error, isA<NetworkException>());
      }
    });

    test('timeout de lectura → NetworkException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      final adapter = DioAdapter(dio: dio);
      dio.interceptors.add(ErrorInterceptor());

      adapter.onGet(
        '/lento',
        (server) => server.throws(
          408,
          DioException(
            requestOptions: RequestOptions(path: '/lento'),
            type: DioExceptionType.receiveTimeout,
          ),
        ),
      );

      try {
        await dio.get('/lento');
        fail('Se esperaba timeout');
      } on DioException catch (e) {
        expect(e.error, isA<NetworkException>());
      }
    });
  });
}
