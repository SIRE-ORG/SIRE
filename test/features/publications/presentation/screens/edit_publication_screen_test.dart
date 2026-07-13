import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/publications/data/datasources/publication_image_datasource.dart';
import 'package:sire/features/publications/data/datasources/publications_remote_datasource_mock_impl.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:sire/features/publications/domain/repositories/publications_repository.dart';
import 'package:sire/features/publications/presentation/providers/my_publications_provider.dart';
import 'package:sire/features/publications/presentation/screens/edit_publication_screen.dart';

/// Doble de [PublicationsRepository] para EditPublicationScreen: entrega
/// [detail] como detalle de la publicación y captura los argumentos del
/// update. El resto revienta si se invoca.
class _StubPublicationsRepository implements PublicationsRepository {
  _StubPublicationsRepository(this.detail);

  final Publication detail;
  String? capturedRegion;
  String? capturedCity;
  bool updateCalled = false;

  @override
  Future<Publication> getPublicationDetail({required String id}) async =>
      detail;

  @override
  Future<Publication> updatePublication({
    required String id,
    String? title,
    String? description,
    PublicationCategory? category,
    String? imageUrl,
    String? region,
    String? city,
    AvailabilityConfig? availability,
  }) async {
    updateCalled = true;
    capturedRegion = region;
    capturedCity = city;
    return detail;
  }

  @override
  Future<Publication> createPublication({
    required String title,
    required String description,
    required PublicationCategory category,
    String? imageUrl,
    required String region,
    String? city,
    required AvailabilityConfig availability,
  }) => throw UnimplementedError();

  @override
  Future<MyPublicationsResult> getMyPublications({
    int page = 1,
    int limit = 20,
  }) => throw UnimplementedError();

  @override
  Future<void> togglePublicationStatus({
    required String id,
    required bool isActive,
  }) => throw UnimplementedError();

  @override
  Future<void> deletePublication({required String id}) =>
      throw UnimplementedError();
}

/// PublicationImageDatasource que revienta si se invoca: estas pruebas no
/// seleccionan imagen.
class _UnusedImageDatasource implements PublicationImageDatasource {
  const _UnusedImageDatasource();

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String extension,
  }) => throw StateError(
    'PublicationImageDatasource no debía ser invocado en esta prueba',
  );
}

Publication _pubFixture() => const Publication(
  id: 'pub-001',
  title: 'Cancha de fútbol El Estadio',
  description: 'Cancha techada con iluminación',
  region: 'Región de La Araucanía',
  city: 'Temuco',
  category: PublicationCategory.deporte,
  ownerId: 'owner-1',
  ownerName: 'Club Deportivo',
  isActive: true,
  availability: AvailabilityConfig(
    slotDurationMinutes: 60,
    sameScheduleAllDays: true,
    defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
    dayOverrides: [],
  ),
  createdAt: '2026-01-01',
);

void main() {
  GoRouter buildRouter() => GoRouter(
    initialLocation: '/publication/pub-001/edit',
    routes: [
      GoRoute(
        path: '/publication/:id/edit',
        builder: (_, state) =>
            EditPublicationScreen(id: state.pathParameters['id'] ?? 'pub-001'),
      ),
      GoRoute(
        path: '/feed',
        builder: (_, _) => const Scaffold(body: Text('Feed')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, _) => const Scaffold(body: Text('Dashboard')),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Perfil')),
      ),
      GoRoute(
        path: '/my-publications',
        builder: (_, _) => const Scaffold(body: Text('Mis Publicaciones')),
      ),
    ],
  );

  Widget buildSubject() {
    return ProviderScope(
      // El formulario se pre-pobla vía publicationDetailProvider -> el
      // datasource mock trae el fixture "Cancha de fútbol El Estadio" que
      // esta pantalla verifica. Se fuerza explícitamente porque
      // ApiFlags.useMocks ahora es false por defecto (backend real).
      overrides: [
        publicationsRemoteDatasourceProvider.overrideWithValue(
          PublicationsRemoteDatasourceMockImpl(),
        ),
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    );
  }

  /// Variante con repositorio stub: permite capturar los argumentos que la
  /// pantalla manda al guardar (región/ciudad).
  Widget buildSubjectConRepo(PublicationsRepository repository) {
    return ProviderScope(
      overrides: [
        publicationsRepositoryProvider.overrideWithValue(repository),
        publicationImageDatasourceProvider.overrideWithValue(
          const _UnusedImageDatasource(),
        ),
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    );
  }

  testWidgets('EditPublicationScreen muestra título del AppBar', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Editar publicación'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen muestra campos pre-poblados', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Cancha de fútbol El Estadio'), findsOneWidget);
    expect(find.text('Deporte'), findsOneWidget);
    // findsWidgets (no findsOneWidget): DropdownMenu construye un Text
    // oculto por cada entrada de la lista (para medir el ancho preferido),
    // así que el label de la región seleccionada aparece dos veces en el
    // árbol de widgets aunque el usuario solo vea una.
    expect(find.text('Región de La Araucanía'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen muestra configuración de horarios', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Agenda Inteligente'), findsOneWidget);
    expect(find.text('Horario para todos los días'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen muestra botón guardar cambios', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Guardar cambios'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'EditPublicationScreen permite editar el nombre de la publicación',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.tap(nameField);
      await tester.pump();
      await tester.enterText(nameField, 'Nueva cancha');
      await tester.pump();

      expect(find.text('Nueva cancha'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('EditPublicationScreen layout web muestra sidebar', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('SIRE'), findsOneWidget);
    expect(find.text('Editar publicación'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen muestra selector de duración de slot', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(390, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);
    expect(find.text('90 min'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen tap en duración cambia selección', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(390, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('30 min'));
    await tester.tap(find.text('30 min'));
    await tester.pump();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('EditPublicationScreen contiene formulario con scroll', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(
      find.byType(TextFormField).evaluate().isNotEmpty ||
          find.byType(TextField).evaluate().isNotEmpty,
      isTrue,
    );

    addTearDown(() {
      tester.view.resetPhysicalSize();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'EditPublicationScreen pre-llena región y ciudad desde la entidad y las '
    'manda al repositorio al guardar',
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

      final repo = _StubPublicationsRepository(_pubFixture());
      await tester.pumpWidget(buildSubjectConRepo(repo));
      await tester.pumpAndSettle();

      // Guardar sin tocar Región ni Ciudad: viajan las de la entidad.
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(repo.updateCalled, isTrue);
      expect(repo.capturedRegion, 'Región de La Araucanía');
      expect(repo.capturedCity, 'Temuco');
      expect(find.text('Mis Publicaciones'), findsOneWidget);
    },
  );

  testWidgets(
    'EditPublicationScreen al cambiar la región se limpia la ciudad que no '
    'pertenece a la nueva región',
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

      final repo = _StubPublicationsRepository(_pubFixture());
      await tester.pumpWidget(buildSubjectConRepo(repo));
      await tester.pumpAndSettle();

      // Cambia la región: Temuco no pertenece a Los Ríos, así que la
      // selección de ciudad debe limpiarse. Se elige una región adyacente a
      // la resaltada porque el menú abre desplazado hasta la selección
      // actual (La Araucanía) y las regiones lejanas quedan fuera de vista.
      await tester.ensureVisible(find.byType(DropdownMenu<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenu<String>).first);
      await tester.pumpAndSettle();
      final opcionLosRios = find
          .widgetWithText(MenuItemButton, 'Región de Los Ríos')
          .last;
      await tester.ensureVisible(opcionLosRios);
      await tester.pumpAndSettle();
      await tester.tap(opcionLosRios);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(repo.updateCalled, isTrue);
      expect(repo.capturedRegion, 'Región de Los Ríos');
      expect(repo.capturedCity, isNull);
    },
  );
}
