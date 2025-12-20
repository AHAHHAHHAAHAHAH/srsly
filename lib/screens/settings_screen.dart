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
          const Text(
            'Impostazioni',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 32),

          // ===== LOGOUT BUTTON (DANGER)
          SizedBox(
            width: 120,
            height: 36,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith(
                  (states) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.red.shade700.withOpacity(0.15);
                    }
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.red.shade900.withOpacity(0.25);
                    }
                    return null;
                  },
                ),
              ),
              onPressed: () async {
                await AuthController.instance.logout();
              },
            ),
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
