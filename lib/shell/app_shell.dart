import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/capi_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/capi_table_screen.dart';
import '../screens/client_table_screen.dart'; // <--- NUOVO IMPORT
import '../screens/settings_screen.dart';
import 'sidebar.dart';

// AGGIUNTA 'tabellaClienti' ALLA FINE
enum AppSection { home, capi, ordini, tabellaCapi, tabellaClienti, settings }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static AppShellState of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>()!;

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  AppSection _section = AppSection.home;
  String? _activeClientId;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void goToSection(AppSection section) {
    setState(() {
      _section = section;
      _activeClientId = null;
    });
  }

  void goToSectionForClient(AppSection section, {required String clientId}) {
    setState(() {
      _section = section;
      _activeClientId = clientId;
    });
  }

  Future<String> _getCompanyId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    final snap = await _db.collection('users').doc(user.uid).get();
    final data = snap.data();
    final companyId = data?['companyId'];

    if (companyId == null || companyId is! String || companyId.trim().isEmpty) {
      throw Exception('companyId mancante su users/${user.uid}');
    }
    return companyId;
  }

  int? get currentPreviewTicket => _lastHeaderPreview;
  int? _lastHeaderPreview;

  Future<_HeaderData?> _loadHeaderData() async {
    final clientId = _activeClientId;
    if (clientId == null) return null;

    final clientSnap = await _db.collection('clients').doc(clientId).get();
    final clientData = clientSnap.data();
    if (clientData == null) return null;

    final fullName = (clientData['fullName'] ?? '') as String;
    final phone = (clientData['number'] ?? '') as String;

    final companyId = await _getCompanyId();
    final companySnap = await _db.collection('companies').doc(companyId).get();
    final companyData = companySnap.data() ?? {};

    final current = companyData['nextTicketNumber'];
    final int currentN = (current is int) ? current : 0;
    final int preview = currentN + 1;

    _lastHeaderPreview = preview;

    return _HeaderData(
      fullName: fullName,
      phone: phone,
      previewNumber: preview,
    );
  }

  Widget _headerBar() {
    if (_activeClientId == null || _section == AppSection.ordini) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<_HeaderData?>(
      key: ValueKey('header_${_activeClientId}'),
      future: _loadHeaderData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 26);
        }

        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.07)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${data.fullName} · ${data.phone}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.black.withOpacity(0.10)),
                ),
                child: Text(
                  'Cod. Cliente #${data.previewNumber} · Partita n° #${data.previewNumber}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
      case AppSection.tabellaClienti: // <--- NUOVO CASE
        body = const ClientTableScreen();
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
            onSelect: goToSection,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerBar(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderData {
  final String fullName;
  final String phone;
  final int previewNumber;

  _HeaderData({
    required this.fullName,
    required this.phone,
    required this.previewNumber,
  });
}