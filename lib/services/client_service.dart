import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/auth_controller.dart';

class ClientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _companyId {
    final id = AuthController.instance.companyId;
    if (id == null) {
      throw Exception('CompanyId non inizializzato');
    }
    return id;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('clients');

  Future<void> addClient({
    required String fullName,
    required String number,
  }) async {
    await _col.add({
      'companyId': _companyId,
      'fullName': fullName,
      'fullNameLower': fullName.toLowerCase(),
      'number': number,
      'createdAt': Timestamp.now(),

      // NOTA: NON lo mettiamo nello storico subito.
      // lastActivityAt verrà valorizzato quando fai un’operazione reale (ordine/scontrino).
      'lastActivityAt': null,
      'lastActivityLabel': null,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> searchClients(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const Stream.empty();

    return _col
        .where('companyId', isEqualTo: _companyId)
        .orderBy('fullNameLower')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .snapshots();
  }

  // Storico: SOLO clienti con lastActivityAt valorizzato
  Stream<QuerySnapshot<Map<String, dynamic>>> getLastServedClients({
    int limit = 7,
  }) {
    return _col
        .where('companyId', isEqualTo: _companyId)
        .where('lastActivityAt', isNull: false)
        .orderBy('lastActivityAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getClientById(String id) {
    return _col.doc(id).get();
  }
}
