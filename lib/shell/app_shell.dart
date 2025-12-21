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

  /// Cliente “in servizio” (valido solo quando impostato esplicitamente)
  String? _activeClientId;

  /// Navigazione “normale” (sidebar): resetta sempre il cliente attivo.
  void goToSection(AppSection section) {
    setState(() {
      _section = section;
      _activeClientId = null; // ✅ reset contesto cliente
    });
  }

  /// Navigazione “con contesto cliente” (click su cliente / storico)
  void goToSectionForClient(AppSection section, {required String clientId}) {
    setState(() {
      _section = section;
      _activeClientId = clientId; // ✅ set contesto cliente
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
            onSelect: goToSection, // ✅ sidebar = reset cliente
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
