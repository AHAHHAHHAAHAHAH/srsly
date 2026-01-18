import 'package:flutter/material.dart';
import '../services/garment_service.dart';
import '../services/operation_type_service.dart';

class AddGarmentDialog {
  static Future<bool?> open(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddGarmentDialog(),
    );
  }
}

class _AddGarmentDialog extends StatefulWidget {
  const _AddGarmentDialog();

  @override
  State<_AddGarmentDialog> createState() => _AddGarmentDialogState();
}

class _AddGarmentDialogState extends State<_AddGarmentDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final _garmentService = GarmentService();
  final _typeService = OperationTypeService();

  String? _selectedTypeId;
  String? _selectedTypeName;

  bool _saveOnlyType = false;
  bool _loading = false;
  String? _error;

  double? _parsePrice(String s) {
    final v = s.trim().replaceAll(',', '.');
    return double.tryParse(v);
  }

  bool get _canSave {
    // CASO 1: salvo solo tipo (senza capo)
    if (_saveOnlyType) {
      final hasId = _selectedTypeId != null && _selectedTypeId!.trim().isNotEmpty;
      final hasName = _selectedTypeName != null && _selectedTypeName!.trim().isNotEmpty;
      return hasId || hasName;
    }

    // CASO 2: capo + tipo + prezzo (tutti obbligatori)
    final nameOk = _nameCtrl.text.trim().isNotEmpty;
    final typeOk = (_selectedTypeId != null && _selectedTypeId!.trim().isNotEmpty) ||
        (_selectedTypeName != null && _selectedTypeName!.trim().isNotEmpty);

    final price = _parsePrice(_priceCtrl.text);
    final priceOk = price != null && price >= 0;

    return nameOk && typeOk && priceOk;
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

  Future<String> _ensureTypeId() async {
    // Se ho già un id valido, uso quello
    final existingId = _selectedTypeId;
    if (existingId != null && existingId.trim().isNotEmpty) {
      return existingId;
    }

    // Altrimenti creo/recupero per nome
    final name = _selectedTypeName?.trim() ?? '';
    if (name.isEmpty) {
      throw Exception('Seleziona o inserisci un tipo');
    }

    final id = await _typeService.getOrCreateOperationType(typeName: name);
    _selectedTypeId = id;
    _selectedTypeName = name;
    return id;
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_saveOnlyType) {
        // salvo solo tipo
        await _ensureTypeId();
      } else {
        // salvo capo + tipo + prezzo
        final name = _nameCtrl.text.trim();
        final price = _parsePrice(_priceCtrl.text);
        if (price == null) throw Exception('Prezzo non valido');

        final typeId = await _ensureTypeId();

        final garmentId = await _garmentService.createGarment(name: name);

        await _garmentService.setPriceForGarmentType(
          garmentId: garmentId,
          typeId: typeId,
          price: price,
        );
      }

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
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo capo / tipo'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NOME CAPO
            TextField(
              controller: _nameCtrl,
              enabled: !_saveOnlyType,
              decoration: const InputDecoration(labelText: 'Nome capo'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // TIPO OPERAZIONE (DROPDOWN + ADD)
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

                // Ordino lato UI (così non dipendi da indici Firestore)
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

                // Se l’id selezionato non esiste più, reset
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
                          final doc = docs.firstWhere((d) => d.id == v);
                          final data = doc.data();
                          setState(() {
                            _selectedTypeId = v;
                            _selectedTypeName = (data['name'] ?? '').toString();
                          });
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

                        final id = await _typeService.getOrCreateOperationType(typeName: res);

                        if (!mounted) return;
                        setState(() {
                          _selectedTypeId = id;
                          _selectedTypeName = res.trim();
                        });
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            // PREZZO
            if (!_saveOnlyType)
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prezzo',
                  prefixText: '€ ',
                ),
                onChanged: (_) => setState(() {}),
              ),

            const SizedBox(height: 10),

            // SOLO TIPO
            CheckboxListTile(
              value: _saveOnlyType,
              onChanged: (v) => setState(() => _saveOnlyType = v ?? false),
              title: const Text('Salva solo tipo'),
              contentPadding: EdgeInsets.zero,
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
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
          onPressed: (!_canSave || _loading) ? null : _save,
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
