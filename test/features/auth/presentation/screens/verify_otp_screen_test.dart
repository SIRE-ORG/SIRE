import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/auth/presentation/screens/verify_otp_screen.dart';

void main() {
  GoRouter _buildRouter({Object? extra}) => GoRouter(
        initialLocation: '/verify-otp',
        routes: [
          GoRoute(
            path: '/verify-otp',
            builder: (_, __) => const VerifyOtpScreen(),
          ),
          GoRoute(
            path: '/activate-account',
            builder: (_, __) =>
                const Scaffold(body: Text('Activar cuenta')),
          ),
        ],
      );

  Widget _buildApp({Object? extra}) => ProviderScope(
        child: MaterialApp.router(
          routerConfig: _buildRouter(extra: extra),
        ),
      );

  void _suppressOverflow(WidgetTester tester) {
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

  testWidgets('renderiza título, campo Código y botón Verificar',
      (tester) async {
    _suppressOverflow(tester);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Verificar código'), findsOneWidget);
    expect(find.text('Código'), findsOneWidget);
    expect(find.text('Verificar'), findsOneWidget);
  });

  testWidgets('muestra instrucción sobre el código de 6 dígitos',
      (tester) async {
    _suppressOverflow(tester);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('6 dígitos'),
      findsOneWidget,
    );
  });

  testWidgets('código menor a 6 dígitos muestra SnackBar de error',
      (tester) async {
    _suppressOverflow(tester);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123');
    await tester.pump();

    await tester.tap(find.text('Verificar'));
    await tester.pump();

    expect(
      find.text('Ingresa el código de 6 dígitos'),
      findsOneWidget,
    );
  });

  testWidgets('permite ingresar texto en el campo de código', (tester) async {
    _suppressOverflow(tester);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();

    expect(find.text('123456'), findsOneWidget);
  });
}
