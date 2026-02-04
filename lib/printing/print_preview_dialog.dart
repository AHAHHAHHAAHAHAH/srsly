import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'print_models.dart';
import 'print_service.dart';

class PrintPreviewDialog extends StatefulWidget {
  final PrintOrderData data;

  const PrintPreviewDialog({super.key, required this.data});

  static Future<bool?> open(
    BuildContext context, {
    required PrintOrderData data,
  }) {
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
        width: 900,
        height: 700,
        child: Column(
          children: [
            _header(d),
            const Divider(height: 1),
            // TAB BUTTONS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _tabButton('Copia lavanderia', 0, Icons.local_laundry_service),
                  const SizedBox(width: 10),
                  _tabButton('Copia cliente', 1, Icons.person),
                  const SizedBox(width: 10),
                  _tabButton('Bollini capi', 2, Icons.sell), 
                ],
              ),
            ),
            
            // PREVIEW AREA
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.all(16),
                child: _pdfPreviewBody(d),
              ),
            ),
            
            const Divider(height: 1),
            // FOOTER ACTIONS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.print),
                    label: const Text('Conferma stampa'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfPreviewBody(PrintOrderData d) {
    // Usiamo una chiave unica basata sul tab per forzare il refresh quando cambi tab
    return PdfPreview(
      key: ValueKey('preview_tab_$_tab'), 
      build: (format) => _buildBytesForCurrentTab(d),
      allowPrinting: false,
      allowSharing: false, 
      canChangeOrientation: false,
      canChangePageFormat: false,
      loadingWidget: const Center(child: CircularProgressIndicator()),
      padding: const EdgeInsets.all(20),
    );
  }

  Future<Uint8List> _buildBytesForCurrentTab(PrintOrderData d) async {
    // ORA CHIAMIAMO I METODI SPECIFICI PER OGNI TAB
    if (_tab == 0) {
      // Solo PDF Lavanderia (1 pagina)
      return PrintService.buildLaundryOnlyPdfBytes(d);
    } else if (_tab == 1) {
      // Solo PDF Cliente (1 pagina)
      return PrintService.buildClientOnlyPdfBytes(d);
    } else {
      // Solo PDF Bollini
      return PrintService.buildLabelsPdfBytes(d);
    }
  }

  // --- UI WIDGETS ---

  Widget _header(PrintOrderData d) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Anteprima Stampa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('Ticket #${d.ticketNumber}'),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, IconData icon) {
    final isSel = _tab == index;
    return ElevatedButton.icon(
      onPressed: () => setState(() => _tab = index),
      icon: Icon(icon, color: isSel ? Colors.white : Colors.black),
      label: Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSel ? Colors.black : Colors.white,
        elevation: isSel ? 2 : 0,
        side: isSel ? null : const BorderSide(color: Colors.grey),
      ),
    );
  }
}