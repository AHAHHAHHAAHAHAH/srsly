import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <--- IMPORT IMPORTANTE
import 'core/auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestionale',
      // CONFIGURAZIONE LINGUA E LOCALIZZAZIONI
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('it', 'IT'), // Supportiamo l'Italiano
      ],
      locale: Locale('it', 'IT'), // Forziamo l'Italiano di default
      
      home: AuthGate(),
    );
  }
}