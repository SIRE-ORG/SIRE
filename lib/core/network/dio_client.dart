import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_constants.dart';
import 'app_exception.dart';

class DioClient {
  final Dio _dio;

  DioClient._(this._dio);

  static Future<DioClient> create() async => createSync();

  static DioClient createSync() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        // NO fijar contentType global: Dio ya pone application/json cuando hay
        // body Map/List. Forzarlo hace que requests SIN body (PATCH
        // /auth/account-status, DELETE /publications/:id) manden el header con
        // cuerpo vacío, y Fastify los rechaza con 400 FST_ERR_CTP_EMPTY_JSON_BODY
        // (hallazgo H7). Sin el header global, esos endpoints sin body funcionan.
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.addAll([AuthInterceptor(), ErrorInterceptor()]);
    return DioClient._(dio);
  }

  Dio get dio => _dio;
}

/// Inyecta la identidad de la sesión Supabase en cada request.
///
/// [sessionReader] es la costura que permite montar el interceptor en pruebas
/// sin inicializar Supabase; en producción lee Supabase.instance.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({Session? Function()? sessionReader})
    : _sessionReader = sessionReader ?? _supabaseSession;

  final Session? Function() _sessionReader;

  static Session? _supabaseSession() =>
      Supabase.instance.client.auth.currentSession;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = _sessionReader();
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      // El backend actual usa x-user-id para identificar al usuario (sin JWT).
      options.headers['x-user-id'] = session.user.id;
    }
    handler.next(options);
  }
}

/// Traduce todo error de transporte a un [AppException] tipado, conservando
/// la respuesta original para quien necesite inspeccionarla.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: AppExceptionFactory.fromDioException(err),
        type: err.type,
        response: err.response,
      ),
    );
  }
}
