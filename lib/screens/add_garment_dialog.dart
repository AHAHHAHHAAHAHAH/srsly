import 'package:flutter/material.dart';
import '../services/garment_service.dart';

class AddGarmentDialog extends StatefulWidget {
  const AddGarmentDialog({super.key});

  @override
  State<AddGarmentDialog> createState() => _AddGarmentDialogState();
}

class _AddGarmentDialogState extends State<AddGarmentDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');

  bool _loading = false;
  String? _error;

  double? _parsePrice(String s) {
    final v = s.trim().replaceAll(',', '.');
    return double.tryParse(v);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = _parsePrice(_priceCtrl.text);

    if (name.isEmpty) {
      setState(() => _error = 'Nome mancante');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Prezzo non valido');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await GarmentService().createGarment(name: name, basePrice: price);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Errore salvataggio: $e');
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
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Prezzo base'),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salva'),
        ),
      ],
    );
  }
}
