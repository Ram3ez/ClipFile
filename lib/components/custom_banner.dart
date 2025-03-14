import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restart_app/restart_app.dart';

class CustomBanner {
  static MaterialBanner customBanner(
      String text, BuildContext context, bool updated) {
    return MaterialBanner(
      content: Text(text),
      contentTextStyle: GoogleFonts.poppins(
        color: Colors.black,
      ),
      actions: [
        !Platform.isWindows
            ? TextButton(
                onPressed: () {
                  if (Platform.isWindows) {
                    exit(1);
                  }

                  if (Platform.isAndroid || Platform.isIOS) {
                    //isUpdated ? FlutterExitApp.exitApp() : 1;
                    Restart.restartApp(
                      notificationTitle: "Restarted App",
                      notificationBody: !updated
                          ? "Succesfully Updated Settings"
                          : "Succesfully Patched App",
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
            : SizedBox.shrink(),
      ],
    );
  }
}
