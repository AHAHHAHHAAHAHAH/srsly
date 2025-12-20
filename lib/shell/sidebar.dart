import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.grey.shade200,
      child: Column(
        children: [
          const SizedBox(height: 40),
          _item('Home', 0, Icons.home),
          _item('Capi', 1, Icons.checkroom_outlined),
          _item('Ordini', 2, Icons.receipt_long),
          _item('Tabella Capi',3, Icons.storage),
          _item('Impostazioni', 4, Icons.settings),
        ],
      ),
    );
  }

  Widget _item(String title, int index, IconData icon) {
    final isSelected = index == selectedIndex;

    return ListTile(
      selected: isSelected,
      leading: Icon(icon),
      title: Text(title),
      onTap: () => onSelect(index),
    );
  }
}
