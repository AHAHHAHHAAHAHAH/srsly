import 'package:flutter/material.dart';
import '../services/garment_service.dart';

class AddGarmentDialog extends StatefulWidget {
  const AddGarmentDialog({super.key});

  @override
  State<AddGarmentDialog> createState() => _AddGarmentDialogState();
}

class _AddGarmentDialogState extends State<AddGarmentDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  final _service = GarmentService();

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));

    if (name.isEmpty || price == null || price < 0) {
      setState(() => _error = 'Dati non validi');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.createGarment(
        name: name,
        basePrice: price,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo capo'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome capo'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Prezzo base'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }
}
