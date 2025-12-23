import 'package:flutter/material.dart';
import '../core/auth_controller.dart';

class AuthDebugBadge extends StatelessWidget {
  const AuthDebugBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthController.instance.email;
    final companyId = AuthController.instance.companyId ?? '—';

    if (email.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text(
        'auth: $email | company: $companyId',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
