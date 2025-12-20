import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyService {
  final _db = FirebaseFirestore.instance;
  final String _collection = 'company';

  Future<DocumentSnapshot> getCompany() {
    return _db.collection(_collection).doc('main').get();
  }

  Future<void> updateCompany(String name) async {
    await _db.collection(_collection).doc('main').set({
      'name': name,
      'updatedAt': Timestamp.now(),
    });
  }
}
