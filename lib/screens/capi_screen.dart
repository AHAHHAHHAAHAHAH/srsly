import 'package:flutter/material.dart';
import '../services/client_service.dart';

class CapiScreen extends StatelessWidget {
  final String? clientId;
  const CapiScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    if (clientId == null) {
      return const Center(
        child: Text(
          'Seleziona un cliente dalla Home',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return FutureBuilder(
      future: ClientService().getClientById(clientId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Errore: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return const Center(child: Text('Cliente non trovato'));
        }

        final fullName = data['fullName'] ?? '';
        final number = data['number'] ?? '';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Niente “CAPI” brutto in alto come mi hai chiesto
              Text(
                'Stai servendo:',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$fullName — $number',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Qui costruiremo la schermata capi (aggiunta capi, lavorazioni, stampa scontrino).',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
