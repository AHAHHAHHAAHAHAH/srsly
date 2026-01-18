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

Future<String> createGarment({
  required String name,
}) async {
  final companyId = await _getCompanyId();
  final n = name.trim();
  if (n.isEmpty) throw Exception('Nome capo vuoto');

  final nLower = n.toLowerCase();

  // 🔒 Anti-duplicato (case-insensitive) per company
  final existing = await _db
      .collection('garments')
      .where('companyId', isEqualTo: companyId)
      .where('nameLowerCase', isEqualTo: nLower)
      .limit(1)
      .get();

  if (existing.docs.isNotEmpty) {
    throw Exception('Capo già esistente: "$n"');
  }

  final doc = await _db.collection('garments').add({
    'companyId': companyId,
    'name': n,
    'nameLowerCase': nLower,
    'createdAt': FieldValue.serverTimestamp(),
  });

  return doc.id;
}




Future<void> setPriceForGarmentType({
  required String garmentId,
  required String typeId,
  required double price,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Utente non autenticato');
  }

  final userSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final companyId = userSnap.data()?['companyId'];
  if (companyId == null) {
    throw Exception('companyId mancante');
  }

  await FirebaseFirestore.instance
      .collection('garments')
      .doc(garmentId)
      .collection('prices')
      .doc(typeId)
      .set({
        'companyId': companyId,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}

  Future<Map<String, double>> getPricesForGarment(String garmentId) async {
  final snap = await _db
      .collection('garments')
      .doc(garmentId)
      .collection('prices')
      .get();

  final Map<String, double> out = {};

  for (final d in snap.docs) {
    final data = d.data();
    final price = (data['price'] as num?)?.toDouble();
    if (price != null) {
      out[d.id] = price;
    }
  }

  return out;
}


  Stream<QuerySnapshot<Map<String, dynamic>>> searchGarments(String query) async* {
    final companyId = await _getCompanyId();
    final q = query.trim().toLowerCase();

    yield* _db
        .collection('garments')
        .where('companyId', isEqualTo: companyId)
        .orderBy('nameLowerCase')       
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .snapshots();
  }

  
}
