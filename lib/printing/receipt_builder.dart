import 'print_models.dart';

class ReceiptBuilder {
  // =========================
  //  CONFIGURAZIONE TABELLE
  // =========================
  static const int _w = 32; // Larghezza totale scontrino (caratteri)

  // Colonne
  static const int _qtyW = 3;
  static const int _descW = 20; // Spazio per la descrizione
  static const int _priceW = _w - (_qtyW + 1 + _descW + 1);

  // Blocchetto Acconto/Totale
  static const int _leftColW = 14;
  static const int _midGap = 2;
  static const int _rightColW = _w - _leftColW - _midGap;

  static String _rule() => '_' * _w;
  static String _dashLine() => '-' * _w;

  // =========================
  //  METODI PUBBLICI
  // =========================
  
  static String lavanderia(PrintOrderData o) {
    final status = o.isPaid ? 'PAGATO' : 'DA PAGARE';
    final remaining = _clamp0(o.total - o.deposit);

    final lines = <String>[];

    lines.add('(copia per la lavanderia)');
    lines.add(_center(status));
    lines.add('');

    lines.add(_dashLine());
    lines.add(_center(o.companyName.toUpperCase()));
    lines.add(_center('SMACCHIATORIA'));
    lines.add(_dashLine());

    lines.add(_center('di ${o.ownerFullName}'));
    lines.add(_center(o.addressStreet));
    lines.add(_center('${o.addressCap} ${o.addressCity.toUpperCase()}'));
    lines.add(_center('Telefono: ${o.ownerPhone}'));
    lines.add('');

    lines.add('Partita n. ${o.ticketNumber}');
    lines.add('Cod. Cliente: ${o.ticketNumber}');
    lines.add('');

    lines.add('Dati: ${o.clientName}');
    lines.add('Cellulare: ${o.clientPhone}');
    lines.add('Accettazione: ${_fmtDate(o.createdAt)}');
    lines.add('Ritiro: ${_fmtDate(o.pickupDate)} ${o.pickupSlot}');
    lines.add('N. capi: ${_totalQty(o)}');
    lines.add('');

    final acc = _euro(o.deposit);
    final tot = _euro(o.total);
    final rem = _euro(remaining);

    final left1 = _padRight('Acconto', 8) + _padLeft('€ $acc', _leftColW - 8);
    final right1 = _padRight('Totale €', 9) + _padLeft(tot, _rightColW - 9);

    lines.add(_padRight(left1, _leftColW) + (' ' * _midGap) + _padRight(right1, _rightColW));

    final right2 = _padRight('Rimanenza', 9) + _padLeft(rem, _rightColW - 9);
    lines.add((' ' * _leftColW) + (' ' * _midGap) + _padRight(right2, _rightColW));

    lines.add('');

    // Intestazione Tabella
    lines.add(_padRight('Q.ta', _qtyW) + ' ' + _padRight('Descrizione Capo', _descW) + ' ' + _padLeft('Prezzo', _priceW));
    lines.add(_rule());

    for (final it in o.items) {
      final op = it.operationName.trim();
      // Costruiamo la stringa completa "Camicia, stiro"
      final descName = op.isNotEmpty ? '${it.garmentName}, $op' : it.garmentName;
      final price = '€ ${_euro(it.price)}';
      
      // Usiamo la funzione "Smart" che va a capo se serve
      _addSmartRow(lines, '${it.qty}', descName, price);
      lines.add(_rule());
    }

    return lines.join('\n');
  }

  static String cliente(PrintOrderData o) {
    final status = o.isPaid ? 'PAGATO' : 'DA PAGARE';
    final remaining = _clamp0(o.total - o.deposit);

    final lines = <String>[];

    lines.add(_center(status));
    lines.add('');

    lines.add(_dashLine());
    lines.add(_center(o.companyName.toUpperCase()));
    lines.add(_center('SMACCHIATORIA'));
    lines.add(_dashLine());

    lines.add(_center('di ${o.ownerFullName}'));
    lines.add(_center(o.addressStreet));
    lines.add(_center('${o.addressCap} ${o.addressCity.toUpperCase()}'));
    lines.add(_center('Telefono: ${o.ownerPhone}'));

    lines.add(_boxedText(
      'In caso di mancato ritiro entro 30 giorni la ditta declina ogni responsabilità. '
      'inoltre la ditta non garantisce: bottoni, alamari, cerniere, spalline, '
      'applicazioni di vario genere come strass, dorature e scolorature del capo etc.',
    ));

    lines.add(_boxedText(
      'Nel caso in cui un capo venisse danneggiato la ditta è tenuta a risarcire '
      'un importo pari a 7 volte il prezzo del lavaggio.',
    ));

    lines.add('Partita n.: ${o.ticketNumber}');
    lines.add('Codice Cliente: ${o.ticketNumber}');
    lines.add('');

    lines.add('Dati: ${o.clientName}');
    lines.add('Cellulare: ${o.clientPhone}');
    lines.add('Accettazione: ${_fmtDate(o.createdAt)}');
    lines.add('Ritiro: ${_fmtDate(o.pickupDate)}');
    lines.add('N. capi: ${_totalQty(o)}');
    lines.add('');

    final acc = _euro(o.deposit);
    final tot = _euro(o.total);
    final rem = _euro(remaining);

    final left1 = _padRight('Acconto', 8) + _padLeft(acc, _leftColW - 8);
    final right1 = _padRight('Totale €', 9) + _padLeft(tot, _rightColW - 9);

    lines.add(_padRight(left1, _leftColW) + (' ' * _midGap) + _padRight(right1, _rightColW));

    final right2 = _padRight('Rimanenza', 9) + _padLeft(rem, _rightColW - 9);
    lines.add((' ' * _leftColW) + (' ' * _midGap) + _padRight(right2, _rightColW));

    lines.add('');

    // Tabella Cliente (Senza Prezzo)
    lines.add(_padRight('Q.ta', _qtyW) + ' ' + _padRight('Descrizione Capo', _descW) + ' ' + _padRight('Note', _priceW));
    lines.add(_rule());

    for (final it in o.items) {
      final op = it.operationName.trim();
      final descName = op.isNotEmpty ? '${it.garmentName}, $op' : it.garmentName;

      // Usiamo la funzione "Smart" (passiamo stringa vuota come prezzo così lascia spazio note)
      _addSmartRow(lines, '${it.qty}', descName, '');
    }

    return lines.join('\n');
  }

  // =========================
  //  HELPERS INTELLIGENTI
  // =========================
  
  // Questa funzione SPEZZA la descrizione su più righe se supera la larghezza massima
  static void _addSmartRow(List<String> lines, String qty, String desc, String rightCol) {
    // Dividiamo la descrizione in parole
    final wrappedDesc = _wrapWords(desc, _descW);

    // Riga 1: Contiene Quantità, Prima riga descrizione, Prezzo/Note
    if (wrappedDesc.isNotEmpty) {
      lines.add(
        _padRight(qty, _qtyW) + ' ' + 
        _padRight(wrappedDesc[0], _descW) + ' ' + 
        _padLeft(rightCol, _priceW)
      );
    }

    // Righe successive: Solo il resto della descrizione (indented)
    for (int i = 1; i < wrappedDesc.length; i++) {
      lines.add(
        (' ' * _qtyW) + ' ' + // Spazio vuoto sotto Qta
        _padRight(wrappedDesc[i], _descW) + ' ' +
        (' ' * _priceW)       // Spazio vuoto sotto Prezzo
      );
    }
  }

  static double _clamp0(double v) => v < 0 ? 0 : v;

  static int _totalQty(PrintOrderData o) {
    var s = 0;
    for (final it in o.items) {
      s += it.qty;
    }
    return s;
  }

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  static String _euro(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  static String _center(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    if (t.length >= _w) return t.substring(0, _w);
    final left = ((_w - t.length) / 2).floor();
    return (' ' * left) + t;
  }

  static String _padRight(String s, int w) {
    if (s.length >= w) return s.substring(0, w);
    return s + (' ' * (w - s.length));
  }

  static String _padLeft(String s, int w) {
    if (s.length >= w) return s.substring(s.length - w);
    return (' ' * (w - s.length)) + s;
  }

  static String _boxedText(String text) {
    final innerW = _w - 2;
    final top = '┌' + ('─' * innerW) + '┐';
    final bottom = '└' + ('─' * innerW) + '┘';

    final wrapped = _wrapWords(text, innerW);

    final body = wrapped.map((line) {
      final t = line.length > innerW ? line.substring(0, innerW) : line;
      return '│' + _padRight(t, innerW) + '│';
    }).toList();

    return ([top, ...body, bottom]).join('\n');
  }

  static List<String> _wrapWords(String text, int width) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return [''];

    final words = cleaned.split(' ');
    final lines = <String>[];
    var current = '';

    for (final w in words) {
      if (w.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        var start = 0;
        while (start < w.length) {
          final end = (start + width < w.length) ? start + width : w.length;
          lines.add(w.substring(start, end));
          start = end;
        }
        continue;
      }

      if (current.isEmpty) {
        current = w;
      } else if (current.length + 1 + w.length <= width) {
        current = '$current $w';
      } else {
        lines.add(current);
        current = w;
      }
    }

    if (current.isNotEmpty) lines.add(current);
    return lines;
  }
}