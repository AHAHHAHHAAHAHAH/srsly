import 'package:flutter/material.dart';
import '../core/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header + account
          Row(
            children: [
              const Text(
                'Impostazioni',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              StreamBuilder(
                stream: AuthController.instance.authState,
                builder: (context, snapshot) {
                  final email = snapshot.data?.email ?? AuthController.instance.email ?? '-';
                  return Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Utente loggato: ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextSpan(
                          text: email,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // logout rosso e "più figo"
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              await AuthController.instance.logout();
            },
          ),

          const Spacer(),

          const Text(
            'Versione 1.0.0',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
