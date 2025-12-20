import 'package:flutter/material.dart';

import 'core/auth_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthGate();
  }
}
