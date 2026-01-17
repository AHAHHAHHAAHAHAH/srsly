import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyTicketService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _companyRef(String companyId) {
    return _db.collection('companies').doc(companyId);
  }

  Stream<int> streamNextTicket(String companyId) {
    return _companyRef(companyId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return (data['nextTicketNumber'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> ensureTicketExists(String companyId) async {
    final ref = _companyRef(companyId);
    final snap = await ref.get();
    final data = snap.data() ?? {};

    if (!data.containsKey('nextTicketNumber')) {
      await ref.set({'nextTicketNumber': 0}, SetOptions(merge: true));
    }
  }

  /// Assegna il ticket corrente e poi incrementa nextTicketNumber di +1.
  /// Chiamare SOLO quando la stampa è andata a buon fine.
  Future<int> allocateTicketAfterSuccessfulPrint(String companyId) async {
    final ref = _companyRef(companyId);

    // Assicura esistenza campo
    await ensureTicketExists(companyId);

    // 1) leggo corrente
    final snapBefore = await ref.get();
    final dataBefore = snapBefore.data() ?? {};
    final current = (dataBefore['nextTicketNumber'] as num?)?.toInt() ?? 0;

    // 2) incremento
    await ref.set({
      'nextTicketNumber': FieldValue.increment(1),
      'ticketUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3) ritorno assegnato
    return current;
  }
}
