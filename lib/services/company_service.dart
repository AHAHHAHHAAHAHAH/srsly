import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'companies';

  Future<DocumentSnapshot<Map<String, dynamic>>> getCompany(String companyId) {
    return _db.collection(_collection).doc(companyId).get();
  }

  Future<void> initIfMissing(String companyId) async {
    final ref = _db.collection(_collection).doc(companyId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'nextTicketNumber': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
