import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/constants/chile_comunas.dart';
import 'package:sire/core/constants/chile_regions.dart';

void main() {
  test(
    'comunasPorRegion tiene exactamente las mismas claves que chileRegions',
    () {
      expect(comunasPorRegion.keys.toSet(), chileRegions.toSet());
      expect(comunasPorRegion.length, 16);
    },
  );

  test('ninguna región tiene lista de comunas vacía', () {
    for (final entry in comunasPorRegion.entries) {
      expect(
        entry.value,
        isNotEmpty,
        reason: 'Región sin comunas: ${entry.key}',
      );
    }
  });

  test('el total de comunas está en el rango esperado (330 a 360)', () {
    final total = comunasPorRegion.values.fold<int>(
      0,
      (sum, comunas) => sum + comunas.length,
    );
    expect(total, greaterThanOrEqualTo(330));
    expect(total, lessThanOrEqualTo(360));
  });

  test('spot-checks: comunas conocidas en su región', () {
    expect(comunasPorRegion['Región de La Araucanía'], contains('Temuco'));
    expect(comunasPorRegion['Región Metropolitana'], contains('Providencia'));
    expect(comunasPorRegion['Región de Los Ríos'], contains('Valdivia'));
  });

  test('sin comunas duplicadas dentro de una misma región', () {
    for (final entry in comunasPorRegion.entries) {
      expect(
        entry.value.toSet().length,
        entry.value.length,
        reason: 'Comunas duplicadas en ${entry.key}',
      );
    }
  });
}
