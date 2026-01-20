import 'print_models.dart';

class ReceiptBuilder {
  static String lavanderia(PrintOrderData o) {
    final status = o.isPaid ? 'PAGATO' : 'DA PAGARE';
    final double remaining = (o.total - o.deposit) < 0 ? 0 : (o.total - o.deposit);

    return '''
Lavanderia
(copia per la lavanderia)
  $status
--------------------------------
KAPPA5CRISTOLAMADONNA
--------------------------------
Partita n°: ${o.ticketNumber}
Codice cliente: ${o.ticketNumber}
--------------------------------
Dati: ${o.clientName}
Cellulare: ${o.clientPhone}
Accettazione: ${_dt(o.createdAt)}
Ritiro: ${_d(o.pickupDate)} ${o.pickupSlot}
N° capi: ${_totalQty(o)}
--------------------------------
Acconto: € ${_euro(o.deposit)}  Totale: € ${_euro(o.total)}
Rimanenza: € ${_euro(remaining)}   Stato: $status

--------------------------------
QTA  DESCRIZIONE        PREZZO
${_items(o)}
--------------------------------
''';
  }

  static String cliente(PrintOrderData o) {
    final status = o.isPaid ? 'PAGATO' : 'DA PAGARE';
    final remaining = (o.total - o.deposit) < 0 ? 0 : (o.total - o.deposit);

    return '''
Cliente
(copia per il cliente)
--------------------------------
KAPPA5CRISTOLAMADONNA
--------------------------------
Partita n°: ${o.ticketNumber}
Codice cliente: ${o.ticketNumber}
--------------------------------
Cliente: ${o.clientName}
Cell: ${o.clientPhone}
Accettazione: ${_dt(o.createdAt)}
Ritiro: ${_d(o.pickupDate)} ${o.pickupSlot}
N° capi: ${_totalQty(o)}
--------------------------------
QTA  DESCRIZIONE        PREZZO
${_items(o)}
--------------------------------
Totale               € ${_euro(o.total)}
--------------------------------
''';
  }

  static String bollino({
    required int ticket,
    required String client,
    required String garment,
    required DateTime pickup,
    required String slot,
  }) {
    return '''
CLIENTE: $client
CODICE: $ticket
CAPO: $garment
RITIRO: ${_d(pickup)} $slot
''';
  }

  // =======================
  // HELPERS TESTO
  // =======================

  static String _items(PrintOrderData o) {
    final b = StringBuffer();
    for (final i in o.items) {
      b.writeln(
          '${i.qty.toString().padRight(4)}${i.garmentName.padRight(18)}€ ${_euro(i.price * i.qty)}');
    }
    return b.toString();
  }

  static int _totalQty(PrintOrderData o) =>
      o.items.fold(0, (s, i) => s + i.qty);

  static String _euro(double v) =>
      v.toStringAsFixed(2).replaceAll('.', ',');

  static String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _dt(DateTime d) =>
      '${_d(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
