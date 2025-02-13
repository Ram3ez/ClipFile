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

  /* MaterialBanner banner(String text, BuildContext context) {
    return MaterialBanner(
      content: Text(text),
      contentTextStyle: GoogleFonts.poppins(
        color: Colors.black,
      ),
      actions: [
        TextButton(
            onPressed: () {
              if (Platform.isWindows) {
                exit(1);
              }

              if (Platform.isAndroid || Platform.isIOS) {
                //isUpdated ? FlutterExitApp.exitApp() : 1;
                Restart.restartApp(
                  notificationTitle: "Restarted App",
                  notificationBody: "Succesfully Updated Settings",
                );
              }
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text(
              "Restart",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).secondaryHeaderColor,
              ),
            ))
      ],
    );
  } */

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onEditingComplete: () {
          onChanged!();
          ScaffoldMessenger.of(context).showMaterialBanner(
            CustomBanner.customBanner("Settings Updated Succesfully", context),
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
