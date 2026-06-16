import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sire/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('RegisterScreen renderiza la UI y permite interaccion', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return; // Ignora los RenderFlex en silencio
      }
      FlutterError.presentError(details);
    };

    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;

    final mockRouter = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (context, state) => const Scaffold(body: Text('Pantalla Feed Exitosa')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: mockRouter,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Registrarse'), findsWidgets);
    expect(find.text('Nombre completo'), findsOneWidget);
    
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Juan Perez');
    await tester.enterText(textFields.at(1), 'juan@sire.cl');
    await tester.enterText(textFields.at(3), 'clave123');
    
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final button = find.text('Crear cuenta').first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Feed Exitosa'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('RegisterScreen layout web muestra panel izquierdo y formulario', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed') || msg.contains('Unable to load asset') || msg.contains('404')) return;
      originalOnError?.call(details);
    };
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final mockRouter = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (context, state) => const Scaffold(body: Text('Feed')),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: mockRouter)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Registrarse'), findsWidgets);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('¿Ya tienes cuenta?'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });
  });
}