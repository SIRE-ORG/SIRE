import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/providers/role_provider.dart';

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('RoleProvider', () {
    test('estado inicial es false y al actualizar muta a true', () {
      final container = createContainer();

      final initialState = container.read(isPublisherProvider);
      expect(initialState, false);

      container.read(isPublisherProvider.notifier).state = true;

      final updatedState = container.read(isPublisherProvider);
      expect(updatedState, true);
    });
  });
}