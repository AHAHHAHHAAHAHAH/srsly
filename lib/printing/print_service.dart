import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' show PdfGoogleFonts;

import 'print_models.dart';
import 'receipt_builder.dart';

class PrintService {
  // =========================
  //  FORMATI REALI (TERMICA)
  // =========================
  // Tipico rotolo: 80mm (se è 58mm cambia qui).
  static const double _receiptWidthMm = 75.0;

  // Margini termica (mm)
  static const double _padLeftMm = 6.0;
  static const double _padRightMm = 3.0;
  static const double _padTopMm = 3.0;
  static const double _padBottomMm = 3.0;

  // Font ricevute
  static const double _fontSizeReceipt = 10.0;
  static const double _lineHeightReceipt = 1.18;

  // Bollini
  static const double _fontSizeLabel = 9.0;
  static const double _lineHeightLabel = 1.10;

  // Bollino: 70x45mm (requisito)
  static const double _labelWidthMm = 75.0;
  static const double _labelHeightMm = 45.0;

  // =========================
  // Helpers
  // =========================
  static double _mm(double v) => v * PdfPageFormat.mm;

  static int _countLines(String s) =>
      s.isEmpty ? 0 : ('\n'.allMatches(s).length + 1);

  /// Stima robusta dell'altezza pagina (in points) per testo monospace.
  /// NB: aggiungiamo buffer extra per evitare tagli (font metrics / rounding).
  static double _estimateHeightPts({
    required int lines,
    required double fontSize,
    required double lineHeight,
    int extraLines = 10, // buffer a righe (più sicuro)
    double extraPts = 60, // aria extra (anti-taglio)
  }) {
    final textH = lines * fontSize * lineHeight;
    final buffer = (extraLines * fontSize * lineHeight) + extraPts;
    return textH + buffer;
  }

  static pw.EdgeInsets _receiptPadding() => pw.EdgeInsets.fromLTRB(
        _mm(_padLeftMm),
        _mm(_padTopMm),
        _mm(_padRightMm),
        _mm(_padBottomMm),
      );

  // =========================
  //  ENTRYPOINT: "UNA BOTTA"
  // =========================
  /// Prova kiosk (no dialog). Se non possibile, apre il dialog OS (dev/test)
  /// MA in un solo colpo (1 PDF unico: ricevute + bollini).
  static Future<void> printAllSmart(PrintOrderData data) async {
    // 1) Provo KIOSK (0 dialog)
    final ok = await printAllKiosk(data);
    if (ok) return;

    // 2) FALLBACK: 1 SOLO DIALOG, 1 SOLO PDF (ricevute + bollini)
    final bytes = await buildAllInOnePdfBytes(data);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Scontrino_${data.ticketNumber}',
    );
  }

  // =========================
  //  1) PDF RICEVUTE (2 pagine)
  // =========================
  static Future<Uint8List> buildReceiptsPdfBytes(PrintOrderData data) async {
    final doc = pw.Document();

    // Monospace NON italic: box dritti
    final mono = await PdfGoogleFonts.notoSansMonoRegular();

    _addReceiptPage(
      doc: doc,
      mono: mono,
      text: ReceiptBuilder.lavanderia(data),
    );

    _addReceiptPage(
      doc: doc,
      mono: mono,
      text: ReceiptBuilder.cliente(data),
    );

    return doc.save();
  }

  static void _addReceiptPage({
    required pw.Document doc,
    required pw.Font mono,
    required String text,
  }) {
    final h = _estimateHeightPts(
      lines: _countLines(text),
      fontSize: _fontSizeReceipt,
      lineHeight: _lineHeightReceipt,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_mm(_receiptWidthMm), h, marginAll: 0),
        build: (_) => pw.Padding(
          padding: _receiptPadding(),
          child: pw.Text(
            text,
            softWrap: false, // IMPORTANT: niente wrap fantasma
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
              font: mono,
              fontSize: _fontSizeReceipt,
              height: _lineHeightReceipt,
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  //  2) PDF BOLLINI (N pagine)
  // =========================
  static Future<Uint8List> buildLabelsPdfBytes(PrintOrderData data) async {
    final doc = pw.Document();
    final mono = await PdfGoogleFonts.notoSansMonoRegular();

    _addAllLabelPages(doc: doc, mono: mono, data: data);

    return doc.save();
  }

  static void _addAllLabelPages({
    required pw.Document doc,
    required pw.Font mono,
    required PrintOrderData data,
  }) {
    for (final item in data.items) {
      for (int i = 0; i < item.qty; i++) {
        final labelText = ReceiptBuilder.bollino(
          ticket: data.ticketNumber,
          client: data.clientName,
          garment: item.garmentName,
          pickup: data.pickupDate,
          slot: data.pickupSlot,
        );

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              _mm(_labelWidthMm),
              _mm(_labelHeightMm),
              marginAll: 0,
            ),
            build: (_) => pw.Padding(
              padding: pw.EdgeInsets.all(_mm(3)),
              child: pw.Text(
                labelText,
                softWrap: false,
                textAlign: pw.TextAlign.left,
                style: pw.TextStyle(
                  font: mono,
                  fontSize: _fontSizeLabel,
                  height: _lineHeightLabel,
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  // =========================
  //  3) PDF UNICO (ricevute + bollini)
  // =========================
  /// Questo è quello che ti serve per avere **1 SOLO dialog** nel fallback.
  static Future<Uint8List> buildAllInOnePdfBytes(PrintOrderData data) async {
    final doc = pw.Document();
    final mono = await PdfGoogleFonts.notoSansMonoRegular();

    // 1) ricevuta lavanderia
    _addReceiptPage(
      doc: doc,
      mono: mono,
      text: ReceiptBuilder.lavanderia(data),
    );

    // 2) ricevuta cliente
    _addReceiptPage(
      doc: doc,
      mono: mono,
      text: ReceiptBuilder.cliente(data),
    );

    // 3) bollini (N pagine)
    _addAllLabelPages(doc: doc, mono: mono, data: data);

    return doc.save();
  }

  // =========================
  //  4) STAMPA KIOSK (NO DIALOG)
  // =========================
  /// Prova a stampare direttamente su TM-U220.
  /// - Se trova TM-U220: stampa ricevute + bollini senza dialog.
  /// - Se NON trova TM-U220: ritorna false (così vai nel fallback con dialog).
  static Future<bool> printAllKiosk(PrintOrderData data) async {
    final printers = await Printing.listPrinters();
    if (printers.isEmpty) return false;

    // cerco SOLO TM-U220, niente fallback su "prima stampante"
    final target = printers.cast<Printer?>().firstWhere(
          (p) =>
              p != null &&
              (p.name ?? '').toUpperCase().contains('TM-U220'),
          orElse: () => null,
        );

    if (target == null) {
      // Se non c'è la stampante vera, NON stampo su OneNote/PDF virtuali
      return false;
    }

    // (A) Ricevute (2 pagine, 80mm)
    final ok1 = await Printing.directPrintPdf(
      printer: target,
      name: 'Ricevute_${data.ticketNumber}',
      forceCustomPrintPaper: true,
      onLayout: (_) async => buildReceiptsPdfBytes(data),
    );
    if (!ok1) return false;

    // (B) Bollini (N pagine, 70x45)
    final ok2 = await Printing.directPrintPdf(
      printer: target,
      name: 'Bollini_${data.ticketNumber}',
      forceCustomPrintPaper: true,
      onLayout: (_) async => buildLabelsPdfBytes(data),
    );

    return ok2;
  }

  // =========================
  //  (OPZ) STAMPA CON DUE DIALOG
  // =========================
  /// Non usarlo nel flusso principale: è solo un tool “dev”.
  static Future<void> printWithDialogTwoSteps(PrintOrderData data) async {
    await Printing.layoutPdf(
      name: 'Ricevute_${data.ticketNumber}',
      onLayout: (_) async => buildReceiptsPdfBytes(data),
    );

    await Printing.layoutPdf(
      name: 'Bollini_${data.ticketNumber}',
      onLayout: (_) async => buildLabelsPdfBytes(data),
    );
  }
}
