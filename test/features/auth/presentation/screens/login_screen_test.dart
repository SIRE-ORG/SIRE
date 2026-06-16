import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sire/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen UI y validacion de campos', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Bienvenido a SIRE'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsWidgets);

    final textFields = find.byType(TextField);
    
    await tester.enterText(textFields.first, 'usuario@prueba.com');
    await tester.enterText(textFields.last, '123456');
    await tester.pump();

    expect(find.text('usuario@prueba.com'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
  });
}