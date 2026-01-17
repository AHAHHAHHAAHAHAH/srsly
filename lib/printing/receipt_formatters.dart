class ReceiptFmt {
  /// Larghezza tipica 80mm (Epson) -> 42 char.
  static const int width = 42;

  static String sep() => '-' * width;

  static String fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  static String fmtMoney(double v) {
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String truncate(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max);
  }

  static String padRight(String s, int width) => s.padRight(width);
  static String padLeft(String s, int width) => s.padLeft(width);
}
