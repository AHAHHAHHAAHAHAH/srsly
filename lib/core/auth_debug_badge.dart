import 'package:flutter/material.dart';
import 'auth_controller.dart';

class AuthDebugBadge extends StatelessWidget {
  const AuthDebugBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        color: Colors.black54,
        child: Text(
          user?.email ?? 'NOT LOGGED',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
