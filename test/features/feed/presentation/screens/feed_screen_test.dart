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

  // No-op: el filtro visual lo hace _filterLocally en el widget
  @override
  Future<void> setCategory(PublicationCategory? category) async {}
}

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/feed',
  routes: [
    GoRoute(
      path: '/feed',
      builder: (context, state) => const FeedScreen(),
    ),
  ],
);

Widget _buildSubject() => ProviderScope(
  overrides: [feedNotifierProvider.overrideWith(_FakeFeedNotifier.new)],
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

  testWidgets('FeedScreen filtro Deporte muestra solo publicación de Deporte',
      (WidgetTester tester) async {
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
}
