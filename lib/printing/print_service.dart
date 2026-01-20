import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'print_preview_dialog.dart';
import 'print_models.dart';
import 'receipt_builder.dart';
class PrintService {

  static Future<Uint8List> buildPdfBytes(PrintOrderData data) async {
    final doc = pw.Document();
    final mono = await PdfGoogleFonts.courierPrimeBoldItalic();

    // 1️⃣ Ricevuta lavanderia
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Text(
          ReceiptBuilder.lavanderia(data),
          style: pw.TextStyle(font: mono, fontSize: 10),
        ),
      ),
    );

    // 2️⃣ Ricevuta cliente
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Text(
          ReceiptBuilder.cliente(data),
          style: pw.TextStyle(font: mono, fontSize: 10),
        ),
      ),
    );

    // 3️⃣ Bollini (1 per capo)
    for (final item in data.items) {
      for (int i = 0; i < item.qty; i++) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              70 * PdfPageFormat.mm,
              45 * PdfPageFormat.mm,
            ),
            build: (_) => pw.Center(
              child: pw.Text(
                ReceiptBuilder.bollino(
                  ticket: data.ticketNumber,
                  client: data.clientName,
                  garment: item.garmentName,
                  pickup: data.pickupDate,
                  slot: data.pickupSlot,
                ),
                style: pw.TextStyle(font: mono, fontSize: 9),
              ),
            ),
          ),
        );
      }
    }

    return doc.save();
  }

  static Future<void> printAll(PrintOrderData data) async {
    await Printing.layoutPdf(
      onLayout: (_) async => buildPdfBytes(data),
    );
  }
}
