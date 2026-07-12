// PI-AUTH-SUPA-DS — AuthSupabaseDatasourceImpl es un wrapper delgado sobre el
// GoTrueClient de Supabase: cada método delega en el SDK. Se inyecta un
// SupabaseClient mockeado (en producción usa Supabase.instance.client).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/features/auth/data/datasources/auth_supabase_datasource_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_doubles.dart';

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUserResponse extends Mock implements UserResponse {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late AuthSupabaseDatasourceImpl ds;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    ds = AuthSupabaseDatasourceImpl(client: client);
  });

  test('signInWithPassword delega en el SDK', () async {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => MockAuthResponse());

    await ds.signInWithPassword(email: 'a@b.cl', password: 'pw');

    verify(
      () => auth.signInWithPassword(email: 'a@b.cl', password: 'pw'),
    ).called(1);
  });

  test('signInAnonymously delega en el SDK', () async {
    when(
      () => auth.signInAnonymously(),
    ).thenAnswer((_) async => MockAuthResponse());

    await ds.signInAnonymously();

    verify(() => auth.signInAnonymously()).called(1);
  });

  test('signInWithOtp delega en el SDK (magic link)', () async {
    when(
      () => auth.signInWithOtp(email: any(named: 'email')),
    ).thenAnswer((_) async {});

    await ds.signInWithOtp(email: 'a@b.cl');

    verify(() => auth.signInWithOtp(email: 'a@b.cl')).called(1);
  });

  test(
    'verifyOtp con type por defecto delega en verifyOTP con OtpType.email',
    () async {
      when(
        () => auth.verifyOTP(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: OtpType.email,
        ),
      ).thenAnswer((_) async => MockAuthResponse());

      await ds.verifyOtp(email: 'a@b.cl', token: '123456');

      verify(
        () => auth.verifyOTP(
          email: 'a@b.cl',
          token: '123456',
          type: OtpType.email,
        ),
      ).called(1);
    },
  );

  test(
    'verifyOtp con type: emailChange delega en verifyOTP con ese type',
    () async {
      when(
        () => auth.verifyOTP(
          email: any(named: 'email'),
          token: any(named: 'token'),
          type: OtpType.emailChange,
        ),
      ).thenAnswer((_) async => MockAuthResponse());

      await ds.verifyOtp(
        email: 'a@b.cl',
        token: '123456',
        type: OtpType.emailChange,
      );

      verify(
        () => auth.verifyOTP(
          email: 'a@b.cl',
          token: '123456',
          type: OtpType.emailChange,
        ),
      ).called(1);
    },
  );

  test('updateEmail delega en updateUser con el email dado', () async {
    when(
      () => auth.updateUser(any()),
    ).thenAnswer((_) async => MockUserResponse());

    await ds.updateEmail(email: 'nuevo@correo.cl');

    final captured = verify(() => auth.updateUser(captureAny())).captured;
    expect((captured.single as UserAttributes).email, 'nuevo@correo.cl');
  });

  test('updatePassword delega en updateUser', () async {
    when(
      () => auth.updateUser(any()),
    ).thenAnswer((_) async => MockUserResponse());

    await ds.updatePassword(password: 'nuevaClave');

    verify(() => auth.updateUser(any())).called(1);
  });

  test('signOut delega en el SDK', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await ds.signOut();

    verify(() => auth.signOut()).called(1);
  });

  test('getCurrentUserId lee el currentUser de la sesión', () {
    // fakeUser usa `when` internamente: construirlo ANTES del thenReturn evita
    // un `when` anidado dentro de la respuesta del stub.
    final user = fakeUser(id: 'user-9');
    when(() => auth.currentUser).thenReturn(user);

    expect(ds.getCurrentUserId(), 'user-9');
  });

  test('getCurrentUserId → null sin sesión', () {
    when(() => auth.currentUser).thenReturn(null);

    expect(ds.getCurrentUserId(), isNull);
  });

  test('getCurrentJwt lee el accessToken de la sesión', () {
    // Sesión inline (solo accessToken): fakeSession construye internamente un
    // fakeUser dentro de un thenReturn → `when` anidado, que aquí no hace falta.
    final session = MockSession();
    when(() => session.accessToken).thenReturn('jwt-xyz');
    when(() => auth.currentSession).thenReturn(session);

    expect(ds.getCurrentJwt(), 'jwt-xyz');
  });

  test('authStateChanges reexpone onAuthStateChange', () {
    when(
      () => auth.onAuthStateChange,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    expect(ds.authStateChanges(), isA<Stream<AuthState>>());
  });
}
