import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forrealeapp/app.dart';
import 'package:forrealeapp/main.dart';

void main() {
  testWidgets('Login screen is shown', (WidgetTester tester) async {
    // Avvia l'app
    await tester.pumpWidget(const MyApp());

    // Controlla che il titolo della schermata login esista
    expect(find.text('Accesso Smacchiatoria'), findsOneWidget);

    // Controlla che i campi di input siano presenti
    expect(find.text('Nome azienda'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Controlla che il bottone di login esista
    expect(find.text('Accedi'), findsOneWidget);
  });
}
