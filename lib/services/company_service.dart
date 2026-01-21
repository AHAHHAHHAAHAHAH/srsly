import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'companies';

  Future<DocumentSnapshot<Map<String, dynamic>>> getCompany(String companyId) {
    return _db.collection(_collection).doc(companyId).get();
  }

  Future<void> updateCompanyProfile({
  required String companyId,
  required String ownerFullName,
  required String addressStreet,
  required String addressCap,
  required String addressCity,
  required String ownerPhone,
}) async {
  await _db.collection(_collection).doc(companyId).set({
    'ownerFullName': ownerFullName.trim(),
    'addressStreet': addressStreet.trim(),
    'addressCap': addressCap.trim(),
    'addressCity': addressCity.trim(),
    'ownerPhone': ownerPhone.trim(),
  }, SetOptions(merge: true));
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
