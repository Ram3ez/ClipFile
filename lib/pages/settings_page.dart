import 'dart:io';

import 'package:clipfile/components/custom_button.dart';
import 'package:clipfile/components/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restart_app/restart_app.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final endPointController = TextEditingController();

  final projectController = TextEditingController();

  final databaseController = TextEditingController();

  final documentController = TextEditingController();

  final collectionController = TextEditingController();

  final attributeController = TextEditingController();

  final bucketController = TextEditingController();

  final Box<String> settingsBox = Hive.box("settings");

  MaterialBanner banner(String text, bool isUpdated) {
    return MaterialBanner(
      content: Text(text),
      contentTextStyle: GoogleFonts.poppins(
        color: Colors.black,
      ),
      actions: [
        isUpdated
            ? TextButton(
                onPressed: () {
                  if (Platform.isWindows) {
                    exit(1);
                  }

                  if (Platform.isAndroid || Platform.isIOS) {
                    //isUpdated ? FlutterExitApp.exitApp() : 1;
                    isUpdated
                        ? Restart.restartApp(
                            notificationTitle: "Restarted App",
                            notificationBody: "Succesfully Updated Settings",
                          )
                        : 1;
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
            : IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                icon: isUpdated && (Platform.isIOS || Platform.isAndroid)
                    ? Icon(Icons.restart_alt_outlined)
                    : Icon(Icons.close)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              color: Colors.white,
              iconSize: 30,
              icon: Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.9,
                  minWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 30,
                      ),
                      CustomTextField(
                        label: "ENDPOINT",
                        hint: settingsBox.get("endpoint") ??
                            "https://cloud.appwrite.io/v1",
                        controller: endPointController,
                      ),
                      CustomTextField(
                        label: "PROJECT ID",
                        hint: settingsBox.get("projectID") ?? "",
                        controller: projectController,
                      ),
                      CustomTextField(
                        label: "DATABASE ID",
                        hint: settingsBox.get("databaseID") ?? "",
                        controller: databaseController,
                      ),
                      CustomTextField(
                        label: "DOCUMENT ID",
                        hint: settingsBox.get("documentID") ?? "",
                        controller: documentController,
                      ),
                      CustomTextField(
                        label: "COLLECTION ID",
                        hint: settingsBox.get("collectionID") ?? "",
                        controller: collectionController,
                      ),
                      CustomTextField(
                        label: "ATTRIBUTE NAME",
                        hint: settingsBox.get("attributeName") ?? "clipboard",
                        controller: attributeController,
                      ),
                      CustomTextField(
                        label: "BUCKET ID",
                        hint: settingsBox.get("bucketID") ?? "",
                        controller: bucketController,
                      ),
                      Spacer(),
                      CustomButton(
                          onPress: () async {
                            ScaffoldMessenger.of(context)
                                .clearMaterialBanners();
                            var isUpdated = false;
                            if (endPointController.text != "") {
                              isUpdated = true;
                              await settingsBox.put(
                                  "endpoint", endPointController.text);
                            }
                            if (projectController.text != "") {
                              isUpdated = true;
                              await settingsBox.put(
                                  "projectID", projectController.text);
                            }
                            if (databaseController.text != "") {
                              isUpdated = true;
                              await settingsBox.put(
                                  "databaseID", databaseController.text);
                            }
                            if (documentController.text != "") {
                              isUpdated = true;
                              await settingsBox.put(
                                  "documentID", documentController.text);
                            }
                            if (collectionController.text != "") {
                              isUpdated = true;
                              await settingsBox.put(
                                  "collectionID", collectionController.text);
                            }
                            if (attributeController.text != "") {
                              isUpdated = true;
                              await settingsBox.put(
                                  "attributeName", attributeController.text);
                            }
                            if (bucketController.text != "") {
                              isUpdated = true;
                              await settingsBox.put(
                                  "bucketID", bucketController.text);
                            }
                            if (settingsBox.get("endpoint") !=
                                    "https://cloud.appwrite.io/v1" &&
                                !isUpdated) {
                              isUpdated = true;
                              await settingsBox.put(
                                  "endpoint", "https://cloud.appwrite.io/v1");
                            }
                            if (settingsBox.get("attributeName") !=
                                    "clipboard" &&
                                !isUpdated) {
                              isUpdated = true;
                              await settingsBox.put(
                                  "attributeName", "clipboard");
                            }
                            if (context.mounted) {
                              if (isUpdated) {
                                endPointController.clear();
                                projectController.clear();
                                databaseController.clear();
                                documentController.clear();
                                collectionController.clear();
                                attributeController.clear();
                                bucketController.clear();

                                setState(() {});
                                ScaffoldMessenger.of(context)
                                    .showMaterialBanner(
                                  banner("Settings Updated Succesfully",
                                      isUpdated),
                                );
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showMaterialBanner(
                                  banner("No Changes", isUpdated),
                                );
                              }
                            }

                            /* settingsBox.put("databaseID", databaseController.text);
                                settingsBox.put("projectID", "67a60a050000bc893984");
                                settingsBox.put("documentID", "67a60cb600360cda06f2");
                                settingsBox.put("collectionID", "67a60c07002df8f2e9d8");
                                settingsBox.put("bucketID", "67a6e34a001ffa8c8949"); */
                          },
                          buttonText: "Update",
                          long: true),
                      Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
