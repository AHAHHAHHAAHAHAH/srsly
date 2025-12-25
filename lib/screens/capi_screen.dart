import 'dart:async';
import 'package:flutter/material.dart';
import '../services/client_service.dart';
import '../services/garment_service.dart';
import '../shell/app_shell.dart';
import '../shell/app_shell.dart' show AppSection;
import 'add_garment_dialog.dart';

class CapiScreen extends StatefulWidget {
  final String? clientId;

  /// clientId può essere null: la pagina deve restare comunque utilizzabile
  const CapiScreen({super.key, required this.clientId});

  @override
  State<CapiScreen> createState() => _CapiScreenState();
}

class _CapiScreenState extends State<CapiScreen> {
  final _garmentService = GarmentService();
  final _clientService = ClientService();

  // Search
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  // Operazioni "in attesa" (più capi, in verticale)
  final List<_PendingOp> _pending = [];

  // Cart
  final List<_CartItem> _cart = [];

  // ✅ Drag-scroll state (mouse-only)
  double _dragStartX = 0;
  double _dragStartOffset = 0;
  ScrollController? _dragController;

  // ✅ width fisse (necessarie per scroll orizzontale senza Expanded)
  static const double _wCapo = 190;
  static const double _wQty = 100;
  static const double _wPrezzo = 120;
  static const double _wTipo = 160;
  static const double _wRilascio = 180;
  static const double _wRitiro = 190;
  static const double _wAddBtn = 120;
  static const double _wDelBtn = 62;

  static const double _gap = 10;
  static const double _gapBig = 8;

  double get _rowMinWidth =>
    _wCapo +
    _gap +
    _wQty +
    _gap +
    _wPrezzo +
    _gap +
    _wTipo +
    _gap +
    _wRilascio +
    _gap +
    _wRitiro +
    _gap +
    _wAddBtn +
    _gapBig +
    _wDelBtn +
    24; // 👈 buffer anti-overflow


  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    for (final p in _pending) {
      p.dispose();
    }
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  int? _parseQty(String s) => int.tryParse(s.trim());
    double? _parseEuro(String s) {
    final t = s.trim().replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(t);
  }

String _fmtEuro(double v) => '€ ${v.toStringAsFixed(2).replaceAll('.', ',')}';


  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  String _fmtDateTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy · $hh:$min';
  }

  String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$dd/$mm/$yyyy';
}

Widget _pickupChip(_PendingOp op, String value) {
  final selected = op.pickupSlot == value;

  return InkWell(
    onTap: () {
      setState(() {
        op.pickupSlot = value;
      });
    },
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
    ),
  );
}



  int _qtyOf(_PendingOp op) {
    final q = _parseQty(op.qtyCtrl.text);
    return (q == null || q <= 0) ? 1 : q;
  }

  double _priceOf(_PendingOp op) {
    if (op.priceManuallyEdited) {
        final v = _parseEuro(op.priceCtrl.text);
        return v ?? (op.basePrice * _qtyOf(op));
  }
  // altrimenti prezzo automatico = basePrice * qty
  return op.basePrice * _qtyOf(op);  }

 
   
  void _addPending({
    required String id,
    required String name,
    required double basePrice,

  }) {
    setState(() {
     _pending.add(
    _PendingOp(
      garmentId: id,
      garmentName: name,
      basePrice: basePrice,
      qtyCtrl: TextEditingController(text: '1'),
      priceCtrl: TextEditingController(
        text: _fmtEuro(basePrice),
      ),
      priceManuallyEdited: false,
      type: 'Lavaggio',
      releaseDate: DateTime.now(),
      pickupDate: DateTime.now().add(const Duration(days: 1)),
      pickupSlot: 'Mattina', 
      hScrollCtrl: ScrollController(),
    ),
);

    });
  }

  void _removePendingAt(int index) {
    setState(() {
      _pending[index].dispose();
      _pending.removeAt(index);
    });
  }

  void _addPendingToCart(int index) {
    final op = _pending[index];

    final qty = _qtyOf(op);
    final price = _priceOf(op);

    if (qty <= 0) {
      _toast('Quantità non valida');
      return;
    }
    if (price < 0) {
      _toast('Prezzo non valido');
      return;
    }

    setState(() {
    _cart.add(
      _CartItem(
        garmentId: op.garmentId,
        garmentName: op.garmentName,
        qty: qty,
        price: price,
        type: op.type,
        releaseDate: op.releaseDate,
        pickupDate: op.pickupDate,
        pickupSlot: op.pickupSlot,
      ),
    );


      op.dispose();
      _pending.removeAt(index);
    });

    _toast('Aggiunto al carrello');
  }

  double get _total => _cart.fold(0, (sum, x) => sum + (x.price * x.qty));

  Future<void> _openCart() async {
    await showDialog(
  context: context,
  builder: (context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined),
              const SizedBox(width: 10),
              Text('Carrello (${_cart.length})'),
            ],
          ),
          content: SizedBox(
            width: 680,
            child: _cart.isEmpty
                ? const Text('Carrello vuoto')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: const [
                            Expanded(flex: 3, child: Text('Capo', style: TextStyle(fontWeight: FontWeight.w700))),
                            Expanded(flex: 1, child: Text('Qtà', style: TextStyle(fontWeight: FontWeight.w700))),
                            Expanded(flex: 2, child: Text('Prezzo', style: TextStyle(fontWeight: FontWeight.w700))),
                            Expanded(flex: 2, child: Text('Tipo', style: TextStyle(fontWeight: FontWeight.w700))),
                            Expanded(flex: 2, child: Text('Rilascio', style: TextStyle(fontWeight: FontWeight.w700))),
                            Expanded(flex: 3, child: Text('Ritiro', style: TextStyle(fontWeight: FontWeight.w700))),
                            SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // LISTA
                      SizedBox(
                        height: 260,
                        child: ListView.separated(
                          itemCount: _cart.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final it = _cart[i];
                            return Row(
                              children: [
                                Expanded(flex: 3, child: Text(it.garmentName)),
                                Expanded(flex: 1, child: Text('${it.qty}')),
                                Expanded(flex: 2, child: Text('€ ${it.price.toStringAsFixed(2)}')),
                                Expanded(flex: 2, child: Text(it.type)),
                                Expanded(flex: 2, child: Text(_fmtDate(it.releaseDate))),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${_fmtDate(it.pickupDate)} · ${it.pickupSlot}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setDialogState(() {
                                        _cart.removeAt(i);
                                      });
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // TOTALE
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Totale: € ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
            TextButton(
              onPressed: _cart.isEmpty
                  ? null
                  : () {
                      setDialogState(() {
                        _cart.clear();
                      });
                      setState(() {});
                      Navigator.of(context).pop();
                      _toast('Carrello svuotato');
                    },
              child: const Text('Svuota'),
            ),
          ],
        );
      },
    );
  },
);

  }

  Future<void> _printAndClose() async {
    if (_cart.isEmpty) {
      _toast('Carrello vuoto');
      return;
    }

    if (widget.clientId != null) {
      try {
        await _clientService.markClientServed(
          clientId: widget.clientId!,
          label: 'Scontrino',
        );
      } catch (e) {
        _toast('Errore aggiornamento storico: $e');
      }
    }

    setState(() {
      _cart.clear();
      for (final p in _pending) {
        p.dispose();
      }
      _pending.clear();
      _searchCtrl.clear();
      _query = '';
    });

    _toast('Operazione conclusa');

    if (widget.clientId != null) {
      AppShell.of(context).goToSection(AppSection.home);
    }
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.clientId != null)
            FutureBuilder(
              future: ClientService().getClientById(widget.clientId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 58,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final data = snapshot.data!.data() ?? {};
                final fullName = (data['fullName'] ?? '') as String;
                final number = (data['number'] ?? '') as String;

                  return Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    children: [
      const Icon(Icons.person, size: 16, color: Colors.grey),
      const SizedBox(width: 6),
      Text(
        '$fullName · $number',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  ),
);

              },
            ),
          const SizedBox(height: 14),

          // BLOCCO SUPERIORE
          Container(
            height: 330,
            padding: const EdgeInsets.all(18),
            decoration: _box(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ricerca capi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Scrivi anche 1 lettera…',
                    border: const OutlineInputBorder(),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Nuovo capo'),
                      onPressed: () async {
                        final res = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const AddGarmentDialog(),
                        );
                        if (res == true) _toast('Capo creato');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: _query.isEmpty
                      ? const SizedBox()
                      : StreamBuilder(
                          stream: _garmentService.searchGarments(_query),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'Errore: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) return const Text('Nessun capo trovato');

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, i) {
                                final doc = docs[i];
                                final d = doc.data();
                                final name = (d['name'] ?? '') as String;
                                final basePrice = (d['basePrice'] ?? 0).toDouble();

                                return ListTile(
                                  title: Text(name,style: const TextStyle(fontWeight: FontWeight.w800),),                                
                                  subtitle: Text('Prezzo base: € ${basePrice.toStringAsFixed(2)}'),
                                  onTap: () => _addPending(
                                    id: doc.id,
                                    name: name,
                                    basePrice: basePrice,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // BLOCCO INFERIORE
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _box(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operazioni',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _pending.isEmpty
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nessuna operazione inserita',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _pending.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final op = _pending[i];
                              final pickupDate = op.pickupDate;

                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragStart: (details) {
                                  _dragController = op.hScrollCtrl;
                                  _dragStartX = details.localPosition.dx;
                                  _dragStartOffset =
                                      op.hScrollCtrl.hasClients ? op.hScrollCtrl.offset : 0;
                                },
                                onHorizontalDragUpdate: (details) {
                                  final ctrl = _dragController;
                                  if (ctrl == null || !ctrl.hasClients) return;

                                  final dx = details.localPosition.dx - _dragStartX;
                                  final target = _dragStartOffset - dx;

                                  final min = ctrl.position.minScrollExtent;
                                  final max = ctrl.position.maxScrollExtent;

                                  ctrl.jumpTo(target.clamp(min, max));
                                },
                                onHorizontalDragEnd: (_) {
                                  _dragController = null;
                                },
                                child: SingleChildScrollView(
                                  controller: op.hScrollCtrl,
                                  scrollDirection: Axis.horizontal,
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: SizedBox(
                                    width: _rowMinWidth,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: _wCapo,
                                          child: _fieldBox(
                                            label: 'Capo',
                                            child: Text(
                                              op.garmentName,
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: _gap),
                                        SizedBox(
                                          width: _wQty,
                                          child: _fieldBox(
                                            label: 'Quantità',
                                            child: TextField(
                                              controller: op.qtyCtrl,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero, 
                                            ),
                                           onChanged: (_) {
                                              if (!mounted) return;

                                              // se NON è stato modificato a mano, aggiorniamo il prezzo automaticamente
                                              if (!op.priceManuallyEdited) {
                                                final auto = op.basePrice * _qtyOf(op);
                                                op.priceCtrl.text = _fmtEuro(auto);
                                              }

                                              setState(() {});
                                            },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: _gap),
                                        SizedBox(
                                            width: _wPrezzo,
                                            child: _fieldBox(
                                              label: 'Prezzo',
                                       child: TextField(
                                        controller: op.priceCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        
                                        onChanged: (_) {
                                          if (!mounted) return;
                                          op.priceManuallyEdited = true;
                                          setState(() {});
                                        },
                                      ),
                                        ),
                                        ),
                                        const SizedBox(width: _gap),
                                        SizedBox(
                                          width: _wTipo,
                                          child: _fieldBox(
                                            label: 'Tipo',
                                            child: DropdownButtonHideUnderline(
                                              child: SizedBox(
                                                height: 24, // 🔒 altezza fissa = niente espansione verticale
                                                child: DropdownButton<String>(
                                                  value: op.type,
                                                  items: const [
                                                    DropdownMenuItem(value: 'Lavaggio', child: Text('Lavaggio')),
                                                    DropdownMenuItem(value: 'Stiratura', child: Text('Stiratura')),
                                                    DropdownMenuItem(value: 'Lav+Stiro', child: Text('Lav+Stiro')),
                                                    DropdownMenuItem(value: 'Altro', child: Text('Altro')),
                                                  ],
                                                  onChanged: (v) {
                                                    setState(() => op.type = v ?? 'Lavaggio');
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: _gap),
                                        SizedBox(
                                          width: _wRilascio,
                                          child: _fieldBox(
                                            label: 'Rilascio',
                                            child: Text(
                                              _fmtDateTime(op.releaseDate),
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: _gap),
                                     
                                          SizedBox(
                                            width: _wRitiro,
                                            child: _fieldBox(
                                              label: 'Ritiro',
                                              child: Row(
                                                children: [
                                                  // icona calendario
                                                  InkWell(
                                                    onTap: () async {
                                                      final picked = await showDatePicker(
                                                        context: context,
                                                        initialDate: op.pickupDate,
                                                        firstDate: DateTime.now(),
                                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                                      );
                                                      if (picked == null) return;

                                                      setState(() {
                                                        op.pickupDate = DateTime(
                                                          picked.year,
                                                          picked.month,
                                                          picked.day,
                                                        );
                                                      });
                                                    },
                                                    child: Icon(
                                                      Icons.calendar_month,
                                                      size: 20,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),

                                                  const SizedBox(width: 10),

                                                  Expanded(
                                                    child: DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                        value: op.pickupSlot,
                                                        isDense: true,
                                                        items: const [
                                                          DropdownMenuItem(
                                                            value: 'Mattina',
                                                            child: Text('Mattina'),
                                                          ),
                                                          DropdownMenuItem(
                                                            value: 'Pomeriggio',
                                                            child: Text('Pomeriggio'),
                                                          ),
                                                        ],
                                                        onChanged: (v) {
                                                          if (v == null) return;
                                                          setState(() => op.pickupSlot = v);
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),


                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: _wAddBtn,
                                          height: 44,
                                          child: ElevatedButton(
                                            onPressed: () => _addPendingToCart(i),
                                            style: ElevatedButton.styleFrom(
                                              shape: const StadiumBorder(),
                                              padding: const EdgeInsets.symmetric(horizontal: 18),
                                            ),
                                            child: const Text('Aggiungi'),
                                          ),
                                        ),
                                        const SizedBox(width: _gapBig),
                                        SizedBox(
                                          width: _wDelBtn,
                                          height: 44,
                                          child: OutlinedButton(
                                            onPressed: () => _removePendingAt(i),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              side: BorderSide(
                                                color: Colors.red.withOpacity(0.35),
                                              ),
                                            ),
                                            child: const Icon(Icons.delete, color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _openCart,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text('Carrello (${_cart.length})'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        onPressed: _cart.isEmpty ? null : _printAndClose,
                        icon: const Icon(Icons.print),
                        label: const Text('Stampa'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Totale: € ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _fieldBox({required String label, required Widget child}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), // ⬅ padding calibrato
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.03),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black.withOpacity(0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ⭐ CHIAVE
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.1, // ⬅ evita overflow del label
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}


}

class _PendingOp {
  final String garmentId;
  final String garmentName;

  DateTime pickupDate;
  String pickupSlot;

  // prezzo base del capo (listino)
  final double basePrice;

  // input modificabili
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  // se true: l’utente ha modificato il prezzo a mano
  bool priceManuallyEdited;

  String type;

  final DateTime releaseDate;

 

  final ScrollController hScrollCtrl;

  _PendingOp({
    required this.garmentId,
    required this.garmentName,
    required this.basePrice,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.priceManuallyEdited,
    required this.type,
    required this.releaseDate,
    required this.pickupDate,
    required this.hScrollCtrl,
    required this.pickupSlot,
  });

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
    hScrollCtrl.dispose();
  }
}


class _CartItem {
  final String garmentId;
  final String garmentName;
  final int qty;
  final double price;
  final String type;
  final DateTime releaseDate;
  final DateTime pickupDate;
  final String pickupSlot;

  _CartItem({
    required this.garmentId,
    required this.garmentName,
    required this.qty,
    required this.price,
    required this.type,
    required this.releaseDate,
    required this.pickupDate,
    required this.pickupSlot,
  });
}

