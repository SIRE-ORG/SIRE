/// La app corre contra el backend real por defecto (sin dart-defines).
///
/// Los mocks son un flag opt-in para desarrollo offline: activar con
/// `flutter run --dart-define=USE_MOCKS=true`.
class ApiFlags {
  ApiFlags._();

  static const bool useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: false,
  );
}
