import 'package:cloud_firestore/cloud_firestore.dart';

class PrintOrderData {
  final int ticketNumber;
  final String clientName;
  final String clientPhone;
  final DateTime createdAt;
  final DateTime pickupDate;
  final String pickupSlot;
  final List<PrintOrderItem> items;
  final double total;
  final double deposit;
  final bool isPaid;
  
  PrintOrderData({
    required this.ticketNumber,
    required this.clientName,
    required this.clientPhone,
    required this.createdAt,
    required this.pickupDate,
    required this.pickupSlot,
    required this.items,
    required this.total,
    required this.deposit,
    required this.isPaid,
  });
}

class PrintOrderItem {
  final String garmentName;
  final int qty;
  final double price;

  PrintOrderItem({
    required this.garmentName,
    required this.qty,
    required this.price,
  });
}
