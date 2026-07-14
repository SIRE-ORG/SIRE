import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/feed/domain/entities/feed_page.dart';
import 'package:sire/features/feed/domain/entities/publication_summary.dart';
import 'package:sire/features/feed/presentation/providers/feed_provider.dart';
import 'package:sire/features/feed/presentation/screens/feed_screen.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';

// Notifier falso que devuelve datos de inmediato sin tocar plataforma
class _FakeFeedNotifier extends FeedNotifier {
  static const _items = [
    PublicationSummary(
      id: 'p1',
      title: 'Cancha de fútbol El Estadio',
      description: 'Descripción',
      region: 'Araucanía',
      category: PublicationCategory.deporte,
      ownerName: 'Pedro González',
      ownerId: 'o1',
      createdAt: '2026-01-01',
    ),
    PublicationSummary(
      id: 'p2',
      title: 'Clases de yoga Namaste',
      description: 'Descripción',
      region: 'Araucanía',
      category: PublicationCategory.otros,
      ownerName: 'Ana Ruiz',
      ownerId: 'o2',
      createdAt: '2026-01-02',
    ),
  ];

  /// Última categoría recibida por [setCategory]; permite comprobar que cada
  /// chip manda el valor de enum correcto (el "query param" real lo arma
  /// GetFeedUseCase -> repo -> datasource a partir de este valor).
  PublicationCategory? lastCategory;
  var setCategoryCallCount = 0;

  /// Región recibida en cada llamada a [setRegionManually]; null significa
  /// "Todas las regiones" (la petición va sin filtro de región).
  final regionCalls = <String?>[];

  @override
  Future<FeedPage> build() async => const FeedPage(
    items: _items,
    page: 1,
    limit: 10,
    total: 2,
    hasMore: false,
    currentRegion: 'Araucanía',
    currentOrder: FeedOrder.recent,
  );

  // El filtro visual lo hace _filterLocally en el widget; acá solo
  // registramos con qué categoría se llamó para poder aserirlo en el test.
  @override
  Future<void> setCategory(PublicationCategory? category) async {
    lastCategory = category;
    setCategoryCallCount++;
  }

  @override
  Future<void> setRegionManually(String? region) async {
    regionCalls.add(region);
  }
}

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/feed',
  routes: [
    GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
  ],
);

Widget _buildSubject({_FakeFeedNotifier? notifier}) => ProviderScope(
  overrides: [
    feedNotifierProvider.overrideWith(() => notifier ?? _FakeFeedNotifier()),
  ],
  child: MaterialApp.router(routerConfig: _makeRouter()),
);

void main() {
  testWidgets('FeedScreen renderiza UI y filtros', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Explorar'), findsWidgets);
    expect(find.text('Cancha de fútbol El Estadio'), findsWidgets);

    await tester.tap(find.text('Deporte').first);
    await tester.pump();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('FeedScreen filtro Deporte muestra solo publicación de Deporte', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };

    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Deporte').first);
    await tester.pump();

    expect(find.text('Cancha de fútbol El Estadio'), findsOneWidget);
    expect(find.text('Clases de yoga Namaste'), findsNothing);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'FeedScreen no ofrece el chip Salud (categoría muerta, fuera del enum '
    'congelado por el backend)',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Salud'), findsNothing);
      // Las 4 categorías válidas del enum congelado + "Todos" sí se ofrecen
      // como chip. "Deporte" y "Otros" además aparecen como badge en las
      // tarjetas (p1 es deporte, p2 es otros), de ahí findsWidgets en esos
      // dos en vez de findsOneWidget.
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Deporte'), findsWidgets);
      expect(find.text('Eventos'), findsOneWidget);
      expect(find.text('Recreación'), findsOneWidget);
      expect(find.text('Otros'), findsWidgets);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('FeedScreen filtro Otros muestra solo publicación de Otros', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };

    // Viewport ancho: el chip "Otros" es el último de la fila con scroll
    // horizontal y en un ancho angosto (390) queda fuera de la vista inicial.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Otros').first);
    await tester.pump();

    expect(find.text('Clases de yoga Namaste'), findsOneWidget);
    expect(find.text('Cancha de fútbol El Estadio'), findsNothing);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'FeedScreen: cada chip válido manda la categoría de enum correcta a '
    'setCategory',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      final notifier = _FakeFeedNotifier();
      await tester.pumpWidget(_buildSubject(notifier: notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      const casos = {
        'Deporte': PublicationCategory.deporte,
        'Eventos': PublicationCategory.eventos,
        'Recreación': PublicationCategory.recreacion,
        'Otros': PublicationCategory.otros,
      };

      for (final entry in casos.entries) {
        await tester.tap(find.text(entry.key).first);
        await tester.pump();
        expect(
          notifier.lastCategory,
          entry.value,
          reason: 'chip ${entry.key} debe mandar ${entry.value}',
        );
      }

      await tester.tap(find.text('Todos').first);
      await tester.pump();
      expect(notifier.lastCategory, isNull);
      expect(notifier.setCategoryCallCount, casos.length + 1);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

  // S3-2: selector de región del feed con opción "Todas las regiones".
  testWidgets(
    'FeedScreen: el selector de región ofrece Todas las regiones primero y '
    'al elegirla manda region null',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });

      final notifier = _FakeFeedNotifier();
      await tester.pumpWidget(_buildSubject(notifier: notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // El header muestra la región activa del estado del feed.
      expect(find.text('Araucanía'), findsOneWidget);

      await tester.tap(find.text('Araucanía'));
      await tester.pumpAndSettle();

      // "Todas las regiones" encabeza el selector, seguida de las 16
      // regiones canónicas.
      expect(find.text('Todas las regiones'), findsOneWidget);
      expect(find.text('Región Metropolitana'), findsOneWidget);
      expect(find.text('Región de La Araucanía'), findsOneWidget);

      await tester.tap(find.text('Todas las regiones'));
      await tester.pumpAndSettle();

      expect(notifier.regionCalls, [null]);
    },
  );

  testWidgets(
    'FeedScreen: elegir una región concreta en el selector la manda a '
    'setRegionManually',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });

      final notifier = _FakeFeedNotifier();
      await tester.pumpWidget(_buildSubject(notifier: notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Araucanía'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Región del Maule'));
      await tester.pumpAndSettle();

      expect(notifier.regionCalls, ['Región del Maule']);
    },
  );
}
