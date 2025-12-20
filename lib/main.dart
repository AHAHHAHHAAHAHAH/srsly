import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/auth_gate.dart';
import 'core/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 INIZIALIZZA IL CONTROLLER AUTH
  // Questo è CRUCIALE per evitare il bug desktop
  AuthController.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smacchiatoria App',
      theme: ThemeData(
        useMaterial3: true,
       colorSchemeSeed: Colors.indigo,
      ),
      // 🔥 ROOT LOGICO UNICO
      home: const AuthGate(),
    );
  }
}
