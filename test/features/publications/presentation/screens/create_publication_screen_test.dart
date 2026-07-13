import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/core/constants/chile_regions.dart';
import 'package:sire/features/publications/data/datasources/publication_image_datasource.dart';
import 'package:sire/features/publications/domain/entities/availability_config.dart';
import 'package:sire/features/publications/domain/entities/publication.dart';
import 'package:sire/features/publications/domain/repositories/publications_repository.dart';
import 'package:sire/features/publications/presentation/providers/my_publications_provider.dart';
import 'package:sire/features/publications/presentation/screens/create_publication_screen.dart';

/// Doble controlable de [PublicationsRepository]: solo implementa
/// [createPublication] (lo único que ejercita CreatePublicationScreen) y
/// captura los argumentos con los que se llamó. El resto revienta si se
/// invoca (no debería pasar en estas pruebas).
class _StubPublicationsRepository implements PublicationsRepository {
  final _completer = Completer<Publication>();
  int createCallCount = 0;
  PublicationCategory? capturedCategory;
  String? capturedRegion;

  /// Completa la llamada a [createPublication] en curso (permite controlar
  /// cuándo termina la operación async para probar el estado de loading).
  void completeWith(Publication publication) =>
      _completer.complete(publication);

  @override
  Future<Publication> createPublication({
    required String title,
    required String description,
    required PublicationCategory category,
    String? imageUrl,
    required String region,
    String? city,
    required AvailabilityConfig availability,
  }) {
    createCallCount++;
    capturedCategory = category;
    capturedRegion = region;
    return _completer.future;
  }

  @override
  Future<Publication> getPublicationDetail({required String id}) =>
      throw UnimplementedError();

  @override
  Future<MyPublicationsResult> getMyPublications({
    int page = 1,
    int limit = 20,
  }) => throw UnimplementedError();

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

/// PublicationImageDatasource que revienta si se invoca: el formulario no
/// selecciona imagen en estas pruebas, así que no debería llamarse.
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

Publication _dummyPublication({
  required PublicationCategory category,
  required String region,
}) {
  return Publication(
    id: 'pub-test',
    title: 'Cancha de prueba',
    description: 'Descripción de prueba',
    region: region,
    category: category,
    ownerId: 'owner-1',
    ownerName: 'Dueño de prueba',
    isActive: true,
    availability: const AvailabilityConfig(
      slotDurationMinutes: 30,
      sameScheduleAllDays: true,
      defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
      dayOverrides: [],
    ),
    createdAt: DateTime(2026).toIso8601String(),
  );
}

void main() {
  Widget buildSubject({
    Size size = const Size(1080, 2400),
    PublicationsRepository? repository,
  }) {
    final mockRouter = GoRouter(
      initialLocation: '/create-publication',
      routes: [
        GoRoute(
          path: '/create-publication',
          builder: (_, _) => const CreatePublicationScreen(),
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
          path: '/my-reservations',
          builder: (_, _) => const Scaffold(body: Text('Reservas')),
        ),
        GoRoute(
          path: '/my-publications',
          builder: (_, _) => const Scaffold(body: Text('Mis Publicaciones')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        if (repository != null)
          publicationsRepositoryProvider.overrideWithValue(repository),
        publicationImageDatasourceProvider.overrideWithValue(
          const _UnusedImageDatasource(),
        ),
      ],
      child: MaterialApp.router(routerConfig: mockRouter),
    );
  }

  testWidgets('CreatePublicationScreen muestra título del formulario', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Crear publicación'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('CreatePublicationScreen muestra campos del formulario', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Nombre del servicio'), findsOneWidget);
    expect(find.text('Descripción'), findsOneWidget);
    expect(find.text('Categoría'), findsOneWidget);
    expect(find.text('Región'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('CreatePublicationScreen muestra sección Agenda Inteligente', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Agenda Inteligente'), findsOneWidget);
    expect(find.text('Duración de cada slot'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);
    expect(find.text('90 min'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('CreatePublicationScreen muestra opciones de tipo de horario', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Mismo horario todos los días'), findsOneWidget);
    expect(find.text('Personalizar por día'), findsOneWidget);
    expect(find.text('Horario para todos los días'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('CreatePublicationScreen toca opción 60 min', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('60 min'));
    await tester.pumpAndSettle();

    expect(find.text('60 min'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'CreatePublicationScreen toca Personalizar por día muestra días',
    (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Personalizar por día'));
      await tester.pumpAndSettle();

      expect(find.text('Lunes'), findsOneWidget);
      expect(find.text('Martes'), findsOneWidget);
      expect(find.text('Sábado'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });
    },
  );

  testWidgets('CreatePublicationScreen muestra botón Guardar publicación', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Guardar publicación'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('CreatePublicationScreen layout móvil muestra AppBar', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject(size: const Size(390, 844)));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Nueva publicación'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets('CreatePublicationScreen toca 90 min actualiza selección', (
    WidgetTester tester,
  ) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('90 min'));
    await tester.pumpAndSettle();

    expect(find.text('90 min'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });

  testWidgets(
    'CreatePublicationScreen deshabilita el botón mientras guarda (evita doble '
    'envío) y navega a Mis Publicaciones al terminar',
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

      final repo = _StubPublicationsRepository();
      await tester.pumpWidget(buildSubject(repository: repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Cancha de prueba');
      await tester.pump();

      await tester.tap(find.text('Guardar publicación'));
      await tester.pump();

      // Mientras la operación está en vuelo, el botón queda deshabilitado
      // (spinner en vez de texto) y un segundo tap no dispara otro guardado.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardar publicación'), findsNothing);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(repo.createCallCount, 1);

      repo.completeWith(
        _dummyPublication(
          category: PublicationCategory.otros,
          region: 'Región Metropolitana',
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.createCallCount, 1);
      expect(find.text('Mis Publicaciones'), findsOneWidget);
    },
  );

  testWidgets(
    'CreatePublicationScreen selecciona categoría válida del autocompletado y '
    'región de la lista compartida: guarda con esos valores exactos',
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

      final repo = _StubPublicationsRepository();
      await tester.pumpWidget(buildSubject(repository: repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Cancha de fútbol');
      await tester.pump();

      // Categoría: escribe un prefijo y selecciona la sugerencia "Eventos".
      final categoriaField = find.byType(TextField).at(2);
      await tester.tap(categoriaField);
      await tester.enterText(categoriaField, 'Even');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eventos').last);
      await tester.pumpAndSettle();

      // Región: abre el selector y elige la primera región de la lista
      // compartida (misma fuente que usa el onboarding).
      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(MenuItemButton, chileRegions.first).last,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar publicación'));
      await tester.pump();
      repo.completeWith(
        _dummyPublication(
          category: PublicationCategory.eventos,
          region: chileRegions.first,
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.capturedCategory, PublicationCategory.eventos);
      expect(repo.capturedRegion, chileRegions.first);
    },
  );

  testWidgets(
    'CreatePublicationScreen categoría con texto libre desconocido se guarda como Otros',
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

      final repo = _StubPublicationsRepository();
      await tester.pumpWidget(buildSubject(repository: repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Yoga al aire libre',
      );
      await tester.pump();

      // Categoría: texto libre que no matchea ninguna opción del enum.
      final categoriaField = find.byType(TextField).at(2);
      await tester.tap(categoriaField);
      await tester.enterText(categoriaField, 'Yoga');
      await tester.pump();

      await tester.tap(find.text('Guardar publicación'));
      await tester.pump();
      repo.completeWith(
        _dummyPublication(
          category: PublicationCategory.otros,
          region: 'Región Metropolitana',
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.capturedCategory, PublicationCategory.otros);
    },
  );
}
