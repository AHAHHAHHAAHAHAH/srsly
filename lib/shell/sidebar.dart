import 'package:flutter/material.dart';
import 'app_shell.dart';

class Sidebar extends StatelessWidget {
  final AppSection current;
  final void Function(AppSection) onSelect;

  const Sidebar({
    super.key,
    required this.current,
    required this.onSelect,
  });

  Widget _item(IconData icon, String label, AppSection section) {
    final selected = current == section;

    return InkWell(
      onTap: () => onSelect(section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.black.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Smacchiatoria',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),

          _item(Icons.home, 'Home', AppSection.home),
          const SizedBox(height: 8),
          _item(Icons.checkroom, 'Capi', AppSection.capi),
          const SizedBox(height: 8),
          _item(Icons.receipt_long, 'Ordini', AppSection.ordini),
          const SizedBox(height: 8),
          _item(Icons.table_chart, 'Tabella capi', AppSection.tabellaCapi),

          const Spacer(),

          _item(Icons.settings, 'Impostazioni', AppSection.settings),
        ],
      ),
    );
  }
}
