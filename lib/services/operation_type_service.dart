import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OperationTypeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getCompanyId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

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

  /// GET OR CREATE TYPE (case-insensitive)
  Future<String> getOrCreateOperationType({
    required String typeName,
  }) async {
    final companyId = await _getCompanyId();
    final name = typeName.trim();
    if (name.isEmpty) throw Exception('Nome tipo vuoto');

    final nameLower = name.toLowerCase();

    final snap = await _db
        .collection('operation_types')
        .where('companyId', isEqualTo: companyId)
        .where('nameLowerCase', isEqualTo: nameLower)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return snap.docs.first.id;
    }

    final doc = await _db.collection('operation_types').add({
      'companyId': companyId,
      'name': name,
      'nameLowerCase': nameLower,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// STREAM tipi
  /// ✅ NOTA: niente orderBy qui, così evitiamo indici compositi
  Stream<QuerySnapshot<Map<String, dynamic>>> streamTypes() async* {
    final companyId = await _getCompanyId();

    yield* _db
        .collection('operation_types')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }

  Future<Map<String, String>> getTypesMap() async {
    final companyId = await _getCompanyId();

    final snap = await _db
        .collection('operation_types')
        .where('companyId', isEqualTo: companyId)
        .get();

    final Map<String, String> out = {};
    for (final d in snap.docs) {
      final data = d.data();
      final name = data['name'];
      if (name is String && name.trim().isNotEmpty) {
        out[d.id] = name;
      }
    }
    return out;
  }

  Future<void> deleteType(String typeId) async {
    await _db.collection('operation_types').doc(typeId).delete();
  }
}
