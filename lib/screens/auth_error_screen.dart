import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';

class AuthInitErrorScreen extends StatelessWidget {
  final String message;

  const AuthInitErrorScreen({
    super.key,
    required this.message,
  });

  Future<void> _backToLogin(BuildContext context) async {
    // logout pulito per evitare stati zombie
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Errore Accesso'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _backToLogin(context),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44),
              const SizedBox(height: 14),
              const Text(
                'Non riesco ad inizializzare il profilo utente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _backToLogin(context),
                icon: const Icon(Icons.logout),
                label: const Text('Torna al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
