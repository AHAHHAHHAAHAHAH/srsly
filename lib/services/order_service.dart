import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // HELPERS
  // =========================

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

  // =========================
  // API PRINCIPALE (ANTI-ABORT)
  // =========================

  Future<int> createOrder({
    required String clientId,
    required String clientName,
    required String clientPhone,
    required List<Map<String, dynamic>> items,
  }) async {
    final companyId = await _getCompanyId();
    final companyRef = _db.collection('companies').doc(companyId);

    // 1️⃣ Incremento atomico (NO transaction → NO abort)
    await companyRef.set(
      {'nextTicketNumber': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    // 2️⃣ Rileggo valore aggiornato
    final snap = await companyRef.get();
    final data = snap.data() ?? {};
    final int ticketNumber =
        (data['nextTicketNumber'] is int) ? data['nextTicketNumber'] as int : 1;

    // 3️⃣ Creo ordine
    await _db.collection('orders').add({
      'companyId': companyId,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'ticketNumber': ticketNumber,
      'partitaNumber': ticketNumber,
      'items': items,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ticketNumber;
  }

  // Utility
  static Timestamp ts(DateTime d) => Timestamp.fromDate(d);
}
