import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getCompanyId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utente non autenticato');
    }

    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) {
      throw Exception('Profilo utente non trovato (users/${user.uid})');
    }

    final data = snap.data();
    final companyId = data?['companyId'];

    if (companyId == null || companyId is! String || companyId.trim().isEmpty) {
      throw Exception('companyId mancante su users/${user.uid}');
    }

    return companyId;
  }

  Future<void> addClient({
    required String fullName,
    required String number,
  }) async {
    final companyId = await _getCompanyId();

    final fn = fullName.trim();
    final num = number.trim();

    await _db.collection('clients').add({
      'companyId': companyId,
      'fullName': fn,
      'fullNameLowerCase': fn.toLowerCase(),
      'number': num,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ chiamato SOLO al momento della STAMPA
  Future<void> markClientServed({
    required String clientId,
    required String label,
  }) async {
    await _getCompanyId();

    await _db.collection('clients').doc(clientId).update({
      'lastActivityAt': FieldValue.serverTimestamp(),
      'lastActivityLabel': label,
    });
  }

  /// 🧹 Rimuove il cliente dallo STORICO (NON elimina il cliente)
  Future<void> clearClientFromHistory(String clientId) async {
    await _getCompanyId();

    await _db.collection('clients').doc(clientId).update({
      'lastActivityAt': FieldValue.delete(),
      'lastActivityLabel': FieldValue.delete(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> searchClients(String query) async* {
    final companyId = await _getCompanyId();
    final q = query.trim().toLowerCase();

    yield* _db
        .collection('clients')
        .where('companyId', isEqualTo: companyId)
        .orderBy('fullNameLowerCase')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .snapshots();
  }

  /// Storico = ultimi clienti SERVITI
  Stream<QuerySnapshot<Map<String, dynamic>>> getLastServedClients({
    int limit = 7,
  }) async* {
    final companyId = await _getCompanyId();

    yield* _db
        .collection('clients')
        .where('companyId', isEqualTo: companyId)
        .orderBy('lastActivityAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getClientById(
    String clientId,
  ) {
    return _db.collection('clients').doc(clientId).get();
  }
}
