import 'package:flutter/material.dart';
import 'print_models.dart';
import 'receipt_builder.dart';

class PrintPreviewDialog extends StatefulWidget {
  final PrintOrderData data;

  const PrintPreviewDialog({super.key, required this.data});

  static Future<bool?> open(BuildContext context, {required PrintOrderData data}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrintPreviewDialog(data: data),
    );
  }

  @override
  State<PrintPreviewDialog> createState() => _PrintPreviewDialogState();
}

class _PrintPreviewDialogState extends State<PrintPreviewDialog> {
  int _tab = 0; // 0=lav, 1=cli, 2=bollini

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 920,
        height: 650,
        child: Column(
          children: [
            _header(d),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  _tabButton(
                    label: 'Copia lavanderia',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                    icon: Icons.local_laundry_service_outlined,
                  ),
                  const SizedBox(width: 10),
                  _tabButton(
                    label: 'Copia cliente',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(width: 10),
                  _tabButton(
                    label: 'Bollini capi',
                    selected: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                    icon: Icons.sell_outlined,
                  ),
                  const Spacer(),
                  _pill(
                    'Totale: € ${d.total.toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: _body(d),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annulla'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.print),
                    label: const Text('Conferma stampa'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(PrintOrderData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Anteprima stampa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 12),
          _pill('Ticket #${d.ticketNumber}'),
          const Spacer(),
          Text(
            '${d.clientName} · ${d.clientPhone}',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _body(PrintOrderData d) {
    if (_tab == 0) {
      final text = ReceiptBuilder.lavanderia(d);
      return _monospaceSheet(text);
    }
    if (_tab == 1) {
      final text = ReceiptBuilder.cliente(d);
      return _monospaceSheet(text);
    }

    // Bollini preview: griglia di etichette
    final labels = <String>[];
    for (final item in d.items) {
      for (int i = 0; i < item.qty; i++) {
        labels.add(
          ReceiptBuilder.bollino(
            ticket: d.ticketNumber,
            client: d.clientName,
            garment: item.garmentName,
            pickup: d.pickupDate,
            slot: d.pickupSlot,
          ),
        );
      }
    }

    if (labels.isEmpty) {
      return const Center(child: Text('Nessun bollino'));
    }

    return LayoutBuilder(
      builder: (context, c) {
        // Colonne adattive (etichette piccole)
        final w = c.maxWidth;
        final columns = w > 760 ? 4 : (w > 520 ? 3 : 2);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final s in labels)
                SizedBox(
                  width: (w - (12 * (columns - 1)) - 32) / columns,
                  child: _labelCard(s),
                ),
            ],
          ),
        );
      },
    );
  }

 Widget _monospaceSheet(String text) {
  final controller = ScrollController();

  return Padding(
    padding: const EdgeInsets.all(14),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        interactive: true, // 👈 fondamentale
        child: SingleChildScrollView(
          controller: controller, // 👈 stesso controller
          padding: const EdgeInsets.all(14),
          child: SelectableText(
            text,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 14,
              height: 1.25,
            ),
          ),
        ),
      ),
    ),
  );
}


  Widget _labelCard(String s) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          s.trim(),
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.black : Colors.black.withOpacity(0.12),
          ),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
