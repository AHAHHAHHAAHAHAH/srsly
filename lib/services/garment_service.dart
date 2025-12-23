import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GarmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getCompanyId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) throw Exception('Profilo utente non trovato (users/${user.uid})');

    final data = snap.data();
    final companyId = data?['companyId'];
    if (companyId == null || companyId is! String || companyId.trim().isEmpty) {
      throw Exception('companyId mancante su users/${user.uid}');
    }

    return companyId;
  }

  Future<void> createGarment({
    required String name,
    required double basePrice,
  }) async {
    final companyId = await _getCompanyId();
    final n = name.trim();

    await _db.collection('garments').add({
      'companyId': companyId,
      'name': n,
      'nameLowerCase': n.toLowerCase(), // ✅ CAMPO CHIAVE
      'basePrice': basePrice,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> searchGarments(String query) async* {
    final companyId = await _getCompanyId();
    final q = query.trim().toLowerCase();

    yield* _db
        .collection('garments')
        .where('companyId', isEqualTo: companyId)
        .orderBy('nameLowerCase')       // ✅
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .snapshots();
  }
}
