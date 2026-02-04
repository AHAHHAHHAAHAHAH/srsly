import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/garment_service.dart';
import '../services/operation_type_service.dart';

class CapiTableScreen extends StatefulWidget {
  final String? clientId;
  const CapiTableScreen({super.key, required this.clientId});

  @override
  State<CapiTableScreen> createState() => _CapiTableScreenState();
}

class _CapiTableScreenState extends State<CapiTableScreen> {
  final _garmentService = GarmentService();
  final _typeService = OperationTypeService();

  // Mappa ID -> Nome Operazione (es. "op123" -> "Stiro")
  // Serve per decodificare gli ID salvati nella sottocollezione prezzi
  Map<String, String> _opTypeMap = {};
  bool _isLoadingTypes = true;

  // Filtro Alfabetico
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =======================
          // 1. BARRA ALFABETO
          // =======================
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _boxDecoration(),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.black87),
                const SizedBox(width: 16),
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // =======================
          // 2. TABELLA CAPI
          // =======================
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: _boxDecoration(),
              child: _isLoadingTypes
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      stream: _garmentService.searchGarments(''), 
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text('Errore: ${snapshot.error}'));
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final allDocs = snapshot.data?.docs ?? [];
                        
                        // FILTRO LOCALE PER LETTERA
                        final filteredDocs = allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? '').toString().toUpperCase();
                          return name.startsWith(_selectedLetter);
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Tabella
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
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Intestazioni Colonne
                            Row(
                              children: const [
                                Expanded(flex: 3, child: Text('NOME CAPO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text('DATA AGGIUNTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 3, child: Text('OPERAZIONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text('PREZZO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 100), // Spazio per bottoni azioni
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Lista Righe
                            Expanded(
                              child: filteredDocs.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nessun capo inizia per "$_selectedLetter"',
                                        style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: filteredDocs.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
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
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET RIGA SINGOLA (CON ACCESSO AI PREZZI VERI)
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
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  
  late String _originalName;
  
  // Variabili di stato per la gestione modifiche
  String? _selectedOpId; 
  double? _originalPriceOfSelectedOp; // Il prezzo nel DB per l'op selezionata
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

      // 1. Aggiorna nome capo se cambiato
      if (newName != _originalName) {
        final docRef = FirebaseFirestore.instance.collection('garments').doc(widget.doc.id);
        batch.update(docRef, {
          'name': newName,
          'nameLowerCase': newName.toLowerCase(), // Importante per la ricerca!
        });
      }

      // 2. Aggiorna prezzo se cambiato (e se op selezionata)
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifiche salvate!'), backgroundColor: Colors.green, duration: Duration(milliseconds: 800)),
      );

      // Aggiorniamo lo stato locale
      setState(() {
        _originalName = newName;
        if (_selectedOpId != null) {
          _originalPriceOfSelectedOp = _parseEuro(_priceCtrl.text);
        }
        _isDirty = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteGarment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare Capo?'),
        content: Text('Sei sicuro di voler eliminare "$_originalName"?\nQuesta azione eliminerà anche tutte le operazioni associate.'),
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

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'] as Timestamp?;

    // QUI STA LA MAGIA: Ascoltiamo la sottocollezione "prices" per questo capo
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('garments')
          .doc(widget.doc.id)
          .collection('prices')
          .snapshots(),
      builder: (context, snapshot) {
        
        // Elenco operazioni disponibili (ID e Prezzo)
        final pricesDocs = snapshot.data?.docs ?? [];
        
        // Mappa locale ID -> Prezzo per facilità
        final Map<String, double> pricesMap = {};
        for(var d in pricesDocs) {
          final pData = d.data() as Map<String, dynamic>;
          pricesMap[d.id] = (pData['price'] as num?)?.toDouble() ?? 0.0;
        }

        // Se l'operazione selezionata non esiste più (es. cancellata altrove), resetta
        if (_selectedOpId != null && !pricesMap.containsKey(_selectedOpId)) {
          // Usiamo addPostFrameCallback per evitare setState durante build
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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // 1. NOME (Sempre modificabile)
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => _checkDirty(),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),

              // 2. DATA
              Expanded(
                flex: 2,
                child: Text(
                  _fmtDate(createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),

              // 3. TENDINA OPERAZIONI (Popolata dalla sottocollezione)
              Expanded(
                flex: 3,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: pricesMap.isEmpty 
                    ? const Center(child: Text("Nessuna op.", style: TextStyle(fontSize: 12, color: Colors.grey)))
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedOpId,
                          hint: const Text('Seleziona...', style: TextStyle(fontSize: 13)),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                          items: pricesMap.keys.map((opId) {
                            final opName = widget.opTypeMap[opId] ?? 'Op. cancellata';
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

              // 4. PREZZO (Visibile SOLO se selezionato)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _selectedOpId == null 
                    ? const SizedBox() // Invisibile se non selezionato
                    : Row(
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
                    IconButton(
                      onPressed: _isDirty ? _saveChanges : null,
                      icon: Icon(
                        Icons.check_circle, 
                        color: _isDirty ? Colors.black : Colors.grey.shade200
                      ),
                      tooltip: 'Salva modifiche',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _deleteGarment,
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      ),
                      tooltip: 'Elimina capo',
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