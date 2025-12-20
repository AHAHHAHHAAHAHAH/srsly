import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final bool obscure;
  final TextEditingController controller;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
