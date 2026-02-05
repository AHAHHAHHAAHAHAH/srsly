import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/client_service.dart';

class ClientTableScreen extends StatefulWidget {
  const ClientTableScreen({super.key});

  @override
  State<ClientTableScreen> createState() => _ClientTableScreenState();
}

class _ClientTableScreenState extends State<ClientTableScreen> {
  final _clientService = ClientService();

  // Filtro Alfabetico
  final List<String> _alphabet = List.generate(26, (i) => String.fromCharCode(65 + i));
  String _selectedLetter = 'A';

  // Stile Box elegante (identico a CapiTableScreen)
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
          // 1. BARRA ALFABETO + TOTALE
          // =======================
          Container(
            height: 70, // Altezza fissa
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _headerBoxDecoration(), // Usa lo stile definito nel file
            child: Row(
              children: [
                // Icona a sinistra (semplice come richiesto)
                const Icon(Icons.filter_alt, color: Colors.black87),
                const SizedBox(width: 16),
                
                // LISTA LETTERE SCORREVOLE (Stile 'Pillola')
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

                // --- NUOVO PEZZO: TOTALE CLIENTI ---
                const SizedBox(width: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _clientService.searchClients(''), // Conta tutti i clienti
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Clienti totali: $count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  },
                ),
                // -----------------------------------
              ],
            ),
          ),

          const SizedBox(height: 24),

          // =======================
          // 2. TABELLA CLIENTI
          // =======================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _clientService.searchClients(''), // Prende tutti e filtra localmente
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Errore: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                // FILTRO LOCALE
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['fullName'] ?? '').toString().toUpperCase();
                  return name.startsWith(_selectedLetter);
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER: Titolo e Contatore (Come Table Capi)
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
                            '${filteredDocs.length} CLIENTI TROVATI',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // INTESTAZIONI COLONNE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Padding per allineare con le card
                      child: Row(
                        children: const [
                          Expanded(flex: 4, child: Text('NOME E COGNOME', style: _headerStyle)),
                          SizedBox(width: 12),
                          Expanded(flex: 3, child: Text('NUMERO', style: _headerStyle)),
                          SizedBox(width: 12),
                          Expanded(flex: 2, child: Text('AGGIUNTO IL', style: _headerStyle)),
                          SizedBox(width: 12),
                          Expanded(flex: 2, child: Text('ULTIMA ATTIVITÀ', style: _headerStyle)),
                          SizedBox(width: 100), // Spazio Azioni
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // LISTA RIGHE (Card Sospese)
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off, size: 64, color: Colors.grey.shade100),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nessun cliente trovato con "$_selectedLetter"',
                                    style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              itemCount: filteredDocs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16), // Spazio tra le card
                              itemBuilder: (context, i) {
                                final doc = filteredDocs[i];
                                return _ClientRow(
                                  key: ValueKey(doc.id),
                                  doc: doc,
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
// RIGA CLIENTE (Card Sospesa - Stile Boxato)
// ==========================================
class _ClientRow extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  const _ClientRow({super.key, required this.doc});

  @override
  State<_ClientRow> createState() => _ClientRowState();
}

class _ClientRowState extends State<_ClientRow> {
  final _clientService = ClientService();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  
  late String _originalName;
  late String _originalPhone;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final data = widget.doc.data() as Map<String, dynamic>;
    _originalName = data['fullName'] ?? '';
    _originalPhone = data['number'] ?? '';
    
    _nameCtrl = TextEditingController(text: _originalName);
    _phoneCtrl = TextEditingController(text: _originalPhone);
  }

  @override
  void didUpdateWidget(covariant _ClientRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.doc.data().toString() != oldWidget.doc.data().toString()) {
       final data = widget.doc.data() as Map<String, dynamic>;
       setState(() {
         _originalName = data['fullName'] ?? '';
         _originalPhone = data['number'] ?? '';
         _isDirty = false;
       });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(Timestamp? ts) {
    if (ts == null) return '--/--/----';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  void _checkDirty() {
    final currentName = _nameCtrl.text.trim();
    final currentPhone = _phoneCtrl.text.trim();
    
    final newDirty = (currentName != _originalName) || (currentPhone != _originalPhone);
    
    if (newDirty != _isDirty) {
      setState(() => _isDirty = newDirty);
    }
  }

  Future<void> _saveChanges() async {
    if (!_isDirty) return;

    try {
      await _clientService.updateClient(
        clientId: widget.doc.id,
        fullName: _nameCtrl.text,
        number: _phoneCtrl.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifiche salvate!'), backgroundColor: Colors.green, duration: Duration(milliseconds: 800)),
        );
      }
      
      setState(() {
        _isDirty = false;
        _originalName = _nameCtrl.text.trim();
        _originalPhone = _phoneCtrl.text.trim();
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteClient() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare Cliente?'),
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
      await _clientService.deleteClient(widget.doc.id);
    }
  }

  // Helper per i Box (Stile Capi Table)
  Widget _boxWrapper({required Widget child, bool active = true, Color? bgColor}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
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
    final lastActivity = data['lastActivityAt'] as Timestamp?;

    // Card Sospesa con Ombra
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // 1. NOME (Box Bianco)
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

          // 2. NUMERO (Box Bianco)
          Expanded(
            flex: 3,
            child: _boxWrapper(
              bgColor: Colors.white,
              child: TextField(
                controller: _phoneCtrl,
                onChanged: (_) => _checkDirty(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 3. AGGIUNTO IL (Box Grigio)
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

          // 4. ULTIMA ATTIVITÀ (Box Grigio)
          Expanded(
            flex: 2,
            child: _boxWrapper(
              bgColor: Colors.grey.shade100, 
              active: false,
              child: Text(
                _fmtDate(lastActivity),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
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
                    color: _isDirty ? Colors.green : Colors.grey.shade200, 
                    size: 28,
                  ),
                  tooltip: 'Salva modifiche',
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _deleteClient,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                  ),
                  tooltip: 'Elimina cliente',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}