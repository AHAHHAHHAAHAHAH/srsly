import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addClient({
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Utente non autenticato');
    }

    final companyId = user.uid;

    final now = FieldValue.serverTimestamp();

    await _db
        .collection('companies')
        .doc(companyId)
        .collection('clients')
        .add({
      'name': name.trim(),
      'nameLowercase': name.toLowerCase().trim(),
      'phone': phone.trim(),
      'createdAt': now,
      'lastInteractionAt': now,
    });
  }
}
