import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/core/constants/chile_regions.dart';
import 'package:sire/features/auth/presentation/screens/location_screen.dart';
import 'package:sire/features/feed/data/datasources/geo_datasource.dart';
import 'package:sire/features/feed/domain/entities/geo_location.dart';
import 'package:sire/features/feed/presentation/providers/feed_provider.dart';

/// GeoDatasource controlable: permite fijar si el permiso ya está
/// concedido y qué devuelve (o lanza) getCurrentLocation.
class _FakeGeoDatasource implements GeoDatasource {
  _FakeGeoDatasource({
    required this.permissionGranted,
    this.location,
    this.error,
  });

  final bool permissionGranted;
  final GeoLocation? location;
  final Object? error;

  @override
  Future<bool> hasLocationPermission() async => permissionGranted;

  @override
  Future<GeoLocation> getCurrentLocation() async {
    if (error != null) throw error!;
    return location ?? const GeoLocation(region: 'Región de La Araucanía');
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/location',
      routes: [
        GoRoute(path: '/location', builder: (_, _) => const LocationScreen()),
        GoRoute(
          path: '/feed',
          builder: (_, _) => const Scaffold(body: Text('Pantalla Feed')),
        ),
      ],
    );
  }

  Widget buildSubjectWithGeo(GeoDatasource geo) => ProviderScope(
    overrides: [geoDatasourceProvider.overrideWithValue(geo)],
    child: MaterialApp.router(routerConfig: buildRouter()),
  );

  testWidgets('LocationScreen muestra contenido principal', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    expect(find.text('¿Dónde estás?'), findsOneWidget);
    expect(find.text('Permitir ubicación'), findsOneWidget);
    expect(find.text('Seleccionar ubicación manualmente'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('LocationScreen navega a /feed al pulsar Permitir ubicación', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    await tester.tap(find.text('Permitir ubicación'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Feed'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('LocationScreen navega a /feed al pulsar selección manual', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    await tester.tap(find.text('Seleccionar ubicación manualmente'));
    await tester.pumpAndSettle();

    // Se abre el selector de región; al elegir una, navega al feed.
    await tester.tap(find.text('Región de Arica y Parinacota'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Feed'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'LocationScreen selector manual ofrece exactamente la lista compartida '
    'de regiones (chileRegions)',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        if (details.exceptionAsString().contains('Unable to load asset')) {
          return;
        }
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
      await tester.pump();

      await tester.tap(find.text('Seleccionar ubicación manualmente'));
      await tester.pumpAndSettle();

      for (final region in chileRegions) {
        expect(find.text(region), findsOneWidget);
      }
      expect(find.byType(ListTile), findsNWidgets(chileRegions.length));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('LocationScreen muestra aviso de privacidad', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();

    expect(
      find.textContaining('Tu ubicación solo se usa para filtrar el feed'),
      findsOneWidget,
    );

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  group('E: salto automático si el permiso ya está concedido', () {
    testWidgets(
      'permiso concedido + región cacheada -> entra directo a /feed sin tap',
      (WidgetTester tester) async {
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.exceptionAsString().contains('overflowed')) return;
          originalOnError?.call(details);
        };
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = originalOnError;
        });

        FlutterSecureStorage.setMockInitialValues({
          'last_region': 'Región de La Araucanía',
        });

        await tester.pumpWidget(
          buildSubjectWithGeo(_FakeGeoDatasource(permissionGranted: true)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pantalla Feed'), findsOneWidget);
        expect(find.text('¿Dónde estás?'), findsNothing);
      },
    );

    testWidgets(
      'permiso concedido + sin caché pero la detección resuelve -> entra '
      'directo a /feed',
      (WidgetTester tester) async {
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.exceptionAsString().contains('overflowed')) return;
          originalOnError?.call(details);
        };
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = originalOnError;
        });

        await tester.pumpWidget(
          buildSubjectWithGeo(
            _FakeGeoDatasource(
              permissionGranted: true,
              location: const GeoLocation(
                region: 'Región Metropolitana',
                city: 'Santiago',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pantalla Feed'), findsOneWidget);
      },
    );

    testWidgets(
      'sin permiso concedido -> muestra la pantalla normal, sin saltar',
      (WidgetTester tester) async {
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.exceptionAsString().contains('overflowed')) return;
          originalOnError?.call(details);
        };
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = originalOnError;
        });

        await tester.pumpWidget(
          buildSubjectWithGeo(_FakeGeoDatasource(permissionGranted: false)),
        );
        await tester.pumpAndSettle();

        expect(find.text('¿Dónde estás?'), findsOneWidget);
        expect(find.text('Permitir ubicación'), findsOneWidget);
        expect(find.text('Pantalla Feed'), findsNothing);
      },
    );

    testWidgets(
      'permiso concedido pero sin caché y la detección falla -> muestra la '
      'pantalla normal',
      (WidgetTester tester) async {
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (details.exceptionAsString().contains('overflowed')) return;
          originalOnError?.call(details);
        };
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = originalOnError;
        });

        await tester.pumpWidget(
          buildSubjectWithGeo(
            _FakeGeoDatasource(
              permissionGranted: true,
              error: Exception('sin señal GPS'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('¿Dónde estás?'), findsOneWidget);
        expect(find.text('Pantalla Feed'), findsNothing);
      },
    );
  });
}
