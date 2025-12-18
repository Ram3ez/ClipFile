import "package:clipfile/components/custom_banner.dart";
import "package:flutter/material.dart";

/// A customized text field widget for settings and inputs.
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.isSetting = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;
  final bool isSetting;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        obscureText: isPassword,
        onEditingComplete: () {
          onChanged?.call();
          if (isSetting) {
            ScaffoldMessenger.of(context).showMaterialBanner(
              CustomBanner.customBanner(
                  "Settings Updated Succesfully", context, false),
            );
          }
        },
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
