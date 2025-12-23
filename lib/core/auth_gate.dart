import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/login_screen.dart';
import '../shell/app_shell.dart';
import 'auth_controller.dart';
import '../screens/auth_error_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // IMPORTANTISSIMO:
    // - nessun setState qui
    // - nessuna init "side effect" dentro builder
    return StreamBuilder<User?>(
      stream: AuthController.instance.authState,
      builder: (context, snap) {
        // Loading primo aggancio stream
        if (snap.connectionState == ConnectionState.waiting) {
          return const _CenterLoading();
        }

        final user = snap.data;
        if (user == null) {
          return const LoginScreen();
        }

        // User presente -> inizializzazione profilo (FutureBuilder)
        // Così NON facciamo nulla durante build dello StreamBuilder.
        return FutureBuilder<void>(
          future: AuthController.instance.ensureInitialized(),
          builder: (context, initSnap) {
            if (initSnap.connectionState == ConnectionState.waiting) {
              return const _CenterLoading();
            }

            if (initSnap.hasError) {
              final msg = AuthController.instance.lastError ?? initSnap.error.toString();

              return AuthInitErrorScreen(
                message: msg,
              );
            }

            return const AppShell();
          },
        );
      },
    );
  }
}

class _CenterLoading extends StatelessWidget {
  const _CenterLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
