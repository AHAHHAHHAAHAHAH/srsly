import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' show PdfGoogleFonts;

import 'print_models.dart';
import 'receipt_builder.dart';

class PrintService {
  // =========================
  //  CONFIGURAZIONE MISURE (CALIBRATE SU EPSON TM-U220)
  // =========================
  static const double _receiptWidthMm = 75.0;
  
  // MARGINI (Confermati ok):
  static const double _padLeftMm = 9.0; 
  static const double _padTopMm = 0.0; 
  static const double _padRightMm = 3.0; 
  static const double _padBottomMm = 0.0;

  // Font Ricevuta
  static const double _fontSizeReceipt = 8.0;
  static const double _lineHeightReceipt = 1.15;

  // BOLLINO
  static const double _labelWidthMm = 75.0;
  static const double _labelHeightMm = 50.0; 
  static const double _fontSizeLabel = 8.0; 

  // =========================
  // Helpers
  // =========================
  static double _mm(double v) => v * PdfPageFormat.mm;

  static int _countLines(String s) => s.isEmpty ? 0 : ('\n'.allMatches(s).length + 1);

  static double _estimateHeightPts({
    required int lines,
    required double fontSize,
    required double lineHeight,
    int extraLines = 15, 
    double extraPts = 100,
  }) {
    final textH = lines * fontSize * lineHeight;
    final buffer = (extraLines * fontSize * lineHeight) + extraPts;
    return textH + buffer;
  }

  static pw.EdgeInsets _printPadding() => pw.EdgeInsets.fromLTRB(
    _mm(_padLeftMm), 
    _mm(_padTopMm), 
    _mm(_padRightMm), 
    _mm(_padBottomMm)
  );

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString().substring(2); 
    return '$dd/$mm/$yyyy';
  }

  // Helper per unire Capo e Operazione senza maiuscolo forzato
  static String _formatItemName(PrintOrderItem item) {
    // Esempio output: "Camicia nera, Solo stiro"
    // NOTA: Se l'operazione è vuota o null, stampa solo il capo
    final op = item.operationName.trim();
    if (op.isEmpty) return item.garmentName;
    return '${item.garmentName}, $op';
  }

  // =========================
  //  ENTRYPOINT
  // =========================
  static Future<void> printAllSmart(PrintOrderData data) async {
    final ok = await printAllKiosk(data);
    if (ok) return;

    final bytes = await buildAllInOnePdfBytes(data);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Scontrino_${data.ticketNumber}',
    );
  }

  // =========================
  //  GENERATORI PDF
  // =========================
  static Future<Uint8List> buildLaundryOnlyPdfBytes(PrintOrderData data) async {
    final doc = pw.Document();
    final mono = await PdfGoogleFonts.jetBrainsMonoRegular();
    _addReceiptPage(doc: doc, mono: mono, data: data, isClientCopy: false);
    return doc.save();
  }

  static Future<Uint8List> buildClientOnlyPdfBytes(PrintOrderData data) async {
    final doc = pw.Document();
    final mono = await PdfGoogleFonts.jetBrainsMonoRegular();
    _addReceiptPage(doc: doc, mono: mono, data: data, isClientCopy: true);
    return doc.save();
  }

  static Future<Uint8List> buildLabelsPdfBytes(PrintOrderData data) async {
    final doc = pw.Document();
    final mono = await PdfGoogleFonts.jetBrainsMonoRegular();
    final monoBold = await PdfGoogleFonts.jetBrainsMonoBold();
    for (final item in data.items) {
      for (int i = 0; i < item.qty; i++) {
        _addSingleLabelPage(doc: doc, mono: mono, monoBold: monoBold, data: data, item: item);
      }
    }
    return doc.save();
  }

  static Future<Uint8List> buildSingleLabelItemPdfBytes(PrintOrderData data, PrintOrderItem item) async {
    final doc = pw.Document();
    final mono = await PdfGoogleFonts.jetBrainsMonoRegular();
    final monoBold = await PdfGoogleFonts.jetBrainsMonoBold();
    _addSingleLabelPage(doc: doc, mono: mono, monoBold: monoBold, data: data, item: item);
    return doc.save();
  }

  static Future<Uint8List> buildAllInOnePdfBytes(PrintOrderData data) async {
    final doc = pw.Document();
    final mono = await PdfGoogleFonts.jetBrainsMonoRegular();
    final monoBold = await PdfGoogleFonts.jetBrainsMonoBold();
    
    _addReceiptPage(doc: doc, mono: mono, data: data, isClientCopy: false);
    _addReceiptPage(doc: doc, mono: mono, data: data, isClientCopy: true);
    
    for (final item in data.items) {
      for (int i = 0; i < item.qty; i++) {
        _addSingleLabelPage(doc: doc, mono: mono, monoBold: monoBold, data: data, item: item);
      }
    }
    return doc.save();
  }

  // =========================
  //  DISEGNO PAGINE
  // =========================
  
  // Modificato per accettare data invece di text string, così possiamo formattare i capi qui
  static void _addReceiptPage({
    required pw.Document doc,
    required pw.Font mono,
    required PrintOrderData data,
    required bool isClientCopy,
  }) {
    // Recuperiamo il testo base (intestazioni) dal builder, MA SENZA LA TABELLA OGGETTI
    // Nota: Per fare questo velocemente senza toccare receipt_builder, usiamo la funzione normale
    // ma la "puliamo" o meglio: RIGENERIAMO LA LISTA CAPI QUI CON LA NUOVA FORMATTAZIONE.
    
    // Per semplicità e sicurezza, usiamo il testo generato da ReceiptBuilder 
    // MA dobbiamo assicurarci che ReceiptBuilder NON faccia toUpperCase sugli items.
    // SE NON POSSIAMO MODIFICARE RECEIPT_BUILDER ORA, DOBBIAMO SOSTITUIRE IL TESTO AL VOLO.
    // OPPURE (Meglio): Usiamo ReceiptBuilder normalmente e ci fidiamo che tu abbia tolto toUpperCase di là, 
    // oppure facciamo un replace se ReceiptBuilder li fa maiuscoli.
    
    // SOLUZIONE PULITA: Chiamiamo ReceiptBuilder passando i dati.
    // Se ReceiptBuilder mette tutto maiuscolo, lo correggeremo nel ReceiptBuilder.
    // MA VISTO CHE HAI CHIESTO DI MODIFICARE SOLO QUI:
    // Ti consiglio di andare in ReceiptBuilder e togliere .toUpperCase() alla riga 80 e 152.
    // Se non puoi, dimmelo. Assumo che ReceiptBuilder stampi quello che gli passi.
    
    String text = isClientCopy ? ReceiptBuilder.cliente(data) : ReceiptBuilder.lavanderia(data);
    
    // Se ReceiptBuilder usa toUpperCase(), questo codice qui sotto NON può farci nulla se riceve già la stringa fatta.
    // QUINDI: DEVI ANDARE IN `receipt_builder.dart` E TOGLIERE `.toUpperCase()` dove stampa il nome del capo.
    // Esempio: invece di `it.garmentName.toUpperCase()`, metti `it.garmentName + ', ' + it.operationName`.
    
    final h = _estimateHeightPts(
      lines: _countLines(text),
      fontSize: _fontSizeReceipt,
      lineHeight: _lineHeightReceipt,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_mm(_receiptWidthMm), h, marginAll: 0),
        build: (_) => pw.Padding(
          padding: _printPadding(),
          child: pw.Text(
            text,
            softWrap: false,
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

  // --- DISEGNO BOLLINO AGGIORNATO (FONT PIU PICCOLO + OPERAZIONE) ---
  static void _addSingleLabelPage({
    required pw.Document doc,
    required pw.Font mono,
    required pw.Font monoBold,
    required PrintOrderData data,
    required PrintOrderItem item,
  }) {
    final style = pw.TextStyle(font: mono, fontSize: _fontSizeLabel);
    final styleBold = pw.TextStyle(font: monoBold, fontSize: _fontSizeLabel);
    // RIDOTTO FONT CAPO A 8.5 PER FAR ENTRARE "CAPO + OPERAZIONE"
    final styleGarment = pw.TextStyle(font: monoBold, fontSize: 8.5); 

    final labelPadding = pw.EdgeInsets.fromLTRB(_mm(_padLeftMm), _mm(1), _mm(_padRightMm), _mm(0));

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_mm(_labelWidthMm), _mm(_labelHeightMm), marginAll: 0),
        build: (context) {
          return pw.Padding(
            padding: labelPadding,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.max,
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, 
              children: [
                
                // RIGA 1: Codice e Partita
                pw.Row(
                  children: [
                    pw.Text('Cod: ${data.ticketNumber}', style: style),
                    pw.SizedBox(width: _mm(8)), 
                    pw.Text('Partita: ${data.ticketNumber}', style: styleBold),
                  ],
                ),
                
                // RIGA 2: Dati Cliente
                pw.Row(
                  children: [
                      pw.Text('Dati: ', style: style),
                      pw.Expanded(
                        child: pw.Text('${data.clientName}', style: styleBold, maxLines: 1, overflow: pw.TextOverflow.clip),
                      )
                  ]
                ),
                
                // RIGA 3: Accettazione e Ritiro
                pw.Row(
                  children: [
                    pw.Text('Acc: ${_fmtDate(data.createdAt)}', style: style),
                    pw.SizedBox(width: _mm(5)), 
                    pw.Text('Rit: ${_fmtDate(data.pickupDate)}', style: styleBold),
                  ],
                ),
                
                // RIGA 4: Headers
                pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text('Descrizione', style: style)),
                    pw.Expanded(flex: 1, child: pw.Text('Note', style: style)),
                  ],
                ),
                
                pw.Divider(thickness: 0.5, color: PdfColors.grey800, height: 2),
                
                // RIGA 5: CAPO + OPERAZIONE
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        _formatItemName(item), // Qui stampa "Camicia, stiro" (no uppercase)
                        style: styleGarment, 
                        maxLines: 2
                      ),
                    ),
                    pw.Expanded(flex: 1, child: pw.Container()),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================
  //  4) KIOSK MODE
  // =========================
  static Future<bool> printAllKiosk(PrintOrderData data) async {
    final printers = await Printing.listPrinters();
    if (printers.isEmpty) return false;

    final target = printers.cast<Printer?>().firstWhere(
          (p) => p != null && (p.name ?? '').toUpperCase().contains('TM-U220'),
          orElse: () => null,
        );

    if (target == null) return false;

    await Printing.directPrintPdf(
      printer: target,
      name: 'Lavanderia_${data.ticketNumber}',
      forceCustomPrintPaper: true,
      onLayout: (_) async => buildLaundryOnlyPdfBytes(data),
    );

    await Printing.directPrintPdf(
      printer: target,
      name: 'Cliente_${data.ticketNumber}',
      forceCustomPrintPaper: true,
      onLayout: (_) async => buildClientOnlyPdfBytes(data),
    );

    for (final item in data.items) {
      for (int i = 0; i < item.qty; i++) {
        await Printing.directPrintPdf(
          printer: target,
          name: 'Bollino_${item.garmentName}_$i',
          forceCustomPrintPaper: true,
          onLayout: (_) async => buildSingleLabelItemPdfBytes(data, item),
        );
      }
    }

    return true;
  }
}