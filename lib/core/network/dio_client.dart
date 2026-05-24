import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_constants.dart';
import 'app_exception.dart';

class DioClient {
  final Dio _dio;

  DioClient._(this._dio);

  static Future<DioClient> create() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.addAll([_AuthInterceptor(), _ErrorInterceptor()]);
    return DioClient._(dio);
  }

  static DioClient createSync() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.addAll([_AuthInterceptor(), _ErrorInterceptor()]);
    return DioClient._(dio);
  }

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
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
