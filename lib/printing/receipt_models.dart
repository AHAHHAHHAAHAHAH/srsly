class ReceiptItem {
  final int qty;

  /// Scelta A: "Capo — Tipo"
  final String description;

  /// Totale riga (unitPrice * qty)
  final double lineTotal;

  /// Opzionale ma utile per debug/stampa futura
  final double unitPrice;

  /// Per bollini (date/slot possono essere diversi per riga)
  final DateTime pickupDate;
  final String pickupSlot;

  ReceiptItem({
    required this.qty,
    required this.description,
    required this.lineTotal,
    required this.unitPrice,
    required this.pickupDate,
    required this.pickupSlot,
  });
}

class ReceiptCompanyInfo {
  final String titleLine1; // es: "NEW CLEANING"
  final String titleLine2; // es: "LAVASECCO" (se vuoi)
  final String ownerLine;  // es: "di Nome Cognome"
  final String addressLine; // es: "Via Roma 10"
  final String cityLine;    // es: "00100 ROMA"
  final String phoneLine;   // es: "333 1234567"

  const ReceiptCompanyInfo({
    required this.titleLine1,
    required this.titleLine2,
    required this.ownerLine,
    required this.addressLine,
    required this.cityLine,
    required this.phoneLine,
  });
}

class ReceiptModel {
  final ReceiptCompanyInfo company;

  /// per ora false => "DA PAGARE"
  final bool isPaid;

  final int clientCode;
  final int partitaNumber;

  final String clientName;
  final String clientPhone;

  final DateTime acceptanceDate;

  /// Data unica "Ritiro" in ricevuta (regola: max pickupDate delle righe)
  final DateTime pickupDate;

  /// numero capi totali = somma qty
  final int capCount;

  /// per ora 0, poi lo aggiungi da UI
  final double acconto;

  /// totale finale
  final double total;

  final List<ReceiptItem> items;

  const ReceiptModel({
    required this.company,
    required this.isPaid,
    required this.clientCode,
    required this.partitaNumber,
    required this.clientName,
    required this.clientPhone,
    required this.acceptanceDate,
    required this.pickupDate,
    required this.capCount,
    required this.acconto,
    required this.total,
    required this.items,
  });

  double get rimanenza => total - acconto;
}
