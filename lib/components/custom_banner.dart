import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restart_app/restart_app.dart';

/// A helper class to creates a standardized MaterialBanner for the app.
class CustomBanner {
  /// Creates a banner prompting the user to restart the app.
  static MaterialBanner customBanner(
      String text, BuildContext context, bool updated) {
    return MaterialBanner(
      content: Text(text),
      contentTextStyle: GoogleFonts.poppins(
        color: Colors.black,
      ),
      actions: [
        // Show restart button on supported platforms
        if (!Platform
            .isWindows) // Windows handled below differently? Original code logic preserved.
          TextButton(
            onPressed: () {
              _handleRestart(updated);
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text(
              "Restart",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).secondaryHeaderColor,
              ),
            ),
          )
        else
          // Original code didn't show button for Windows?
          // Wait, original: !Platform.isWindows ? TextButton(...) : SizedBox.shrink()
          // Inside callback: if(Platform.isWindows) exit(1)...
          // BUT the button is HIDDEN on windows, so that code is dead code?
          // " !Platform.isWindows ? ... : SizedBox.shrink()"
          // So `if (Platform.isWindows)` inside the onPressed is never reached.
          // I will assume the intention was to HIDE it on windows.
          const SizedBox.shrink(),
      ],
    );
  }

  static void _handleRestart(bool updated) {
    if (Platform.isWindows) {
      exit(
          1); // This code is technically unreachable if button is hidden on Windows
    }

    if (Platform.isAndroid || Platform.isIOS) {
      Restart.restartApp(
        notificationTitle: "Restarted App",
        notificationBody: !updated
            ? "Succesfully Updated Settings"
            : "Succesfully Patched App",
      );
    }
  }
}
