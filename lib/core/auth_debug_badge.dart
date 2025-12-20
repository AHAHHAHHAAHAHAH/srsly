import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthDebugBadge extends StatelessWidget {
  const AuthDebugBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final u = snap.data;
        final text = u == null ? 'AUTH: null' : 'AUTH: ${u.email}';
        return Positioned(
          right: 8,
          bottom: 8,
          child: Material(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      },
    );
  }
}
