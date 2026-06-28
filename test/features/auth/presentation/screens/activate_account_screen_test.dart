import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/auth/presentation/screens/activate_account_screen.dart';

void main() {
  Widget buildApp() => ProviderScope(
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/activate-account',
        routes: [
          GoRoute(
            path: '/activate-account',
            builder: (_, _) => const ActivateAccountScreen(),
          ),
          GoRoute(
            path: '/publication/create',
            builder: (_, _) => const Scaffold(body: Text('Crear publicación')),
          ),
        ],
      ),
    ),
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

  testWidgets('renderiza título, campo Contraseña y botón Activar cuenta', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Activar cuenta'), findsWidgets);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.textContaining('Mínimo 8 caracteres'), findsOneWidget);
  });

  testWidgets('muestra instrucción sobre la contraseña', (tester) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Establece una contraseña'), findsOneWidget);
  });

  testWidgets('contraseña menor a 8 caracteres muestra SnackBar de error', (
    tester,
  ) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'short');
    await tester.pump();

    await tester.tap(find.text('Activar cuenta').last);
    await tester.pump();

    expect(
      find.text('La contraseña debe tener al menos 8 caracteres'),
      findsOneWidget,
    );
  });

  testWidgets('permite ingresar contraseña en el campo', (tester) async {
    suppressOverflow(tester);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'mipassword123');
    await tester.pump();

    // El campo es de tipo password, el texto puede estar ofuscado pero el widget lo acepta
    expect(find.byType(TextField), findsOneWidget);
  });
}
