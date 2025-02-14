import "package:clipfile/components/custom_banner.dart";
import "package:flutter/material.dart";

class CustomTextField extends StatelessWidget {
  const CustomTextField(
      {super.key,
      required this.controller,
      required this.label,
      required this.hint,
      this.onChanged});

  final TextEditingController controller;
  final String label;
  final String hint;
  final void Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onEditingComplete: () {
          onChanged!();
          ScaffoldMessenger.of(context).showMaterialBanner(
            CustomBanner.customBanner(
                "Settings Updated Succesfully", context, false),
          );
        },
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
