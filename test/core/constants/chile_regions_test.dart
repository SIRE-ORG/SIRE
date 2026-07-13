import 'package:flutter_test/flutter_test.dart';
import 'package:sire/core/constants/chile_regions.dart';

void main() {
  test('chileRegions tiene las 16 regiones de Chile, sin duplicados', () {
    expect(chileRegions.length, 16);
    expect(chileRegions.toSet().length, chileRegions.length);
  });

  test('chileRegions no contiene texto libre ni entradas vacías', () {
    for (final region in chileRegions) {
      expect(region.trim(), region);
      expect(region, isNotEmpty);
    }
  });

  test('chileRegions incluye la Región Metropolitana y La Araucanía', () {
    expect(chileRegions, contains('Región Metropolitana'));
    expect(chileRegions, contains('Región de La Araucanía'));
  });
}
