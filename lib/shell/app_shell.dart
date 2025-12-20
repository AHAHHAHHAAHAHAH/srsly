import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/capi_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/capi_table_screen.dart';
import '../screens/settings_screen.dart';
import 'sidebar.dart';

enum AppSection { home, capi, ordini, tabellaCapi, settings }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static _AppShellState of(BuildContext context) =>
      context.findAncestorStateOfType<_AppShellState>()!;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _section = AppSection.home;
  String? _activeClientId;

  void goToSection(AppSection section, {String? clientId}) {
    setState(() {
      _section = section;
      if (clientId != null) _activeClientId = clientId;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_section) {
      case AppSection.home:
        body = const HomeScreen();
        break;
      case AppSection.capi:
        body = CapiScreen(clientId: _activeClientId);
        break;
      case AppSection.ordini:
        body = OrdersScreen(clientId: _activeClientId);
        break;
      case AppSection.tabellaCapi:
        body = CapiTableScreen(clientId: _activeClientId);
        break;
      case AppSection.settings:
        body = const SettingsScreen();
        break;
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            current: _section,
            onSelect: (s) => goToSection(s),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
