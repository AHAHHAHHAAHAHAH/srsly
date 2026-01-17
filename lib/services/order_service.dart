import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createOrder({
    required String companyId,
    required String? clientId,
    required String clientName,
    required String clientPhone,

    // ✅ ticket unico
    required int ticketNumber,

    // ✅ compat: li teniamo (uguali al ticket)
    required int clientCode,
    required int partitaNumber,

    required List<Map<String, dynamic>> items,
  }) async {
    final ref = _db.collection('orders').doc();

    await ref.set({
      'companyId': companyId,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,

      'ticketNumber': ticketNumber,
      'clientCode': clientCode,
      'partitaNumber': partitaNumber,

      'createdAt': FieldValue.serverTimestamp(),
      'items': items,
    });

    return ref.id;
  }
}
