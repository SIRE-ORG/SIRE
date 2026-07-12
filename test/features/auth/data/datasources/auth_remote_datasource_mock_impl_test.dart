// PI-AUTH-MOCK-DS - El datasource mock de auth devuelve respuestas canned
// estables: es la fuente que usa la app cuando USE_MOCKS=true.

import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/auth/data/datasources/auth_remote_datasource_mock_impl.dart';

void main() {
  final ds = AuthRemoteDatasourceMockImpl();

  test('registerGuest -> usuario guest creado con token mock', () async {
    final r = await ds.registerGuest(name: 'Dani', email: 'a@b.cl', phone: '1');

    expect(r.accountStatus, 'guest');
    expect(r.userCreated, isTrue);
    expect(r.token, isNotNull);
  });

  test('updateAccountStatus -> completa sin lanzar', () async {
    await expectLater(ds.updateAccountStatus(), completes);
  });

  test('getProfile -> perfil demo guest', () async {
    final p = await ds.getProfile();

    expect(p.email, 'demo@sire.cl');
    expect(p.accountStatus, 'guest');
  });

  test('updateProfile -> refleja el name/phone enviados', () async {
    final p = await ds.updateProfile(name: 'Nuevo', phone: '+569999');

    expect(p.name, 'Nuevo');
    expect(p.phone, '+569999');
  });
}
