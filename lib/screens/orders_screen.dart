import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  final String? clientId;
  const OrdersScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    if (clientId == null) {
      return const Center(
        child: Text(
          'Seleziona un cliente dalla Home (o dallo Storico) per vedere gli ordini.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Center(
      child: Text(
        'Ordini per il cliente selezionato (da implementare)',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
