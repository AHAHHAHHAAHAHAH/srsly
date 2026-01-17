import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyCounters {
  final int clientCode;
  final int partitaNumber;

  CompanyCounters({
    required this.clientCode,
    required this.partitaNumber,
  });
}

class CompanyCountersService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _companyRef(String companyId) {
    return _db.collection('companies').doc(companyId);
  }

  /// Preview realtime (mostra il "prossimo" numero).
  Stream<Map<String, int>> streamNextCounters(String companyId) {
    return _companyRef(companyId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      final nextClient = (data['nextClientCode'] as num?)?.toInt() ?? 0;
      final nextPartita = (data['nextPartitaNumber'] as num?)?.toInt() ?? 0;

      return {
        'nextClientCode': nextClient,
        'nextPartitaNumber': nextPartita,
      };
    });
  }

  /// Assicura che i contatori esistano (senza sovrascrivere).
  Future<void> ensureCountersExist(String companyId) async {
    final ref = _companyRef(companyId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};

      final Map<String, dynamic> patch = {};
      if (!data.containsKey('nextClientCode')) patch['nextClientCode'] = 0;
      if (!data.containsKey('nextPartitaNumber')) patch['nextPartitaNumber'] = 0;

      if (patch.isNotEmpty) {
        tx.set(ref, patch, SetOptions(merge: true));
      }
    });
  }

  /// Assegna i numeri (clientCode e partitaNumber) e incrementa di +1.
  /// DA chiamare SOLO al momento della stampa.
  Future<CompanyCounters> allocateForPrint(String companyId) async {
    final ref = _companyRef(companyId);

    return _db.runTransaction<CompanyCounters>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};

      final currentClient = (data['nextClientCode'] as num?)?.toInt() ?? 0;
      final currentPartita = (data['nextPartitaNumber'] as num?)?.toInt() ?? 0;

      tx.set(ref, {
        'nextClientCode': currentClient + 1,
        'nextPartitaNumber': currentPartita + 1,
        'countersUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return CompanyCounters(
        clientCode: currentClient,
        partitaNumber: currentPartita,
      );
    });
  }
}
