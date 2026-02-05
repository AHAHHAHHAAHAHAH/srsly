import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import '../services/auth_service.dart';
import '../core/company_context.dart';

import '../services/client_service.dart';
import '../services/garment_service.dart';
import '../services/operation_type_service.dart';
import '../services/order_service.dart';

import '../shell/app_shell.dart';
import '../shell/app_shell.dart' show AppSection;

import 'add_garment_dialog.dart';
import 'add_operation_for_garment_dialog.dart';
import '../printing/print_models.dart';
import '../printing/print_service.dart';
import '../printing/receipt_builder.dart';
import '../printing/print_preview_dialog.dart';

class CapiScreen extends StatefulWidget {
  final String? clientId;

  const CapiScreen({super.key, required this.clientId});

  @override
  State<CapiScreen> createState() => _CapiScreenState();
}

class _CapiScreenState extends State<CapiScreen> {
  final _garmentService = GarmentService();
  final _clientService = ClientService();
  final _typeService = OperationTypeService();

  List<Map<String, String>> _operationTypes = [];

  StreamSubscription? _typesSub;

  bool _typesLoaded = false;
  bool _isPrinting = false;
  final TextEditingController _depositCtrl = TextEditingController(text: '0,00');
  bool _isPaid = false;

  double _deposit = 0.0;
  double get _remaining {
    final r = _total - _deposit;
    return r < 0 ? 0 : r;
  }

  double _parseEuroToDouble(String s) {
    final t = s
        .trim()
        .replaceAll('€', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(t) ?? 0.0;
  }

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

  // ✅ width fisse
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
      24; 

  @override
  void initState() {
    super.initState();
    _listenTypes();
  }

  void _listenTypes() {
    _typesSub?.cancel();
    _typesSub = _typeService.streamTypes().listen((snap) {
      final docs = snap.docs.toList();

      DateTime dt(dynamic v) =>
          v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

      docs.sort((a, b) =>
          dt(a.data()['createdAt']).compareTo(dt(b.data()['createdAt'])));

      final types = docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': (data['name'] ?? '').toString(),
        };
      }).where((t) => (t['name'] ?? '').toString().trim().isNotEmpty).toList();

      if (!mounted) return;
      setState(() {
        _operationTypes = types;
        _typesLoaded = true;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _operationTypes = [];
        _typesLoaded = true;
      });
    });
  }

  Future<void> _loadTypes() async {
    final snap = await _typeService.streamTypes().first;

    final docs = snap.docs.toList();

    DateTime _dtFrom(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    docs.sort((a, b) {
      final da = _dtFrom(a.data()['createdAt']);
      final db = _dtFrom(b.data()['createdAt']);
      return da.compareTo(db); 
    });

    _operationTypes = docs
        .map((d) => {
              'id': d.id,
              'name': d['name'] as String,
            })
        .toList();

    if (!mounted) return;
    setState(() => _typesLoaded = true);
  }

  Future<void> _onTypeSelected(_PendingOp op, String typeId) async {
    final prices = await _garmentService.getPricesForGarment(op.garmentId);
    final price = prices[typeId] ?? 0;

    if (!mounted) return;

    setState(() {
      op.typeId = typeId;
      op.typeName =
          _operationTypes.firstWhere((t) => t['id'] == typeId)['name']!;
      op.priceManuallyEdited = false;
      op.priceCtrl.text = _fmtEuro(price);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _depositCtrl.dispose();
    _typesSub?.cancel();

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
    final t = s
        .trim()
        .replaceAll('€', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(t);
  }

  double _depositValue() {
    final v = _parseEuro(_depositCtrl.text) ?? 0;
    return v < 0 ? 0 : v;
  }

  double _remainingTotal() {
    final r = _total - _depositValue();
    return r < 0 ? 0 : r;
  }

  String _fmtEuro(double v) =>
      '€ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

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
      return v ?? (op.unitPrice * _qtyOf(op));
    }
    return op.unitPrice * _qtyOf(op);
  }

  void _addPending({
    required String id,
    required String name,
    required double basePrice,
  }) {
    final op = _PendingOp(
      garmentId: id,
      garmentName: name,
      unitPrice: basePrice,
      currentQty: 1,
      qtyCtrl: TextEditingController(text: '1'),
      priceCtrl: TextEditingController(text: _fmtEuro(basePrice * 1)),
      priceManuallyEdited: false,
      typeId: null,
      typeName: '',
      releaseDate: DateTime.now(),
      pickupDate: DateTime.now().add(const Duration(days: 1)),
      pickupSlot: 'Mattina',
      hScrollCtrl: ScrollController(),
      validOpIds: [],
      isOpsLoaded: false,
    );

    setState(() {
      _pending.add(op);
    });

    _garmentService.getPricesForGarment(id).then((pricesMap) {
      if (!mounted) return;
      setState(() {
        op.validOpIds = pricesMap.keys.toList();
        op.isOpsLoaded = true;
      });
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
    if (op.typeId == null) {
      _toast('Seleziona un tipo');
      return;
    }

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
          type: op.typeName,
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

  double get _total => _cart.fold(0, (sum, x) => sum + x.price);

  Future<void> _openCart() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
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
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: const [
                                Expanded(
                                    flex: 3,
                                    child: Text('Capo',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700))),
                                Expanded(
                                    flex: 1,
                                    child: Text('Qtà',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700))),
                                Expanded(
                                    flex: 2,
                                    child: Text('Prezzo',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700))),
                                Expanded(
                                    flex: 2,
                                    child: Text('Tipo',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700))),
                                Expanded(
                                    flex: 2,
                                    child: Text('Rilascio',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700))),
                                Expanded(
                                    flex: 3,
                                    child: Text('Ritiro',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700))),
                                SizedBox(width: 40),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 260,
                            child: ListView.separated(
                              itemCount: _cart.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final it = _cart[i];
                                return Row(
                                  children: [
                                    Expanded(
                                        flex: 3, child: Text(it.garmentName)),
                                    Expanded(flex: 1, child: Text('${it.qty}')),
                                    Expanded(
                                        flex: 2,
                                        child: Text(
                                            '€ ${it.price.toStringAsFixed(2)}')),
                                    Expanded(flex: 2, child: Text(it.type)),
                                    Expanded(
                                        flex: 2,
                                        child: Text(_fmtDate(it.releaseDate))),
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
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
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
    if (_isPrinting) return;

    if (_cart.isEmpty) {
      _toast('Carrello vuoto');
      return;
    }
    if (widget.clientId == null) {
      _toast('Cliente non valido');
      return;
    }

    setState(() => _isPrinting = true);

    final cartCopy = List<_CartItem>.from(_cart);
    final totalCopy = cartCopy.fold(0.0, (s, x) => s + x.price);
    final depositCopy = _depositValue();
    final isPaidCopy = _isPaid;

    try {
      final clientSnap =
          await ClientService().getClientById(widget.clientId!);
      final client = clientSnap.data();
      if (client == null) {
        _toast('Cliente non trovato');
        return;
      }

      final companyId = await CompanyContext.instance.getCompanyId();
      final companySnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();

      final company = companySnap.data() ?? {};

      final companyName = (company['companyName'] ?? '').toString();
      final ownerFullName = (company['ownerFullName'] ?? '').toString();
      final addressStreet = (company['addressStreet'] ?? '').toString();
      final addressCap = (company['addressCap'] ?? '').toString();
      final addressCity = (company['addressCity'] ?? '').toString();
      final ownerPhone = (company['ownerPhone'] ?? '').toString();

      final previewTicket = AppShell.of(context).currentPreviewTicket;
      if (previewTicket == null) {
        _toast('Preview ticket non disponibile (header non caricato)');
        return;
      }

      final previewData = PrintOrderData(
        ticketNumber: previewTicket,
        clientName: (client['fullName'] ?? '') as String,
        clientPhone: (client['number'] ?? '') as String,
        createdAt: DateTime.now(),
        pickupDate: cartCopy.first.pickupDate,
        pickupSlot: cartCopy.first.pickupSlot,
        items: cartCopy
            .map((c) => PrintOrderItem(
                  garmentName: c.garmentName,
                  qty: c.qty,
                  price: c.price,
                  operationName: c.type,
                ))
            .toList(),
        deposit: depositCopy,
        isPaid: isPaidCopy,
        total: totalCopy,
        companyName: companyName,
        ownerFullName: ownerFullName,
        addressStreet: addressStreet,
        addressCap: addressCap,
        addressCity: addressCity,
        ownerPhone: ownerPhone,
      );

      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PrintPreviewDialog(data: previewData),
      );

      if (confirmed != true) {
        _toast('Stampa annullata');
        return;
      }

      final orderItems = cartCopy.map((c) {
        return {
          'garmentId': c.garmentId,
          'garmentName': c.garmentName,
          'qty': c.qty,
          'unitPrice': (c.qty > 0) ? (c.price / c.qty) : c.price,
          'lineTotal': c.price,
          'operationTypeName': c.type,
          'releaseDate': Timestamp.fromDate(c.releaseDate),
          'pickupDate': Timestamp.fromDate(c.pickupDate),
          'pickupSlot': c.pickupSlot,
        };
      }).toList();

      final int ticketNumber = await OrderService().createOrder(
        clientId: widget.clientId!,
        clientName: (client['fullName'] ?? '') as String,
        clientPhone: (client['number'] ?? '') as String,
        items: orderItems,
        deposit: depositCopy,
        isPaid: isPaidCopy,
        total: totalCopy,
      );

      final finalData = PrintOrderData(
        ticketNumber: ticketNumber,
        clientName: previewData.clientName,
        clientPhone: previewData.clientPhone,
        createdAt: previewData.createdAt,
        pickupDate: previewData.pickupDate,
        pickupSlot: previewData.pickupSlot,
        items: previewData.items,
        deposit: previewData.deposit,
        isPaid: previewData.isPaid,
        total: totalCopy,
        companyName: companyName,
        ownerFullName: ownerFullName,
        addressStreet: addressStreet,
        addressCap: addressCap,
        addressCity: addressCity,
        ownerPhone: ownerPhone,
      );

      await PrintService.printAllSmart(finalData);

      await _clientService.markClientServed(
        clientId: widget.clientId!,
        label: 'Scontrino',
      );

      setState(() {
        _cart.clear();
        for (final p in _pending) {
          p.dispose();
        }
        _pending.clear();
        _searchCtrl.clear();
        _query = '';

        _depositCtrl.text = '0,00';
        _deposit = 0.0;
        _isPaid = false;
      });

      _toast('Operazione conclusa');
      AppShell.of(context).goToSection(AppSection.home);
    } catch (e) {
      _toast('Errore salvataggio ordine: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }
  
  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black.withOpacity(0.04)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 2),

          Container(
            height: 330,
            padding: const EdgeInsets.all(24),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ricerca capi',
                      style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('NUOVO CAPO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final res = await AddGarmentDialog.open(context);
                        if (res == true) {
                          _toast('Salvato correttamente');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Scrivi anche 1 lettera…',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black, width: 1.5),
                    ),
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
                const SizedBox(height: 16),
                Expanded(
                  child: _query.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dry_cleaning, size: 48, color: Colors.grey.shade200),
                              const SizedBox(height: 12),
                              Text('Cerca un capo per iniziare', style: TextStyle(color: Colors.grey.shade400)),
                            ],
                          ),
                        )
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
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return const Text('Nessun capo trovato');
                            }

                            return ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final doc = docs[i];
                                final d = doc.data();
                                final name = (d['name'] ?? '') as String;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                                    tooltip: 'Aggiungi operazione',
                                    onPressed: () async {
                                      final res =
                                          await AddOperationForGarmentDialog
                                              .open(
                                        context,
                                        garmentId: doc.id,
                                        garmentName: name,
                                      );
                                      if (res == true) {
                                        _toast('Operazione salvata');
                                      }
                                    },
                                  ),
                                  onTap: () => _addPending(
                                    id: doc.id,
                                    name: name,
                                    basePrice: 0,
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

          Flexible(
            fit: FlexFit.loose,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operazioni',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 20),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, i) {
                              final op = _pending[i];
                              final List<Map<String, String>> visibleTypes = (!op.isOpsLoaded) 
                                  ? [] 
                                  : (op.validOpIds.isEmpty 
                                      ? _operationTypes 
                                      : _operationTypes.where((t) => op.validOpIds.contains(t['id'])).toList());

                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragStart: (details) {
                                  _dragController = op.hScrollCtrl;
                                  _dragStartX = details.localPosition.dx;
                                  _dragStartOffset = op.hScrollCtrl.hasClients
                                      ? op.hScrollCtrl.offset
                                      : 0;
                                },
                                onHorizontalDragUpdate: (details) {
                                  final ctrl = _dragController;
                                  if (ctrl == null || !ctrl.hasClients) return;

                                  final dx =
                                      details.localPosition.dx - _dragStartX;
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
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  child: SizedBox(
                                    width: _rowMinWidth,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: _wCapo,
                                          // Box Capo
                                          child: _fieldBox(
                                            label: 'Capo',
                                            child: Text(
                                              op.garmentName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
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
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.zero,
                                              ),
                                              onChanged: (_) {
                                                if (!mounted) return;
                                                final qty = _qtyOf(op);
                                                if (op.priceManuallyEdited) {
                                                  final unit = op.manualUnitPrice;
                                                  if (unit != null) {
                                                    op.priceCtrl.text = _fmtEuro(unit * qty);
                                                  } else {
                                                    final currentTotal = _parseEuro(op.priceCtrl.text);
                                                    if (currentTotal != null) {
                                                      final derivedUnit = currentTotal / (qty == 0 ? 1 : qty);
                                                      op.manualUnitPrice = derivedUnit;
                                                      op.priceCtrl.text = _fmtEuro(derivedUnit * qty);
                                                    }
                                                  }
                                                } else {
                                                  op.priceCtrl.text = _fmtEuro(op.unitPrice * qty);
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
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.zero,
                                              ),
                                              onChanged: (_) {
                                                if (!mounted) return;
                                                op.priceManuallyEdited = true;
                                                final total = _parseEuro(op.priceCtrl.text);
                                                final qty = _qtyOf(op);
                                                if (total != null && qty > 0) {
                                                  op.manualUnitPrice =
                                                      total / qty;
                                                }
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
                                            child: Stack(
                                              children: [
                                                // 1. STATI CARICAMENTO
                                                if (!_typesLoaded)
                                                  const Padding(padding: EdgeInsets.symmetric(vertical: 2), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                                                else if (!op.isOpsLoaded)
                                                  const Padding(padding: EdgeInsets.symmetric(vertical: 2), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                                                else if (visibleTypes.isEmpty)
                                                  const Padding(padding: EdgeInsets.only(top: 2), child: Text('Nessun tipo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)))
                                                else
                                                // 2. TESTO VISIBILE "MANUALE" (NO Grassetto, NO Troncamento)
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 20.0, top: 2), 
                                                    child: Text(
                                                      (op.typeId != null && op.typeName.isNotEmpty) 
                                                          ? op.typeName 
                                                          : 'Seleziona',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.normal, // RIMOSSO grassetto
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                
                                                // 3. ICONA FRECCIA
                                                if (_typesLoaded && op.isOpsLoaded && visibleTypes.isNotEmpty)
                                                  const Positioned(
                                                    right: -2,
                                                    top: -2,
                                                    child: Icon(Icons.arrow_drop_down, color: Colors.black54),
                                                  ),

                                                // 4. DROPDOWN "FANTASMA" (per click e menu)
                                                if (_typesLoaded && op.isOpsLoaded && visibleTypes.isNotEmpty)
                                                  Positioned.fill(
                                                    child: DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                        isExpanded: true,
                                                        value: (op.typeId != null && visibleTypes.any((t) => t['id'] == op.typeId))
                                                            ? op.typeId
                                                            : null,
                                                        // MENU VISIBILE (rimosso style: transparent)
                                                        items: visibleTypes.map((t) {
                                                          return DropdownMenuItem<String>(
                                                            value: t['id'],
                                                            child: Text(t['name']!, 
                                                              style: const TextStyle(color: Colors.black87), // Colore esplicito per il menu
                                                              overflow: TextOverflow.visible
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (typeId) {
                                                          if (typeId == null) return;
                                                          final type = _operationTypes.firstWhere((t) => t['id'] == typeId);
                                                          setState(() {
                                                            op.typeId = typeId;
                                                            op.typeName = type['name']!;
                                                            op.priceManuallyEdited = false;
                                                            op.priceCtrl.text = _fmtEuro(0);
                                                          });

                                                          () async {
                                                            try {
                                                              final prices = await _garmentService.getPricesForGarment(op.garmentId);
                                                              final price = prices[typeId] ?? 0;
                                                              if (!mounted) return;
                                                              setState(() {
                                                                op.unitPrice = (price as num).toDouble();
                                                                final qty = _qtyOf(op);
                                                                op.manualUnitPrice = null;
                                                                op.priceManuallyEdited = false;
                                                                op.priceCtrl.text = _fmtEuro(op.unitPrice * qty);
                                                              });
                                                            } catch (e) {
                                                              if (!mounted) return;
                                                              _toast('Prezzo non leggibile: $e');
                                                            }
                                                          }();
                                                        },
                                                        // ICONA E TESTO BOTTONE NASCOSTI (perché usiamo il layer manuale)
                                                        icon: const SizedBox.shrink(),
                                                        selectedItemBuilder: (context) {
                                                          return visibleTypes.map((e) => const SizedBox.shrink()).toList();
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                              ],
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
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
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
                                                InkWell(
                                                  onTap: () async {
                                                    final picked =
                                                        await showDatePicker(
                                                      context: context,
                                                      initialDate:
                                                          op.pickupDate,
                                                      firstDate: DateTime.now(),
                                                      lastDate: DateTime.now()
                                                          .add(const Duration(
                                                              days: 365)),
                                                      locale: const Locale('it', 'IT'),
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
                                                  child:
                                                      DropdownButtonHideUnderline(
                                                    child:
                                                        DropdownButton<String>(
                                                      value: op.pickupSlot,
                                                      isDense: true,
                                                      isExpanded: true, 
                                                      items: const [
                                                        DropdownMenuItem(
                                                          value: 'Mattina',
                                                          child:
                                                              Text('Mattina'),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'Pomeriggio',
                                                          child: Text(
                                                              'Pomeriggio'),
                                                        ),
                                                      ],
                                                      onChanged: (v) {
                                                        if (v == null) return;
                                                        setState(() =>
                                                            op.pickupSlot = v);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // BOTTONI
                                        SizedBox(
                                          width: _wAddBtn,
                                          height: 44, 
                                          child: ElevatedButton(
                                            onPressed: (op.typeId == null)
                                                ? null
                                                : () => _addPendingToCart(i),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              elevation: 0,
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
                                            onPressed: () =>
                                                _removePendingAt(i),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              side: BorderSide(
                                                color: Colors.red
                                                    .withOpacity(0.35),
                                              ),
                                            ),
                                            child: const Icon(Icons.delete,
                                                color: Colors.red),
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
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        onPressed: (_cart.isEmpty || _isPrinting)
                            ? null
                            : _printAndClose,
                        icon: const Icon(Icons.print),
                        label: const Text('Stampa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Totale: € ${_total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _depositCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Acconto',
                            prefixText: '€ ',
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (v) {
                            setState(() => _deposit = _parseEuroToDouble(v));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => setState(() => _isPaid = !_isPaid),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isPaid ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PAGATO',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Rimanenza: € ${_remaining.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.1,
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

  double unitPrice;
  double? manualUnitPrice;

  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  bool priceManuallyEdited;

  String? typeId;
  String typeName;

  final DateTime releaseDate;
  final ScrollController hScrollCtrl;

  int currentQty;

  List<String> validOpIds;
  bool isOpsLoaded;

  _PendingOp({
    required this.garmentId,
    required this.garmentName,
    required this.unitPrice,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.priceManuallyEdited,
    required this.typeId,
    required this.typeName,
    required this.releaseDate,
    required this.pickupDate,
    required this.hScrollCtrl,
    required this.pickupSlot,
    required this.currentQty,
    this.manualUnitPrice,
    required this.validOpIds,
    required this.isOpsLoaded,
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