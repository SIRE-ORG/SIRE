class ApiFlags {
  ApiFlags._();

  // Activar con: flutter run --dart-define=USE_REAL_BACKEND=true
  static const bool useRealBackend = bool.fromEnvironment(
    'USE_REAL_BACKEND',
    defaultValue: false,
  );
}
