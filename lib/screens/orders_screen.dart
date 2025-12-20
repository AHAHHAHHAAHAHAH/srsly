import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  final String? clientId;
  const OrdersScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        clientId == null
            ? 'Seleziona un cliente (Home → click cliente)'
            : 'Ordini per cliente: $clientId (da implementare)',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
