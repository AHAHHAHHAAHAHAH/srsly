import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import 'sidebar.dart';

class AppShell extends StatefulWidget {
   AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const Center(child: Text('Clienti (gestione completa - dopo)', style: TextStyle(fontSize: 24)));
      case 2:
        return const Center(child: Text('Ordini (dopo)', style: TextStyle(fontSize: 24)));
      case 3:
        return const Center(child:Text('Tabella (dopo)', style: TextStyle(fontSize: 24)));
      case 4:
        return const SettingsScreen();
      default:
        return const Center(child: Text('Sezione non trovata', style: TextStyle(fontSize: 24)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onSelect: (index) {
              setState(() => selectedIndex = index);
            },
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
