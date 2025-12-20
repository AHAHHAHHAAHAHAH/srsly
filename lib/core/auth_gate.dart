import 'package:flutter/material.dart';
import 'auth_controller.dart';
import '../screens/login_screen.dart';
import '../shell/app_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();

    // Avvio UNICO del listener auth
    AuthController.instance.start(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance;

    // 1️⃣ Utente NON loggato
    if (auth.currentUser == null) {
      return const LoginScreen();
    }

    // 2️⃣ Utente loggato ma profilo non inizializzato
    if (!auth.initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 3️⃣ Utente loggato + companyId caricato
    return const AppShell();
  }
}
