import 'package:flutter/material.dart';
import 'auth_controller.dart';

class AuthDebugBadge extends StatelessWidget {
  const AuthDebugBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;

    if (user == null) return const SizedBox();

    return Positioned(
      bottom: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black,
        child: Text(
          user.email ?? 'no-email',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
