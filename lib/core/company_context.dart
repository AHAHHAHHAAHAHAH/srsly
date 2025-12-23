import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyContext {
  CompanyContext._();
  static final CompanyContext instance = CompanyContext._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? _companyId;

  /// chiamalo appena dopo login / all’avvio app
  Future<String> loadCompanyId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utente non autenticato');
    }

    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) {
      throw Exception('Documento users/${user.uid} non trovato');
    }

    final data = snap.data();
    final cid = data?['companyId'] as String?;
    if (cid == null || cid.isEmpty) {
      throw Exception('companyId mancante su users/${user.uid}');
    }

    _companyId = cid;
    return cid;
  }

  /// restituisce companyId se già caricato, altrimenti lo carica
  Future<String> getCompanyId() async {
    if (_companyId != null) return _companyId!;
    return loadCompanyId();
  }

  void clear() {
    _companyId = null;
  }
}
