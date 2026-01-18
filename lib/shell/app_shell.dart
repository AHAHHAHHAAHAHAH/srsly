import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    // Preview = prossimo numero che verrà assegnato alla stampa
    final int preview = currentN + 1;

    return _HeaderData(
      fullName: fullName,
      phone: phone,
      previewNumber: preview,
    );
  }

Widget _headerBar() {
  // Se non c'è cliente attivo, niente header (zero spazio).
  if (_activeClientId == null) return const SizedBox.shrink();

  return FutureBuilder<_HeaderData?>(
    key: ValueKey('header_${_activeClientId}'),
    future: _loadHeaderData(),
    builder: (context, snapshot) {
      // mentre carica: riga bassa, niente “spazio enorme”
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(height: 26);
      }

      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
        child: Row(
          children: [
            // "pill" cliente a sinistra (stile coerente coi box)
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // chip a destra (non nero pieno, più elegante e coerente)
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerBar(), // ✅ QUI: stessa riga nome/telefono + pillola
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
