import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getCompanyId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utente non autenticato');
    }

    final snap = await _db.collection('users').doc(user.uid).get();
    final data = snap.data();

    final companyId = data?['companyId'];
    if (companyId == null || companyId is! String || companyId.isEmpty) {
      throw Exception('companyId mancante su users/${user.uid}');
    }

    return companyId;
  }

  Future<int> createOrder({
    required String clientId,
    required String clientName,
    required String clientPhone,
    required List<Map<String, dynamic>> items,
    required double deposit,
    required bool isPaid,
  }) async {
    final companyId = await _getCompanyId();
    final companyRef = _db.collection('companies').doc(companyId);

    // 1) Leggo SEMPRE da server l'ultimo numero assegnato
    final companySnap = await companyRef.get(
      const GetOptions(source: Source.server),
    );
    final companyData = companySnap.data() ?? {};

    final lastIssued = (companyData['nextTicketNumber'] is int)
        ? companyData['nextTicketNumber'] as int
        : 0;

    // 2) Il nuovo ticket è last + 1
    final ticketNumber = lastIssued + 1;

    // 3) Aggiorno il contatore (lastIssued = ticketNumber)
    await companyRef.set(
      {'nextTicketNumber': ticketNumber},
      SetOptions(merge: true),
    );

    // 4) Creo ordine con quel ticket
    await _db.collection('orders').add({
      'companyId': companyId,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'ticketNumber': ticketNumber,
      'partitaNumber': ticketNumber,
      'items': items,
      'deposit': deposit,
      'isPaid': isPaid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ticketNumber;
  }

  static Timestamp ts(DateTime d) => Timestamp.fromDate(d);
}
//MODIFICA cRISTOLAMADONNNADEDDIO