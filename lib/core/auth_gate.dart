import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_controller.dart';
import '../screens/login_screen.dart';
import '../shell/app_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: AuthController.user,
      builder: (context, user, _) {
        if (user == null) {
          return const LoginScreen();
        }
        return AppShell();
      },
    );
  }
}
