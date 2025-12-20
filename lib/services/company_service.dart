import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createCompany({
    required String companyName,
    required String ownerUid,
    required String email,
  }) async {
    await _db.collection('companies').doc(ownerUid).set({
      'name': companyName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
