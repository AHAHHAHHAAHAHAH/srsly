import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITOLO
          const Text(
            'Impostazioni',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 32),

          // SEZIONE ACCOUNT
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              subtitle: const Text('Esci dall’applicazione'),
              onTap: () async {
                // LOGOUT FIREBASE
                await FirebaseAuth.instance.signOut();

                // TORNA AL LOGIN E PULISCE LO STACK
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // SEZIONE INFO (pronta per crescere)
          const Text(
            'Informazioni',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Versione app'),
              subtitle: const Text('1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}
