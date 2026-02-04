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
        content: Text('Vuoi rimuovere "$name" dallo storico recente?'),
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

  // Helper per le iniziali (es. Mario Rossi -> MR)
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================
          // SEZIONE RICERCA
          // =========================
          Container(
            height: 450, 
            padding: const EdgeInsets.all(24),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ricerca Clienti',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('NUOVO CLIENTE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const AddClientDialog(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Cerca per nome',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: _query.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade200),
                              const SizedBox(height: 12),
                              Text('Inizia a digitare per cercare', style: TextStyle(color: Colors.grey.shade400)),
                            ],
                          ),
                        )
                      : StreamBuilder(
                          stream: _clientService.searchClients(_query),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) return const Center(child: Text('Nessun risultato'));

                            return ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final doc = docs[i];
                                final d = doc.data();
                                return _ClientListTile(
                                  id: doc.id,
                                  name: d['fullName'],
                                  phone: d['number'],
                                  initials: _getInitials(d['fullName']),
                                  onTap: () => AppShell.of(context).goToSectionForClient(AppSection.capi, clientId: doc.id),
                                  onOrdersTap: () => AppShell.of(context).goToSectionForClient(AppSection.ordini, clientId: doc.id),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // =========================
          // STORICO RECENTE
          // =========================
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attività Recente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder(
                      stream: _clientService.getLastServedClients(limit: 7),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(child: Text('Nessuna attività recente', style: TextStyle(color: Colors.grey)));
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final doc = docs[i];
                            final c = doc.data();
                            return _HistoryCard(
                              id: doc.id,
                              name: c['fullName'] ?? '',
                              phone: c['number'] ?? '',
                              lastDate: c['lastActivityAt']?.toDate(),
                              initials: _getInitials(c['fullName'] ?? ''),
                              onRemove: () => _confirmRemoveFromHistory(doc.id, c['fullName'] ?? ''),
                              onOrdersTap: () => AppShell.of(context).goToSectionForClient(AppSection.ordini, clientId: doc.id),
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

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black.withOpacity(0.04)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

// ------------------------------------
// WIDGETS DI SUPPORTO (COPIA TUTTO!)
// ------------------------------------

class _ClientListTile extends StatelessWidget {
  final String id;
  final String name;
  final String phone;
  final String initials;
  final VoidCallback onTap;
  final VoidCallback onOrdersTap;

  const _ClientListTile({
    required this.id,
    required this.name,
    required this.phone,
    required this.initials,
    required this.onTap,
    required this.onOrdersTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.blueGrey.shade50,
        child: Text(
          initials,
          style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(phone, style: const TextStyle(color: Colors.grey)),
      trailing: _OrdersButton(onTap: onOrdersTap),
      onTap: onTap,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String id;
  final String name;
  final String phone;
  final DateTime? lastDate;
  final String initials;
  final VoidCallback onRemove;
  final VoidCallback onOrdersTap;

  const _HistoryCard({
    required this.id,
    required this.name,
    required this.phone,
    this.lastDate,
    required this.initials,
    required this.onRemove,
    required this.onOrdersTap,
  });

  String _fmtTime(DateTime? d) {
    if (d == null) return '';
    return '${d.day}/${d.month} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        // --- CORREZIONE QUI SOTTO ---
        // Abbiamo sostituito CircleAvatar con Container per avere il bordo
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300), // Ecco il bordo funzionante
          ),
          child: Text(
            initials,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        // -----------------------------
        title: Row(
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            Text(phone, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        subtitle: lastDate != null 
          ? Text('Ultimo ordine: ${_fmtTime(lastDate)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
          : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OrdersButton(onTap: onOrdersTap),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              onPressed: onRemove,
              splashRadius: 20,
              tooltip: 'Rimuovi',
            ),
          ],
        ),
        onTap: () => AppShell.of(context).goToSectionForClient(AppSection.capi, clientId: id),
      ),
    );
  }
}

class _OrdersButton extends StatelessWidget {
  final VoidCallback onTap;
  const _OrdersButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.receipt_long, size: 14),
      label: const Text('ORDINI'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}