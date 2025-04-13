// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:preparatorio_concursos/app.dart';
import 'package:preparatorio_concursos/core/auth/auth_service.dart';

void main() {
  testWidgets('App deve inicializar sem erros', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>(
        create: (_) => AuthService(),
        child: const PreparatorioConcursosApp(),
      ),
    );

    // Verificar se o app foi inicializado sem erros
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
