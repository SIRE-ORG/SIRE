import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sire/core/network/app_exception.dart';
import 'package:sire/features/auth/data/datasources/auth_supabase_datasource.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';
import 'package:sire/features/auth/domain/repositories/auth_repository.dart';
import 'package:sire/features/auth/presentation/providers/auth_provider.dart';
import 'package:sire/features/reservations/domain/entities/reservation.dart';
import 'package:sire/features/reservations/domain/entities/reservation_eligibility.dart';
import 'package:sire/features/reservations/domain/repositories/reservations_repository.dart';
import 'package:sire/features/reservations/presentation/providers/reservation_eligibility_provider.dart';
import 'package:sire/features/reservations/presentation/providers/reservations_provider.dart';
import 'package:sire/features/reservations/presentation/screens/reservation_confirm_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockReservationsRepository extends Mock
    implements ReservationsRepository {}

class MockAuthSupabaseDatasource extends Mock
    implements AuthSupabaseDatasource {}

const _guestProfile = UserProfile(
  id: 'guest-1',
  name: 'María Torres',
  email: 'maria@correo.com',
  accountStatus: AccountStatus.guest,
  emailVerified: false,
);

const _createdReservation = Reservation(
  id: 'res-1',
  publicationId: 'pub-001',
  date: '2026-07-15',
  startTime: '10:00',
  endTime: '11:00',
  status: ReservationStatus.pending,
  createdAt: '2026-07-01T00:00:00Z',
);

void main() {
  late MockAuthRepository authRepo;
  late MockReservationsRepository resRepo;
  late MockAuthSupabaseDatasource supabaseDs;

  setUp(() {
    authRepo = MockAuthRepository();
    resRepo = MockReservationsRepository();
    supabaseDs = MockAuthSupabaseDatasource();
    // Por defecto ya hay sesión anónima (caso feliz: welcome la creó):
    // _ensureSession no necesita llamar signInAnonymously.
    when(() => supabaseDs.getCurrentUserId()).thenReturn('anon-1');
  });

  void suppressOverflow(WidgetTester tester) {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = original;
      tester.view.resetPhysicalSize();
    });
    tester.view.physicalSize = const Size(1080, 2400);
  }

  Widget buildSubject({
    required ReservationEligibility eligibility,
    UserProfile? profile,
    String date = '2026-07-15',
    String time = '10:00',
  }) {
    final router = GoRouter(
      initialLocation: '/confirm',
      routes: [
        GoRoute(
          path: '/confirm',
          builder: (_, _) => ReservationConfirmScreen(
            id: 'pub-001',
            title: 'Cancha de fútbol sintética',
            subtitle: 'Club Deportivo Temuco',
            date: date,
            time: time,
          ),
        ),
        GoRoute(
          path: '/my-reservations',
          builder: (_, _) => const Scaffold(body: Text('Mis Reservas')),
        ),
        GoRoute(
          path: '/verify-otp',
          builder: (_, _) => const Scaffold(body: Text('Verificar OTP')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        reservationEligibilityProvider.overrideWith((ref) async => eligibility),
        currentProfileProvider.overrideWith((ref) async => profile),
        authRepositoryProvider.overrideWithValue(authRepo),
        reservationsRepositoryProvider.overrideWithValue(resRepo),
        authSupabaseDatasourceProvider.overrideWithValue(supabaseDs),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('needsGuestForm', () {
    testWidgets('muestra encabezado, título y campos del formulario', (
      tester,
    ) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildSubject(eligibility: ReservationEligibility.needsGuestForm),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmar Reserva'), findsWidgets);
      expect(find.text('Cancha de fútbol sintética'), findsOneWidget);
      expect(find.text('Club Deportivo Temuco'), findsOneWidget);
      expect(find.text('Nombre Completo'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Teléfono'), findsOneWidget);
    });

    testWidgets('muestra resumen de fecha (dd/MM/yyyy) y hora', (tester) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildSubject(eligibility: ReservationEligibility.needsGuestForm),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('15/07/2026'), findsOneWidget);
      expect(find.textContaining('10:00'), findsOneWidget);
    });

    testWidgets('formulario vacío deja el botón Confirmar deshabilitado', (
      tester,
    ) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildSubject(eligibility: ReservationEligibility.needsGuestForm),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('correo con formato inválido mantiene botón deshabilitado', (
      tester,
    ) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildSubject(eligibility: ReservationEligibility.needsGuestForm),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'María Torres');
      await tester.enterText(fields.at(1), 'esto-no-es-un-correo');
      await tester.enterText(fields.at(2), '+56912345678');
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets(
      'formulario válido confirma: registerGuest -> createReservation -> '
      'modal de éxito',
      (tester) async {
        suppressOverflow(tester);
        when(
          () => authRepo.registerGuest(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer(
          (_) async => const AuthResult(
            userId: 'guest-1',
            accountStatus: AccountStatus.guest,
            userCreated: true,
          ),
        );
        when(
          () => resRepo.createReservation(
            publicationId: any(named: 'publicationId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => _createdReservation);

        await tester.pumpWidget(
          buildSubject(eligibility: ReservationEligibility.needsGuestForm),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'María Torres');
        await tester.enterText(fields.at(1), 'maria@correo.com');
        await tester.enterText(fields.at(2), '+56912345678');
        await tester.pump();

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.pumpAndSettle();

        verify(
          () => authRepo.registerGuest(
            name: 'María Torres',
            email: 'maria@correo.com',
            phone: '+56912345678',
          ),
        ).called(1);
        // La fecha enviada es la del slot (widget.date, ISO), no un DatePicker.
        verify(
          () => resRepo.createReservation(
            publicationId: 'pub-001',
            date: '2026-07-15',
            startTime: '10:00',
            endTime: '11:00',
          ),
        ).called(1);
        expect(find.text('¡Reserva confirmada!'), findsOneWidget);
      },
    );

    testWidgets(
      'sin sesión Supabase, crea la sesión anónima antes de registerGuest '
      '(F-D)',
      (tester) async {
        suppressOverflow(tester);
        // Sin sesión: welcome pudo fallar o nunca ejecutarse (deep-link,
        // red móvil).
        when(() => supabaseDs.getCurrentUserId()).thenReturn(null);
        when(() => authRepo.signInAnonymously()).thenAnswer((_) async {});
        when(
          () => authRepo.registerGuest(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer(
          (_) async => const AuthResult(
            userId: 'guest-1',
            accountStatus: AccountStatus.guest,
            userCreated: true,
          ),
        );
        when(
          () => resRepo.createReservation(
            publicationId: any(named: 'publicationId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => _createdReservation);

        await tester.pumpWidget(
          buildSubject(eligibility: ReservationEligibility.needsGuestForm),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'María Torres');
        await tester.enterText(fields.at(1), 'maria@correo.com');
        await tester.enterText(fields.at(2), '+56912345678');
        await tester.pump();

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.pumpAndSettle();

        verify(() => authRepo.signInAnonymously()).called(1);
        verify(
          () => authRepo.registerGuest(
            name: 'María Torres',
            email: 'maria@correo.com',
            phone: '+56912345678',
          ),
        ).called(1);
        expect(find.text('¡Reserva confirmada!'), findsOneWidget);
      },
    );

    testWidgets(
      'sin sesión Supabase y falla signInAnonymously: error claro, no '
      'llama registerGuest',
      (tester) async {
        suppressOverflow(tester);
        when(() => supabaseDs.getCurrentUserId()).thenReturn(null);
        when(() => authRepo.signInAnonymously()).thenThrow(NetworkException());

        await tester.pumpWidget(
          buildSubject(eligibility: ReservationEligibility.needsGuestForm),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'María Torres');
        await tester.enterText(fields.at(1), 'maria@correo.com');
        await tester.enterText(fields.at(2), '+56912345678');
        await tester.pump();

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'No se pudo iniciar tu sesión. Revisa tu conexión e intenta '
            'nuevamente.',
          ),
          findsOneWidget,
        );
        verifyNever(
          () => authRepo.registerGuest(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        );
      },
    );

    testWidgets(
      'correo ya registrado (ConflictException) muestra aviso y no crea '
      'la reserva',
      (tester) async {
        suppressOverflow(tester);
        when(
          () => authRepo.registerGuest(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenThrow(ConflictException(code: 'EMAIL_TAKEN'));

        await tester.pumpWidget(
          buildSubject(eligibility: ReservationEligibility.needsGuestForm),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'María Torres');
        await tester.enterText(fields.at(1), 'maria@correo.com');
        await tester.enterText(fields.at(2), '+56912345678');
        await tester.pump();

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Este correo ya tiene cuenta; inicia sesión'),
          findsOneWidget,
        );
        verifyNever(
          () => resRepo.createReservation(
            publicationId: any(named: 'publicationId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        );
      },
    );

    testWidgets(
      'fallo de red al crear la reserva muestra SnackBar de sin conexión',
      (tester) async {
        suppressOverflow(tester);
        when(
          () => authRepo.registerGuest(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer(
          (_) async => const AuthResult(
            userId: 'guest-1',
            accountStatus: AccountStatus.guest,
            userCreated: true,
          ),
        );
        when(
          () => resRepo.createReservation(
            publicationId: any(named: 'publicationId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenThrow(NetworkException());

        await tester.pumpWidget(
          buildSubject(eligibility: ReservationEligibility.needsGuestForm),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'María Torres');
        await tester.enterText(fields.at(1), 'maria@correo.com');
        await tester.enterText(fields.at(2), '+56912345678');
        await tester.pump();

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.pumpAndSettle();

        // NetworkException tiene mensaje propio (encargo H6): "sin conexión",
        // no el genérico.
        expect(find.textContaining('Sin conexión'), findsOneWidget);
      },
    );

    testWidgets(
      'fecha del slot no parseable (no ISO) muestra error controlado y no '
      'llama al backend',
      (tester) async {
        suppressOverflow(tester);

        await tester.pumpWidget(
          buildSubject(
            eligibility: ReservationEligibility.needsGuestForm,
            date: 'Lun 15 jun',
          ),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'María Torres');
        await tester.enterText(fields.at(1), 'maria@correo.com');
        await tester.enterText(fields.at(2), '+56912345678');
        await tester.pump();

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.pump();

        expect(
          find.textContaining('No se pudo determinar la fecha'),
          findsOneWidget,
        );
        verifyNever(
          () => authRepo.registerGuest(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        );
      },
    );
  });

  group('allowed / allowedExistingProfile', () {
    for (final elig in [
      ReservationEligibility.allowed,
      ReservationEligibility.allowedExistingProfile,
    ]) {
      testWidgets('($elig) oculta el formulario y confirma directo', (
        tester,
      ) async {
        suppressOverflow(tester);
        when(
          () => resRepo.createReservation(
            publicationId: any(named: 'publicationId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => _createdReservation);

        await tester.pumpWidget(
          buildSubject(eligibility: elig, profile: _guestProfile),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nombre Completo'), findsNothing);
        expect(find.text('Correo'), findsNothing);

        final btn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        expect(btn.onPressed, isNotNull);

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.pumpAndSettle();

        verifyNever(
          () => authRepo.registerGuest(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        );
        verify(
          () => resRepo.createReservation(
            publicationId: 'pub-001',
            date: '2026-07-15',
            startTime: '10:00',
            endTime: '11:00',
          ),
        ).called(1);
        expect(find.text('¡Reserva confirmada!'), findsOneWidget);
      });
    }
  });

  group('needsActivation', () {
    testWidgets('oculta form y botón Confirmar; muestra aviso y Activar '
        'cuenta', (tester) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildSubject(
          eligibility: ReservationEligibility.needsActivation,
          profile: _guestProfile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nombre Completo'), findsNothing);
      expect(
        find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        findsNothing,
      );
      expect(find.text('Activar cuenta'), findsOneWidget);
      expect(find.textContaining('Ya hiciste una reserva'), findsOneWidget);
    });

    testWidgets('tap Activar cuenta llama updateEmail y navega a /verify-otp', (
      tester,
    ) async {
      suppressOverflow(tester);
      when(
        () => authRepo.updateEmail(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildSubject(
          eligibility: ReservationEligibility.needsActivation,
          profile: _guestProfile,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Activar cuenta'));
      await tester.pumpAndSettle();

      verify(() => authRepo.updateEmail(email: 'maria@correo.com')).called(1);
      expect(find.text('Verificar OTP'), findsOneWidget);
    });
  });

  group('interacciones comunes', () {
    testWidgets('tap Cancelar reserva muestra SnackBar de función no '
        'disponible', (tester) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildSubject(eligibility: ReservationEligibility.allowed),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cancelar reserva'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar reserva'));
      await tester.pump();

      expect(find.text('Función no disponible aún'), findsOneWidget);
    });

    testWidgets('AppBar tiene botón de retroceso', (tester) async {
      suppressOverflow(tester);

      await tester.pumpWidget(
        buildSubject(eligibility: ReservationEligibility.allowed),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });
  });

  // Regresión F1/F4: usa la cadena REAL de providers (authRepositoryProvider
  // + reservationsRepositoryProvider), sin override estático de
  // reservationEligibilityProvider ni de currentProfileProvider, para
  // verificar que `create()` invalida de verdad la elegibilidad cacheada.
  group('F1 (regresión) - invalidación real tras crear', () {
    Widget buildRealSubject() {
      final router = GoRouter(
        initialLocation: '/confirm',
        routes: [
          GoRoute(
            path: '/confirm',
            builder: (_, _) => const ReservationConfirmScreen(
              id: 'pub-001',
              title: 'Cancha de fútbol sintética',
              subtitle: 'Club Deportivo Temuco',
              date: '2026-07-15',
              time: '10:00',
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          reservationsRepositoryProvider.overrideWithValue(resRepo),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('tras crear la reserva, la elegibilidad real recalcula de '
        'allowedExistingProfile a needsActivation para un guest', (
      tester,
    ) async {
      suppressOverflow(tester);
      when(() => authRepo.getProfile()).thenAnswer((_) async => _guestProfile);

      var reservationCreated = false;
      when(() => resRepo.getMyReservations()).thenAnswer(
        (_) async => reservationCreated ? [_createdReservation] : [],
      );
      when(
        () => resRepo.createReservation(
          publicationId: any(named: 'publicationId'),
          date: any(named: 'date'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async {
        reservationCreated = true;
        return _createdReservation;
      });

      await tester.pumpWidget(buildRealSubject());
      await tester.pumpAndSettle();

      // Elegibilidad inicial real: guest con 0 reservas -> confirma
      // directo, sin formulario de invitado.
      expect(find.text('Nombre Completo'), findsNothing);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
      );
      expect(btn.onPressed, isNotNull);

      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
      );
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Reserva confirmada!'), findsOneWidget);

      // Sin el fix F1, reservationEligibilityProvider quedaba cacheado en
      // allowedExistingProfile tras crear y el guest podía reservar de
      // nuevo saltándose la regla de negocio 4.
      final context = tester.element(find.byType(ReservationConfirmScreen));
      final container = ProviderScope.containerOf(context);
      final eligibility = container.read(reservationEligibilityProvider);
      expect(eligibility.value, ReservationEligibility.needsActivation);
    });
  });

  group('F1 (regresión) - back del sistema no cierra el modal de éxito', () {
    testWidgets(
      'PopScope bloquea Navigator.maybePop sobre el diálogo de éxito',
      (tester) async {
        suppressOverflow(tester);
        when(
          () => authRepo.registerGuest(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer(
          (_) async => const AuthResult(
            userId: 'guest-1',
            accountStatus: AccountStatus.guest,
            userCreated: true,
          ),
        );
        when(
          () => resRepo.createReservation(
            publicationId: any(named: 'publicationId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => _createdReservation);

        await tester.pumpWidget(
          buildSubject(eligibility: ReservationEligibility.needsGuestForm),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'María Torres');
        await tester.enterText(fields.at(1), 'maria@correo.com');
        await tester.enterText(fields.at(2), '+56912345678');
        await tester.pump();

        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Confirmar Reserva'),
        );
        await tester.pumpAndSettle();

        expect(find.text('¡Reserva confirmada!'), findsOneWidget);

        // Simula el botón back del sistema (Android): sin
        // PopScope(canPop: false), Navigator.maybePop() cerraría esta ruta
        // modal aunque barrierDismissible sea false.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('¡Reserva confirmada!'), findsOneWidget);
      },
    );
  });
}
