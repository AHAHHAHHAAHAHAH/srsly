import 'dart:async';
import 'package:flutter/material.dart';
import '../services/client_service.dart';
import '../shell/app_shell.dart';
import '../shell/app_shell.dart' show AppSection;
import 'add_client_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  Future<void> _confirmRemoveFromHistory(String clientId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rimuovi dallo storico'),
        content: Text('Vuoi rimuovere "$name" dallo storico clienti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _clientService.clearClientFromHistory(clientId);
    }
  }

  /// 📅 + 🕒 formato: DD/MM/YYYY · HH:mm
  String _formatDateTime(dynamic ts) {
    if (ts == null) return '—';
    try {
      final d = ts.toDate();
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year;
      final hour = d.hour.toString().padLeft(2, '0');
      final minute = d.minute.toString().padLeft(2, '0');
      return '$day/$month/$year · $hour:$minute';
    } catch (_) {
      return '—';
    }
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      );

  Widget _value(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      );

  BoxDecoration _pillBox() => BoxDecoration(
        color: Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================
          // RICERCA CLIENTI
          // =========================
          Container(
            height: 420,
            padding: const EdgeInsets.all(18),
            decoration: _box(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ricerca clienti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    hintText: 'Scrivi nome cliente',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Nuovo cliente'),
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const AddClientDialog(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _query.isEmpty
                      ? const SizedBox()
                      : StreamBuilder(
                          stream: _clientService.searchClients(_query),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return const Text('Nessun cliente trovato');
                            }

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, i) {
                                final doc = docs[i];
                                final d = doc.data();
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                      d['fullName'],
                                      style: const TextStyle(
                                        fontSize: 16, // 👈 cambia qui
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  subtitle: Text(
                                      d['number'],
                                      style: const TextStyle(
                                        fontSize: 14.5, // 👈 cambia qui
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  onTap: () {
                                    AppShell.of(context).goToSectionForClient(
                                      AppSection.capi,
                                      clientId: doc.id,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =========================
          // STORICO CLIENTI
          // =========================
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _box(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Storico Clienti (ultimi 7)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder(
                      stream: _clientService.getLastServedClients(limit: 7),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Text(
                            'Nessuna operazione recente',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final doc = docs[i];
                            final c = doc.data();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: _pillBox(),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _label('Nome e cognome'),
                                          _value(c['fullName'] ?? ''),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _label('Numero'),
                                          _value(c['number'] ?? ''),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _label('Data e ora ultimo ordine'),
                                          _value(_formatDateTime(c['lastActivityAt'])),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        AppShell.of(context).goToSectionForClient(
                                          AppSection.ordini,
                                          clientId: doc.id,
                                        );
                                      },
                                      child: const Text('ORDINI'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Rimuovi dallo storico',
                                      onPressed: () => _confirmRemoveFromHistory(
                                        doc.id,
                                        c['fullName'] ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      );
}
