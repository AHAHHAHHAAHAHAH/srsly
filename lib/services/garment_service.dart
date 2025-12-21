import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GarmentService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) {
      throw Exception('Utente non autenticato');
    }
    return u.uid;
  }

  Future<String> _companyId() async {
    final snap = await _db.collection('users').doc(_uid).get();
    final data = snap.data();
    if (data == null || data['companyId'] == null) {
      throw Exception('companyId mancante su users/_uid');
    }
    return data['companyId'];
  }

  /// 🔍 Ricerca capi (immediata, anche 1 lettera)
  Stream<QuerySnapshot<Map<String, dynamic>>> searchGarments(String query) async* {
    final companyId = await _companyId();

    yield* _db
        .collection('garments')
        .where('companyId', isEqualTo: companyId)
        .where('nameLower', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('nameLower', isLessThan: query.toLowerCase() + 'z')
        .orderBy('nameLower')
        .snapshots();
  }

  /// ➕ Crea capo
  Future<void> createGarment({
    required String name,
    required double basePrice,
  }) async {
    final companyId = await _companyId();

    await _db.collection('garments').add({
      'name': name,
      'nameLower': name.toLowerCase(),
      'basePrice': basePrice,
      'companyId': companyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
