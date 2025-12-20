import 'package:flutter/material.dart';

class CapiTableScreen extends StatelessWidget {
  final String? clientId;
  const CapiTableScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        clientId == null
            ? 'Seleziona un cliente (Home → click cliente)'
            : 'Tabella capi per cliente: $clientId (da implementare)',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
