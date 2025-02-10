import "package:flutter/material.dart";

class CustomTextField extends StatelessWidget {
  const CustomTextField(
      {super.key,
      required this.controller,
      required this.label,
      required this.hint});

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder()),
      ),
    );
  }
}
