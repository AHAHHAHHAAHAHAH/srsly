import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/client_service.dart';

class OrdersScreen extends StatefulWidget {
  final String? clientId;
  const OrdersScreen({super.key, required this.clientId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderService = OrderService();
  final _clientService = ClientService();

  // Stato Filtro
  String _activeFilter = 'Tutti';

  // Dati cliente
  String _clientName = 'Caricamento...';
  String _clientPhone = '';

  @override
  void initState() {
    super.initState();
    _loadClientInfo();
  }

  Future<void> _loadClientInfo() async {
    if (widget.clientId == null) return;
    try {
      final snap = await _clientService.getClientById(widget.clientId!);
      final data = snap.data();
      if (data != null && mounted) {
        setState(() {
          _clientName = data['fullName'] ?? 'Cliente';
          _clientPhone = data['number'] ?? '';
        });
      }
    } catch (_) {}
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy · $hh:$min';
  }

  // Logica Filtro
  bool _applyFilter(Map<String, dynamic> data) {
    final isPaid = data['isPaid'] == true;
    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
    final ts = data['createdAt'] as Timestamp?;
    final date = ts?.toDate() ?? DateTime.now();
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    switch (_activeFilter) {
      case 'Pagati':
        return isPaid;
      case 'Da Pagare':
        return !isPaid;
      case 'Ultimi 7 gg':
        return diff <= 7;
      case 'Ultimi 14 gg':
        return diff <= 14;
      case 'Ultimi 30 gg':
        return diff <= 30;
      case 'Ultimi 3 Mesi':
        return diff <= 90;
      case '<= 50 €':
        return total <= 50;
      case '>= 50 €':
        return total >= 50;
      default:
        return true; // Tutti
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

  void _openDetailDialog(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => OrderDetailDialog(
        data: orderData, 
        clientName: _clientName,
        fmtDate: _fmtDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clientId == null) {
      return const Center(child: Text('Nessun cliente selezionato'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==============================
          // 1. DASHBOARD HEADER
          // ==============================
          StreamBuilder<QuerySnapshot>(
            stream: _orderService.getOrdersByClient(widget.clientId!),
            builder: (context, snapshot) {
              final allDocs = snapshot.data?.docs ?? [];
              final totalOrders = allDocs.length;

              final filteredDocs = allDocs.where((d) {
                return _applyFilter(d.data() as Map<String, dynamic>);
              }).toList();

              final filteredCount = filteredDocs.length;

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: _boxDecoration(),
                child: Column(
                  children: [
                    // TOP ROW: Titolo + Filtro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INFO CLIENTE
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STORICO ORDINI DI:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_clientName $_clientPhone',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // BOTTONE FILTRO
                        PopupMenuButton<String>(
                          onSelected: (val) => setState(() => _activeFilter = val),
                          offset: const Offset(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            _menuItem('Tutti', isHeader: true),
                            _menuItem('Pagati'),
                            _menuItem('Da Pagare'),
                            const PopupMenuDivider(),
                            _menuItem('Ultimi 7 gg'),
                            _menuItem('Ultimi 14 gg'),
                            _menuItem('Ultimi 30 gg'),
                            _menuItem('Ultimi 3 Mesi'),
                            const PopupMenuDivider(),
                            _menuItem('<= 50 €'),
                            _menuItem('>= 50 €'),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.filter_list, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _activeFilter == 'Tutti' ? 'FILTRO' : _activeFilter.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // STATISTICHE
                    Row(
                      children: [
                        _StatItem(
                          label: 'Totale Ordini',
                          value: '$totalOrders',
                        ),
                        const SizedBox(width: 40),
                        _StatItem(
                          label: 'Ordini Filtrati',
                          value: '$filteredCount',
                          highlight: true,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ==============================
          // 2. LISTA ORDINI
          // ==============================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _orderService.getOrdersByClient(widget.clientId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Errore: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final allDocs = snapshot.data?.docs ?? [];
                
                // Filtro Lista
                final filteredDocs = allDocs.where((d) {
                  return _applyFilter(d.data() as Map<String, dynamic>);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun ordine corrisponde ai filtri.',
                          style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    return InkWell(
                      onTap: () => _openDetailDialog(data),
                      borderRadius: BorderRadius.circular(16),
                      child: _OrderCard(data: data, fmtDate: _fmtDate),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, {bool isHeader = false}) {
    final isSelected = _activeFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: isSelected ? Colors.black : Colors.grey.shade400,
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// WIDGETS GRAFICI
// =======================

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatItem({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: highlight ? Colors.black : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(DateTime) fmtDate;

  const _OrderCard({required this.data, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    final ticket = data['ticketNumber']?.toString() ?? '---';
    final totalVal = (data['total'] as num?)?.toDouble() ?? 0.0;
    final totalStr = totalVal.toStringAsFixed(2).replaceAll('.', ',');
    final isPaid = data['isPaid'] == true;
    final items = (data['items'] as List?) ?? [];
    final itemCount = items.length;
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null ? fmtDate(ts.toDate()) : '---';

    final statusColor = isPaid ? const Color(0xFF00C853) : const Color(0xFFD32F2F);
    final statusText = isPaid ? 'PAGATO' : 'DA PAGARE';

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 6,
              height: double.infinity,
              color: statusColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('TICKET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                          Text(
                            '#$ticket',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$itemCount ${itemCount == 1 ? 'Capo' : 'Capi'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '€ $totalStr',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================
// DETTAGLIO ORDINE DIALOG
// =======================

class OrderDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String clientName;
  final String Function(DateTime) fmtDate;

  const OrderDetailDialog({
    super.key,
    required this.data,
    required this.clientName,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    final ticket = data['ticketNumber']?.toString() ?? '---';
    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
    final deposit = (data['deposit'] as num?)?.toDouble() ?? 0.0;
    final remaining = (total - deposit) < 0 ? 0.0 : (total - deposit);
    final isPaid = data['isPaid'] == true;
    final items = (data['items'] as List?) ?? [];
    
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null ? fmtDate(ts.toDate()) : '---';

    final statusColor = isPaid ? const Color(0xFF00C853) : const Color(0xFFD32F2F);
    final statusText = isPaid ? 'PAGATO' : 'DA PAGARE';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TICKET #$ticket', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // INFO CLIENTE
            Text('CLIENTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),

            const SizedBox(height: 24),

            // LISTA CAPI
            Text('CAPI IN ORDINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1)),
            const SizedBox(height: 12),
            
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final name = item['garmentName'] ?? '';
                    final op = item['operationTypeName'] ?? '';
                    final qty = item['qty'] ?? 1;
                    final price = (item['lineTotal'] as num?)?.toDouble() ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                if (op.isNotEmpty)
                                  Text(op, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                              ],
                            ),
                          ),
                          Text(
                            '€ ${price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- FOOTER RIVISTO: Totale a SX (con acconto), Rimanenza a DX ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // SX: Totale e Acconto
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTALE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1)),
                    Text(
                      '€${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, height: 1.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acconto: €${deposit.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ],
                ),
                
                // DX: Rimanenza
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('RIMANENZA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      '€${remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.w900, 
                        color: remaining > 0 ? Colors.red : Colors.green,
                        height: 1.0
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('CHIUDI SCHEDA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}