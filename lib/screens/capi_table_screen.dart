import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/garment_service.dart';
import '../services/operation_type_service.dart';
///////AHAHAHAHAHHAHAHAHAAHHAHAHAHHA
class CapiTableScreen extends StatefulWidget {
  final String? clientId;
  const CapiTableScreen({super.key, required this.clientId});

  @override
  State<CapiTableScreen> createState() => _CapiTableScreenState();
}

class _CapiTableScreenState extends State<CapiTableScreen> {
  final _garmentService = GarmentService();
  final _typeService = OperationTypeService();

  Map<String, String> _opTypeMap = {};
  bool _isLoadingTypes = true;

  final List<String> _alphabet = List.generate(26, (i) => String.fromCharCode(65 + i));
  String _selectedLetter = 'A';

  @override
  void initState() {
    super.initState();
    _loadOperationTypes();
  }

  Future<void> _loadOperationTypes() async {
    try {
      final snap = await _typeService.streamTypes().first;
      final map = <String, String>{};
      for (var doc in snap.docs) {
        map[doc.id] = (doc.data()['name'] ?? '').toString();
      }
      if (mounted) {
        setState(() {
          _opTypeMap = map;
          _isLoadingTypes = false;
        });
      }
    } catch (e) {
      debugPrint('Errore caricamento tipi: $e');
    }
  }

  // Stile del box Alfabeto (quello che ti piaceva)
  BoxDecoration _headerBoxDecoration() => BoxDecoration(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =======================
          // 1. BARRA ALFABETO (Ripristinata)
          // =======================
      // =======================
          // 1. BARRA ALFABETO + TOTALE
          // =======================
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _headerBoxDecoration(), // Usa lo stile definito nel file
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.black87),
                const SizedBox(width: 16),
                
                // LISTA LETTERE SCORREVOLE
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _alphabet.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, i) {
                      final letter = _alphabet[i];
                      final isSelected = letter == _selectedLetter;
                      return Center(
                        child: InkWell(
                          onTap: () => setState(() => _selectedLetter = letter),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              letter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // --- NUOVO PEZZO: TOTALE CAPI ---
                const SizedBox(width: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _garmentService.searchGarments(''), // Conta tutti i capi
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Capi totali: $count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  },
                ),
                // --------------------------------
              ],
            ),
          ),

          const SizedBox(height: 24),

          // =======================
          // 2. TABELLA CAPI
          // =======================
          Expanded(
            child: _isLoadingTypes
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : StreamBuilder<QuerySnapshot>(
                    stream: _garmentService.searchGarments(''), 
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Errore: ${snapshot.error}'));
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.black));
                      }

                      final allDocs = snapshot.data?.docs ?? [];
                      
                      // FILTRO LOCALE
                      final filteredDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toUpperCase();
                        return name.startsWith(_selectedLetter);
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER TABELLA (Ripristinato stile originale)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RISULTATI PER "$_selectedLetter"',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w700, 
                                  color: Colors.grey.shade500, 
                                  letterSpacing: 1.0
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${filteredDocs.length} CAPI TROVATI',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // INTESTAZIONE COLONNE (Semplice e allineata)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: const [
                                Expanded(flex: 4, child: Text('NOME CAPO', style: _headerStyle)),
                                SizedBox(width: 12),
                                Expanded(flex: 2, child: Text('AGGIUNTO IL', style: _headerStyle)),
                                SizedBox(width: 12),
                                Expanded(flex: 3, child: Text('OPERAZIONE', style: _headerStyle)),
                                SizedBox(width: 12),
                                Expanded(flex: 2, child: Text('PREZZO', style: _headerStyle)),
                                SizedBox(width: 100), // Spazio Azioni
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // LISTA RIGHE
                          Expanded(
                            child: filteredDocs.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade200),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Nessun capo inizia per "$_selectedLetter"',
                                          style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4), // Padding per l'ombra
                                    itemCount: filteredDocs.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 24), // Spazio aumentato tra le righe
                                    itemBuilder: (context, i) {
                                      final doc = filteredDocs[i];
                                      return _GarmentRow(
                                        key: ValueKey(doc.id),
                                        doc: doc,
                                        opTypeMap: _opTypeMap,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  fontWeight: FontWeight.w800, 
  fontSize: 11, 
  color: Colors.black45,
  letterSpacing: 0.5
);

// ==========================================
// WIDGET RIGA "CARD SOSPESA" (Ombra Potenziata)
// ==========================================
class _GarmentRow extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, String> opTypeMap;

  const _GarmentRow({
    super.key,
    required this.doc,
    required this.opTypeMap,
  });

  @override
  State<_GarmentRow> createState() => _GarmentRowState();
}

class _GarmentRowState extends State<_GarmentRow> {
  final _garmentService = GarmentService();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  
  late String _originalName;
  String? _selectedOpId; 
  double? _originalPriceOfSelectedOp; 
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final data = widget.doc.data() as Map<String, dynamic>;
    _originalName = data['name'] ?? '';
    _nameCtrl = TextEditingController(text: _originalName);
    _priceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  String _fmtEuro(dynamic val) {
    if (val == null) return '0,00';
    double v = (val is num) ? val.toDouble() : 0.0;
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _parseEuro(String s) {
    return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  }

  String _fmtDate(Timestamp? ts) {
    if (ts == null) return '--/--/----';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  void _checkDirty() {
    final currentName = _nameCtrl.text.trim();
    bool nameChanged = currentName != _originalName;
    
    bool priceChanged = false;
    if (_selectedOpId != null && _originalPriceOfSelectedOp != null) {
      final currentPrice = _parseEuro(_priceCtrl.text);
      priceChanged = (currentPrice - _originalPriceOfSelectedOp!).abs() > 0.001;
    }

    final newDirty = nameChanged || priceChanged;
    if (newDirty != _isDirty) {
      setState(() => _isDirty = newDirty);
    }
  }

  Future<void> _saveChanges() async {
    if (!_isDirty) return;

    try {
      final newName = _nameCtrl.text.trim();
      final batch = FirebaseFirestore.instance.batch();

      if (newName != _originalName) {
        final docRef = FirebaseFirestore.instance.collection('garments').doc(widget.doc.id);
        batch.update(docRef, {
          'name': newName,
          'nameLowerCase': newName.toLowerCase(),
        });
      }

      if (_selectedOpId != null) {
        final newPrice = _parseEuro(_priceCtrl.text);
        final priceRef = FirebaseFirestore.instance
            .collection('garments')
            .doc(widget.doc.id)
            .collection('prices')
            .doc(_selectedOpId);
        
        batch.update(priceRef, {
          'price': newPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifiche salvate!'), backgroundColor: Colors.green, duration: Duration(milliseconds: 800)),
        );
      }

      setState(() {
        _originalName = newName;
        if (_selectedOpId != null) {
          _originalPriceOfSelectedOp = _parseEuro(_priceCtrl.text);
        }
        _isDirty = false;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteGarment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare Capo?'),
        content: Text('Sei sicuro di voler eliminare "$_originalName"?\nQuesta azione è irreversibile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
         await FirebaseFirestore.instance.collection('garments').doc(widget.doc.id).delete();
       }
  }

  // Helper per creare i Box
  Widget _boxWrapper({required Widget child, bool active = true, Color? bgColor}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? Colors.grey.shade300 : Colors.transparent,
          width: 1
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'] as Timestamp?;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('garments')
          .doc(widget.doc.id)
          .collection('prices')
          .snapshots(),
      builder: (context, snapshot) {
        
        final pricesDocs = snapshot.data?.docs ?? [];
        final Map<String, double> pricesMap = {};
        for(var d in pricesDocs) {
          final pData = d.data() as Map<String, dynamic>;
          pricesMap[d.id] = (pData['price'] as num?)?.toDouble() ?? 0.0;
        }

        if (_selectedOpId != null && !pricesMap.containsKey(_selectedOpId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) {
              setState(() {
                _selectedOpId = null;
                _priceCtrl.text = '';
                _checkDirty();
              });
            }
          });
        }

        // --- ROW CONTAINER "SOSPESO" ---
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // Ombra più marcata come richiesto
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06), // Un po' più scura
                blurRadius: 20, // Molto sfumata
                offset: const Offset(0, 8), // Distanza verticale
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              // 1. NOME (In Box)
              Expanded(
                flex: 4,
                child: _boxWrapper(
                  bgColor: Colors.white,
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => _checkDirty(),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. DATA (In Box Read-only)
              Expanded(
                flex: 2,
                child: _boxWrapper(
                  bgColor: Colors.grey.shade100, 
                  active: false,
                  child: Text(
                    _fmtDate(createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 3. TENDINA OPERAZIONI (In Box)
              Expanded(
                flex: 3,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: pricesMap.isEmpty 
                    ? const Center(child: Text("Nessuna op.", style: TextStyle(fontSize: 12, color: Colors.grey)))
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedOpId,
                          hint: const Text('Seleziona', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          isExpanded: true,
                          icon: const Icon(Icons.expand_more, size: 20),
                          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w700),
                          items: pricesMap.keys.map((opId) {
                            final opName = widget.opTypeMap[opId] ?? 'Op. #$opId';
                            return DropdownMenuItem(
                              value: opId,
                              child: Text(opName, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              _selectedOpId = val;
                              _originalPriceOfSelectedOp = pricesMap[val];
                              _priceCtrl.text = _fmtEuro(_originalPriceOfSelectedOp);
                              _checkDirty();
                            });
                          },
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),

              // 4. PREZZO (In Box)
              Expanded(
                flex: 2,
                child: _selectedOpId == null 
                  ? _boxWrapper( // Placeholder
                      bgColor: Colors.grey.shade100, 
                      active: false, 
                      child: const SizedBox()
                    )
                  : _boxWrapper(
                      bgColor: Colors.white,
                      child: Row(
                        children: [
                          const Text('€ ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: TextField(
                              controller: _priceCtrl,
                              onChanged: (_) => _checkDirty(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
              
              // 5. AZIONI
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tasto Modifica (VERDE)
                    IconButton(
                      onPressed: _isDirty ? _saveChanges : null,
                      icon: Icon(
                        Icons.check_circle, 
                        color: _isDirty ? Colors.green : Colors.grey.shade200, 
                        size: 28,
                      ),
                      tooltip: 'Salva',
                    ),
                    const SizedBox(width: 4),
                    // Tasto Elimina
                    IconButton(
                      onPressed: _deleteGarment,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                      ),
                      tooltip: 'Elimina',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}