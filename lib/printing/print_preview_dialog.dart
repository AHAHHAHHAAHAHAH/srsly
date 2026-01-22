import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'print_models.dart';
import 'receipt_builder.dart';

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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Totale: € ${_euro(d.total)}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Acconto: € ${_euro(_safeDeposit(d))}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rimanenza: € ${_euro(_remaining(d))}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
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
                  child: _pdfBody(d),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
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

  // =========================
  // PDF PREVIEW (render vero)
  // =========================
  Widget _pdfBody(PrintOrderData d) {
    return PdfPreview(
      build: (format) => _buildPdfBytesForTab(d, _tab),
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      pdfFileName: 'scontrino_${d.ticketNumber}.pdf',
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }

  Future<Uint8List> _buildPdfBytesForTab(PrintOrderData d, int tab) async {
    final doc = pw.Document();

    // font monospace stabile
final mono = await PdfGoogleFonts.jetBrainsMonoRegular();

    if (tab == 0 || tab == 1) {
      final text = (tab == 0) ? ReceiptBuilder.lavanderia(d) : ReceiptBuilder.cliente(d);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
          build: (_) {
            return pw.Align(
              alignment: pw.Alignment.topCenter,
              child: pw.Container(
                width: 360, // “scontrino” stretto al centro
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    font: mono,
                    fontSize: 11.5,
                    height: 1.18,
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // BOLLINI: generiamo una pagina con griglia
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
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (_) => pw.Center(
              child: pw.Text(
                'Nessun bollino',
                style: pw.TextStyle(font: mono, fontSize: 14),
              ),
            ),
          ),
        );
      } else {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (_) {
              // 4 colonne tipo etichette
              const cols = 4;
              return pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final s in labels)
                    pw.Container(
                      width: (PdfPageFormat.a4.availableWidth - (10 * (cols - 1))) / cols,
                      height: 95,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1, color: PdfColors.grey700),
                        borderRadius: pw.BorderRadius.circular(6),
                        color: PdfColors.white,
                      ),
                      child: pw.Text(
                        s.trim(),
                        style: pw.TextStyle(
                          font: mono,
                          fontSize: 9.6,
                          height: 1.12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }
    }

    return doc.save();
  }

  // =========================
  // Helpers UI
  // =========================
  String _euro(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  double _safeDeposit(PrintOrderData d) {
    final dep = d.deposit;
    if (dep.isNaN || dep.isInfinite || dep < 0) return 0.0;
    if (dep > d.total) return d.total; // clamp al totale
    return dep;
  }

  double _remaining(PrintOrderData d) {
    final r = d.total - _safeDeposit(d);
    return r < 0 ? 0.0 : r;
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
