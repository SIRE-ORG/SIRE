import 'package:dio/dio.dart';

sealed class AppException implements Exception {}

class ServerException extends AppException {
  final String code;
  final String message;
  ServerException({required this.code, required this.message});
}

class NetworkException extends AppException {}

class UnauthorizedException extends AppException {}

class NotFoundException extends AppException {
  final String code;
  NotFoundException({required this.code});
}

class ConflictException extends AppException {
  final String code;
  ConflictException({required this.code});
}

class ValidationException extends AppException {
  final Map<String, dynamic> fields;
  ValidationException({required this.fields});
}

class AppExceptionFactory {
  AppExceptionFactory._();

  static AppException fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    final rawError = (data is Map) ? data['error'] : null;
    final code =
        (rawError is Map ? rawError['code'] as String? : null) ?? 'UNKNOWN';
    final message =
        (rawError is Map ? rawError['message'] as String? : null) ??
        e.message ??
        '';

    if (statusCode == 400) {
      final rawFields = rawError is Map ? rawError['fields'] : null;
      final fields = rawFields is Map<String, dynamic>
          ? rawFields
          : <String, dynamic>{};
      return ValidationException(fields: fields);
    } else if (statusCode == 401) {
      return UnauthorizedException();
    } else if (statusCode == 403) {
      return ServerException(code: 'FORBIDDEN', message: message);
    } else if (statusCode == 404) {
      return NotFoundException(code: code);
    } else if (statusCode == 409) {
      return ConflictException(code: code);
    } else if (statusCode == 422) {
      return ServerException(code: code, message: message);
    }

    final type = e.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.connectionTimeout) {
      return NetworkException();
    }

    return ServerException(code: 'UNKNOWN', message: e.message ?? '');
  }
}
