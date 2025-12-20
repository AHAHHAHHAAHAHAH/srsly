import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class AuthController {
  AuthController._();

  static final ValueNotifier<User?> user = ValueNotifier<User?>(null);

  static void init() {
    FirebaseAuth.instance.authStateChanges().listen((u) {
      // 🔥 FORZIAMO UPDATE SUL MAIN THREAD
      WidgetsBinding.instance.addPostFrameCallback((_) {
        user.value = u;
      });
    });
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
