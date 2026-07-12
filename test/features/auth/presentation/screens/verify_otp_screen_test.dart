import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/auth/presentation/screens/verify_otp_screen.dart';

void main() {
  GoRouter buildRouter({Object? extra}) => GoRouter(
    initialLocation: '/verify-otp',
    initialExtra: extra,
    routes: [
      GoRoute(path: '/verify-otp', builder: (_, _) => const VerifyOtpScreen()),
      GoRoute(
        path: '/activate-account',
        builder: (_, _) => const Scaffold(body: Text('Activar cuenta')),
      ),
    ],
  );

  Widget buildApp({Object? extra}) => ProviderScope(
    child: MaterialApp.router(routerConfig: buildRouter(extra: extra)),
  );

  void suppressOverflow(WidgetTester tester) {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      original?.call(d);
    };
    addTearDown(() {
      FlutterError.onError = original;
      tester.view.resetPhysicalSize();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('renderiza título, campo Código y botón Verificar', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Verificar código'), findsOneWidget);
    expect(find.text('Código'), findsOneWidget);
    expect(find.text('Verificar'), findsOneWidget);
  });

  testWidgets('muestra instrucción sobre el código de 6 dígitos', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('6 dígitos'), findsOneWidget);
  });

  testWidgets('código menor a 6 dígitos muestra SnackBar de error', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123');
    await tester.pump();

    await tester.tap(find.text('Verificar'));
    await tester.pump();

    expect(find.text('Ingresa el código de 6 dígitos'), findsOneWidget);
  });

  testWidgets('permite ingresar texto en el campo de código', (tester) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();

    expect(find.text('123456'), findsOneWidget);
  });

  testWidgets('contexto activación (otpType emailChange) cambia título y copy', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(
      buildApp(
        extra: {'email': 'ana@mail.com', 'otpType': 'emailChange'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activa tu cuenta'), findsOneWidget);
    expect(find.text('Verificar código'), findsNothing);
    expect(find.textContaining('ana@mail.com'), findsOneWidget);
  });

  testWidgets('contexto registro directo muestra el correo del extra', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(
      buildApp(extra: {'email': 'ana@mail.com', 'otpType': 'email'}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verificar código'), findsOneWidget);
    expect(find.textContaining('ana@mail.com'), findsOneWidget);
  });
}
