import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/auth_controller.dart';

class ClientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _companyId {
    final cid = AuthController.instance.companyId;
    if (cid == null) {
      throw Exception('CompanyId non inizializzato');
    }
    return cid;
  }

  /// =========================
  /// CREA CLIENTE
  /// =========================
  Future<void> addClient({
    required String fullName,
    required String number,
  }) async {
    await _db.collection('clients').add({
      'fullName': fullName,
      'number': number,
      'companyId': _companyId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// CERCA CLIENTI
  /// =========================
  Stream<QuerySnapshot<Map<String, dynamic>>> searchClients(String query) {
    return _db
        .collection('clients')
        .where('companyId', isEqualTo: _companyId)
        .orderBy('fullName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots();
  }

  /// =========================
  /// CLIENTI RECENTI (HOME)
  /// =========================
  Stream<QuerySnapshot<Map<String, dynamic>>> getLastServedClients({
    int limit = 10,
  }) {
    return _db
        .collection('clients')
        .where('companyId', isEqualTo: _companyId)
        .orderBy('lastActivityAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// =========================
  /// SINGOLO CLIENTE
  /// =========================
  Future<DocumentSnapshot<Map<String, dynamic>>> getClientById(String id) {
    return _db.collection('clients').doc(id).get();
  }
}
