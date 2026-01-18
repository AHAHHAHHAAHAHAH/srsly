import 'package:flutter/material.dart';

class CapiTableScreen extends StatelessWidget {
  final String? clientId;
  const CapiTableScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    if (clientId == null) {
      return const Center(
        child: Text(
          'Tabella capi (da implementare)',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return const Center(
      child: Text(
        'Tabella capi (da implementare)',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
