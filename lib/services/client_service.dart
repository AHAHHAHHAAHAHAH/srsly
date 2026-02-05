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

  // --- METODI ESISTENTI (NON TOCCATI) ---

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
      'fullNameLowerCase': fn.toLowerCase(), // Nota: alcuni file usano fullNameLowerCase, altri nameLowerCase. Mantengo coerenza col tuo file caricato.
      'number': num,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

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

    // Nota: Il tuo file originale usa 'fullNameLowerCase'.
    yield* _db
        .collection('clients')
        .where('companyId', isEqualTo: companyId)
        .orderBy('fullNameLowerCase') 
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .snapshots();
  }

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

  // --- NUOVI METODI AGGIUNTI PER LA TABELLA (NON ROMPONO NULLA) ---

  Future<void> updateClient({
    required String clientId,
    required String fullName,
    required String number,
  }) async {
    // Non serve _getCompanyId per update su doc specifico, ma ok per sicurezza
    await _db.collection('clients').doc(clientId).update({
      'fullName': fullName.trim(),
      'fullNameLowerCase': fullName.trim().toLowerCase(),
      'number': number.trim(),
    });
  }

  Future<void> deleteClient(String clientId) async {
    await _db.collection('clients').doc(clientId).delete();
  }
}