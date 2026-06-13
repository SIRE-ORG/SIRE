// PI-PROV-03 (auth) — El flag de backend real selecciona la implementación
// mock por defecto bajo flutter test.
//
// Sin binding de widgets. Solo se verifica el datasource remoto; no se tocan
// authRepositoryProvider ni authSupabaseDatasourceProvider (su inicialización
// tocaría Supabase.instance, que no está disponible en test).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/auth/data/datasources/auth_remote_datasource_mock_impl.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('PI-PROV-03: flag por defecto selecciona el mock', () {
    test('sin overrides, el datasource remoto de auth es el mock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(authRemoteDatasourceProvider),
        isA<AuthRemoteDatasourceMockImpl>(),
      );
    });
  });
}
