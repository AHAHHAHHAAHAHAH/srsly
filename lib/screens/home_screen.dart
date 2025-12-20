import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_client_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchText = '';

  String _companyId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utente non autenticato');
    return user.uid;
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        setState(() {
          _searchText = _searchController.text.trim().toLowerCase();
        });
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _searchClients() {
    if (_searchText.isEmpty) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId())
        .collection('clients')
        .orderBy('nameLowercase')
        .startAt([_searchText])
        .endAt(['$_searchText\uf8ff'])
        .limit(20)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _lastSearches() {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId())
        .collection('clients')
        .orderBy('lastInteractionAt', descending: true)
        .limit(7)
        .snapshots();
  }

  Future<void> _touchClient(String id) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(_companyId())
        .collection('clients')
        .doc(id)
        .update({'lastInteractionAt': FieldValue.serverTimestamp()});
  }

  String _fmt(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Home',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // ---------- RICERCA ----------
          const Text('Cerca clienti'),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              hintText: 'mar → Marco, Martina',
            ),
          ),

          const SizedBox(height: 12),

          // ---------- AGGIUNGI CLIENTE ----------
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Aggiungi cliente'),
            onPressed: () async {
              final created = await showDialog<bool>(
                context: context,
                barrierDismissible: false, // ✅ FIX 1
                builder: (_) => const AddClientDialog(),
              );

              if (created == true) {
                setState(() {});
              }
            },
          ),

          const SizedBox(height: 16),

          // ---------- RISULTATI RICERCA ----------
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _searchClients(),
            builder: (context, snapshot) {
              if (_searchText.isEmpty) {
                return const Text(
                  'Inizia a digitare per cercare un cliente',
                  style: TextStyle(color: Colors.grey),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('Nessun cliente trovato');
              }

              return Card(
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: snapshot.data!.docs.map((doc) {
                    final d = doc.data();
                    return ListTile(
                      title: Text(d['name'] ?? ''),
                      subtitle: Text(d['phone'] ?? '-'),
                      onTap: () => _touchClient(doc.id),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          // ---------- ULTIME RICERCHE ----------
          const Text('ULTIME RICERCHE',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _lastSearches(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('Nessuna ricerca recente');
              }

              return Card(
                child: Column(
                  children: snapshot.data!.docs.map((doc) {
                    final d = doc.data();
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(d['name'] ?? '')),
                          Expanded(flex: 2, child: Text(d['phone'] ?? '-')),
                          Expanded(flex: 2, child: Text(_fmt(d['lastInteractionAt']))),
                          const Icon(Icons.receipt_long),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
