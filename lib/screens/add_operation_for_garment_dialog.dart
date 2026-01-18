import 'package:flutter/material.dart';
import '../services/garment_service.dart';
import '../services/operation_type_service.dart';

class AddOperationForGarmentDialog {
  static Future<bool?> open(
    BuildContext context, {
    required String garmentId,
    required String garmentName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddOperationForGarmentDialog(
        garmentId: garmentId,
        garmentName: garmentName,
      ),
    );
  }
}

class _AddOperationForGarmentDialog extends StatefulWidget {
  final String garmentId;
  final String garmentName;

  const _AddOperationForGarmentDialog({
    required this.garmentId,
    required this.garmentName,
  });

  @override
  State<_AddOperationForGarmentDialog> createState() =>
      _AddOperationForGarmentDialogState();
}

class _AddOperationForGarmentDialogState
    extends State<_AddOperationForGarmentDialog> {
  final _priceCtrl = TextEditingController();

  final _garmentService = GarmentService();
  final _typeService = OperationTypeService();

  String? _selectedTypeId;
  bool _loading = false;
  String? _error;

  double? _parsePrice(String s) {
    final v = s.trim().replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(v);
  }

  bool get _canSave {
    final typeOk = _selectedTypeId != null;
    final price = _parsePrice(_priceCtrl.text);
    final priceOk = price != null && price >= 0;
    return typeOk && priceOk && !_loading;
  }

  Future<String?> _askNewType() async {
    final ctrl = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuovo tipo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome tipo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final price = _parsePrice(_priceCtrl.text);
      if (_selectedTypeId == null) throw Exception('Seleziona un tipo');
      if (price == null) throw Exception('Prezzo non valido');

      await _garmentService.setPriceForGarmentType(
        garmentId: widget.garmentId,
        typeId: _selectedTypeId!,
        price: price,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aggiungi operazione · ${widget.garmentName}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder(
              stream: _typeService.streamTypes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Text(
                      'Errore caricamento tipi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                docs.sort((a, b) {
                  final an = (a.data()['nameLowerCase'] ?? a.data()['name'] ?? '').toString();
                  final bn = (b.data()['nameLowerCase'] ?? b.data()['name'] ?? '').toString();
                  return an.compareTo(bn);
                });

                final items = docs.map((d) {
                  final data = d.data();
                  final name = (data['name'] ?? '').toString();
                  return DropdownMenuItem<String>(
                    value: d.id,
                    child: Text(name),
                  );
                }).toList();

                final validValue =
                    items.any((e) => e.value == _selectedTypeId) ? _selectedTypeId : null;

                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: validValue,
                        items: items,
                        decoration: const InputDecoration(
                          labelText: 'Tipo operazione',
                        ),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedTypeId = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Aggiungi tipo',
                      onPressed: () async {
                        final res = await _askNewType();
                        if (res == null || res.trim().isEmpty) return;

                        try {
                          final id = await _typeService.getOrCreateOperationType(typeName: res);
                          if (!mounted) return;
                          setState(() => _selectedTypeId = id);
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _error = e.toString());
                        }
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Prezzo',
                prefixText: '€ ',
              ),
              onChanged: (_) => setState(() {}),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _canSave ? _save : null,
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
