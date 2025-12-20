import 'package:flutter/material.dart';
import '../services/client_service.dart';

class AddClientDialog extends StatefulWidget {
  const AddClientDialog({super.key});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _service = ClientService();

  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return; // 🔒 sicurezza extra

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Il nome è obbligatorio');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.addClient(name: name, phone: phone);

      if (!mounted) return;

      // ✅ QUESTA È LA RIGA CHE SISTEMA TUTTO
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      // ⚠️ questo non verrà quasi mai eseguito perché pop() chiude il widget
      // ma lo lasciamo per sicurezza
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aggiungi cliente'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Nome e cognome',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Telefono (opzionale)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }
}
