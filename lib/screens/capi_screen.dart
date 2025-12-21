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

  // Search
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  // Operazioni "in attesa" (più capi, in verticale)
  final List<_PendingOp> _pending = [];

  // Cart
  final List<_CartItem> _cart = [];

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

  double? _parsePrice(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  void _addPending({
    required String id,
    required String name,
    required double basePrice,
  }) {
    // Non “sostituisce” niente: aggiunge una riga in verticale
    setState(() {
      _pending.add(
        _PendingOp(
          garmentId: id,
          garmentName: name,
          qtyCtrl: TextEditingController(text: '1'),
          priceCtrl: TextEditingController(
            text: basePrice.toStringAsFixed(2).replaceAll('.', ','),
          ),
          type: 'Lavaggio',
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

    final qty = _parseQty(op.qtyCtrl.text);
    final price = _parsePrice(op.priceCtrl.text);

    if (qty == null || qty <= 0) {
      _toast('Quantità non valida');
      return;
    }
    if (price == null || price < 0) {
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
        ),
      );

      // una volta aggiunto al carrello, puoi anche togliere la riga pending
      op.dispose();
      _pending.removeAt(index);
    });

    _toast('Aggiunto al carrello');
  }

  double get _total => _cart.fold(0, (sum, x) => sum + (x.price * x.qty));

  Future<void> _openCart() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                            child: Text(
                              'Capo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Qtà',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Prezzo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Tipo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
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
                              Expanded(child: Text('${it.qty}')),
                              Expanded(
                                child: Text(it.price.toStringAsFixed(2)),
                              ),
                              Expanded(child: Text(it.type)),
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
                    setState(() => _cart.clear());
                    Navigator.of(context).pop();
                    _toast('Carrello svuotato');
                  },
            child: const Text('Svuota'),
          ),
        ],
      ),
    );
  }

  Future<void> _printAndClose() async {
    if (_cart.isEmpty) {
      _toast('Carrello vuoto');
      return;
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

    // Se stai lavorando su un cliente reale, dopo stampa torni Home e resetti il contesto.
    // Se NON c'è cliente (modalità "a vuoto"), resti qui.
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
          // ===== header "stai servendo" SOLO se clientId != null
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

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stai servendo:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fullName — $number',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 14),

          // =========================
          // BLOCCO SUPERIORE
          // =========================
          Container(
            height: 420,
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
                        if (res == true) {
                          _toast('Capo creato');
                        }
                      },
                    ),
                    // ✅ TOLTO "Selezionato: ..." come richiesto
                  ],
                ),
                const SizedBox(height: 10),

                // Risultati (scroll solo qui)
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
                            if (docs.isEmpty) {
                              return const Text('Nessun capo trovato');
                            }

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, i) {
                                final doc = docs[i];
                                final d = doc.data();
                                final name = (d['name'] ?? '') as String;
                                final basePrice = (d['basePrice'] ?? 0).toDouble();

                                return ListTile(
                                  title: Text(name),
                                  subtitle: Text(
                                    'Prezzo base: € ${basePrice.toStringAsFixed(2)}',
                                  ),
                                  // ✅ Ora il tap AGGIUNGE una riga in basso (non sostituisce)
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

          // =========================
          // BLOCCO INFERIORE
          // =========================
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _box(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ tolta la frase "(seleziona un capo sopra)" come richiesto
                  const Text(
                    'Operazioni',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),

                  const SizedBox(height: 12),

                  // ✅ Lista verticale + scrollbar se tante
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

                              return Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _fieldBox(
                                      label: 'Capo',
                                      child: Text(
                                        op.garmentName,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _fieldBox(
                                      label: 'Quantità',
                                      child: TextField(
                                        controller: op.qtyCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _fieldBox(
                                      label: 'Prezzo',
                                      child: TextField(
                                        controller: op.priceCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _fieldBox(
                                      label: 'Tipo',
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: op.type,
                                          isDense: true,
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
                                  const SizedBox(width: 12),

                                  // ✅ Aggiungi pill (per riga)
                                  SizedBox(
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

                                  const SizedBox(width: 14),

                                  // ✅ delete X (per riga)
                                  SizedBox(
                                    height: 44,
                                    width: 52,
                                    child: OutlinedButton(
                                      onPressed: () => _removePendingAt(i),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Icon(Icons.close),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 12),

                  // bottom actions: carrello + stampa
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
        ],
      ),
    );
  }
}

class _PendingOp {
  final String garmentId;
  final String garmentName;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  String type;

  _PendingOp({
    required this.garmentId,
    required this.garmentName,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.type,
  });

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _CartItem {
  final String garmentId;
  final String garmentName;
  final int qty;
  final double price;
  final String type;

  _CartItem({
    required this.garmentId,
    required this.garmentName,
    required this.qty,
    required this.price,
    required this.type,
  });
}
