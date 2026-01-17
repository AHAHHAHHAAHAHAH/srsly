import 'receipt_models.dart';
import 'receipt_formatters.dart';

class ReceiptBuilders {
  /// Copia per la lavanderia (come tua foto).
  static String buildLaundry(ReceiptModel m) {
    final buf = StringBuffer();

    buf.writeln('(copia per la lavanderia)');
    buf.writeln();
    buf.writeln(m.isPaid ? 'PAGATO' : 'DA PAGARE');
    buf.writeln(ReceiptFmt.sep());

    // Titolo smacchiatoria (verticale, centrato "a occhio")
    buf.writeln(m.company.titleLine1.toUpperCase());
    if (m.company.titleLine2.trim().isNotEmpty) {
      buf.writeln(m.company.titleLine2.toUpperCase());
    }

    buf.writeln(ReceiptFmt.sep());
    buf.writeln(m.company.ownerLine);
    buf.writeln(m.company.addressLine);
    buf.writeln(m.company.cityLine);
    buf.writeln('Tel. ${m.company.phoneLine}');
    buf.writeln(ReceiptFmt.sep());

    buf.writeln('Partita n.:     ${m.partitaNumber}');
    buf.writeln('Codice Cliente: ${m.clientCode}');
    buf.writeln();

    buf.writeln('Dati:          ${m.clientName}');
    buf.writeln('Cellulare:     ${m.clientPhone}');
    buf.writeln('Accettazione:  ${ReceiptFmt.fmtDate(m.acceptanceDate)}');
    buf.writeln('Ritiro:        ${ReceiptFmt.fmtDate(m.pickupDate)}');
    buf.writeln('N. capi:       ${m.capCount}');
    buf.writeln();

    buf.writeln(
      'Acconto € ${ReceiptFmt.fmtMoney(m.acconto)}   Totale € ${ReceiptFmt.fmtMoney(m.total)}',
    );
    buf.writeln('Rimanenza € ${ReceiptFmt.fmtMoney(m.rimanenza)}');
    buf.writeln(ReceiptFmt.sep());

    // Tabella
    buf.writeln('Q.tà  Descrizione Capo           Prezzo');
    buf.writeln(ReceiptFmt.sep());

    for (final it in m.items) {
      final qty = ReceiptFmt.padRight(it.qty.toString(), 4);
      final desc = ReceiptFmt.padRight(ReceiptFmt.truncate(it.description, 26), 26);
      final price = ReceiptFmt.padLeft(ReceiptFmt.fmtMoney(it.lineTotal), 10);
      buf.writeln('$qty$desc$price');
    }

    buf.writeln(ReceiptFmt.sep());
    buf.writeln();
    return buf.toString();
  }

  /// Copia cliente: per ora identica base + placeholder.
  /// (Nel prossimo step la rendiamo "esattamente come foto 2": box condizioni, ecc.)
  static String buildClient(ReceiptModel m) {
    final buf = StringBuffer();
    buf.writeln('(copia per il cliente)');
    buf.writeln();
    buf.writeln(m.isPaid ? 'PAGATO' : 'DA PAGARE');
    buf.writeln(ReceiptFmt.sep());
    buf.writeln(m.company.titleLine1.toUpperCase());
    if (m.company.titleLine2.trim().isNotEmpty) {
      buf.writeln(m.company.titleLine2.toUpperCase());
    }
    buf.writeln(ReceiptFmt.sep());

    buf.writeln('Partita n.:     ${m.partitaNumber}');
    buf.writeln('Codice Cliente: ${m.clientCode}');
    buf.writeln(ReceiptFmt.sep());

    buf.writeln('Cliente:        ${m.clientName}');
    buf.writeln('Cellulare:      ${m.clientPhone}');
    buf.writeln('Accettazione:   ${ReceiptFmt.fmtDate(m.acceptanceDate)}');
    buf.writeln('Ritiro:         ${ReceiptFmt.fmtDate(m.pickupDate)}');
    buf.writeln('N. capi:        ${m.capCount}');
    buf.writeln(ReceiptFmt.sep());

    // stessa tabella (se nella foto cliente non mostra prezzi, la cambiamo nel prossimo step)
    buf.writeln('Q.tà  Descrizione Capo           Prezzo');
    buf.writeln(ReceiptFmt.sep());
    for (final it in m.items) {
      final qty = ReceiptFmt.padRight(it.qty.toString(), 4);
      final desc = ReceiptFmt.padRight(ReceiptFmt.truncate(it.description, 26), 26);
      final price = ReceiptFmt.padLeft(ReceiptFmt.fmtMoney(it.lineTotal), 10);
      buf.writeln('$qty$desc$price');
    }
    buf.writeln(ReceiptFmt.sep());

    // Placeholder condizioni (poi le copiamo identiche alla foto)
    buf.writeln('CONDIZIONI:');
    buf.writeln('- ...');
    buf.writeln();
    return buf.toString();
  }

  /// Bollini: una stringa per ogni capo singolo (qty “esplosa”).
  static List<String> buildLabels(ReceiptModel m) {
    final labels = <String>[];
    for (final it in m.items) {
      for (int i = 0; i < it.qty; i++) {
        final buf = StringBuffer();
        buf.writeln('CLIENTE: ${m.clientCode}  PARTITA: ${m.partitaNumber}');
        buf.writeln('RITIRO: ${ReceiptFmt.fmtDate(it.pickupDate)}  ${it.pickupSlot}');
        buf.writeln(ReceiptFmt.sep());
        buf.writeln(ReceiptFmt.truncate(it.description, ReceiptFmt.width));
        buf.writeln(ReceiptFmt.sep());
        labels.add(buf.toString());
      }
    }
    return labels;
  }
}
