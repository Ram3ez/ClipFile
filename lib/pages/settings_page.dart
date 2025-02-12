import 'dart:io';
import 'package:clipfile/components/custom_text_field.dart';
import 'package:clipfile/config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';

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

  bool onTop = Config.alwaysOnTop == "false" ? false : true;
  bool fixedSize = Config.fixedSize == "true" ? true : false;

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
                  maxHeight: MediaQuery.of(context).size.height * 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: Platform.isWindows ? 15 : 30,
                    ),
                    CustomTextField(
                      label: "ENDPOINT",
                      hint: settingsBox.get("endpoint") ??
                          "https://cloud.appwrite.io/v1",
                      controller: endPointController,
                      onChanged: () async {
                        if (endPointController.text != "") {
                          await settingsBox.put(
                              "endpoint", endPointController.text);
                        } else {
                          await settingsBox.put(
                              "endpoint", "https://cloud.appwrite.io/v1");
                        }
                        endPointController.clear();
                        setState(() {});
                      },
                    ),
                    CustomTextField(
                      label: "PROJECT ID",
                      hint: settingsBox.get("projectID") ?? "",
                      controller: projectController,
                      onChanged: () async {
                        if (projectController.text != "") {
                          await settingsBox.put(
                              "projectID", projectController.text);
                          projectController.clear();
                          setState(() {});
                        }
                      },
                    ),
                    CustomTextField(
                      label: "DATABASE ID",
                      hint: settingsBox.get("databaseID") ?? "",
                      controller: databaseController,
                      onChanged: () async {
                        if (databaseController.text != "") {
                          await settingsBox.put(
                              "databaseID", databaseController.text);
                          databaseController.clear();
                          setState(() {});
                        }
                      },
                    ),
                    CustomTextField(
                      label: "DOCUMENT ID",
                      hint: settingsBox.get("documentID") ?? "",
                      controller: documentController,
                      onChanged: () async {
                        if (documentController.text != "") {
                          await settingsBox.put(
                              "documentID", documentController.text);
                          documentController.clear();
                          setState(() {});
                        }
                      },
                    ),
                    CustomTextField(
                      label: "COLLECTION ID",
                      hint: settingsBox.get("collectionID") ?? "",
                      controller: collectionController,
                      onChanged: () async {
                        if (collectionController.text != "") {
                          await settingsBox.put(
                              "collectionID", collectionController.text);
                          collectionController.clear();
                          setState(() {});
                        }
                      },
                    ),
                    CustomTextField(
                      label: "ATTRIBUTE NAME",
                      hint: settingsBox.get("attributeName") ?? "clipboard",
                      controller: attributeController,
                      onChanged: () async {
                        if (attributeController.text != "") {
                          await settingsBox.put(
                              "attributeName", attributeController.text);
                        } else {
                          await settingsBox.put("attributeName", "clipboard");
                        }
                        attributeController.clear();
                        setState(() {});
                      },
                    ),
                    CustomTextField(
                      label: "BUCKET ID",
                      hint: settingsBox.get("bucketID") ?? "",
                      controller: bucketController,
                      onChanged: () async {
                        if (bucketController.text != "") {
                          await settingsBox.put(
                              "bucketID", bucketController.text);
                          bucketController.clear();
                          setState(() {});
                        }
                      },
                    ),
                    !Platform.isWindows
                        ? SizedBox.shrink()
                        : Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            padding: EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            height: MediaQuery.of(context).size.height * 0.069,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Transform.scale(
                                  scale: 1.5,
                                  child: Checkbox(
                                      activeColor: Theme.of(context)
                                          .secondaryHeaderColor,
                                      value: onTop,
                                      onChanged: (val) async {
                                        if (val == true) {
                                          await settingsBox.put(
                                              "onTop", "true");
                                          await WindowManager.instance
                                              .setAlwaysOnTop(true);
                                        } else {
                                          await settingsBox.put(
                                              "onTop", "false");
                                          await WindowManager.instance
                                              .setAlwaysOnTop(false);
                                        }
                                        setState(() {
                                          Config.alwaysOnTop =
                                              val! ? "true" : "false";
                                          onTop = val;
                                        });
                                      }),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Text(
                                    "Always on Top",
                                    style: GoogleFonts.poppins(fontSize: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    !Platform.isWindows
                        ? SizedBox.shrink()
                        : Container(
                            margin: EdgeInsets.only(top: 8, left: 8, right: 8),
                            padding: EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            height: MediaQuery.of(context).size.height * 0.069,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Transform.scale(
                                  scale: 1.5,
                                  child: Checkbox(
                                      activeColor: Theme.of(context)
                                          .secondaryHeaderColor,
                                      value: fixedSize,
                                      onChanged: (val) async {
                                        if (val == true) {
                                          await settingsBox.put(
                                              "fixedSize", "true");
                                          await WindowManager.instance
                                              .setSize(const Size(400, 730));
                                          await WindowManager.instance
                                              .setResizable(false);
                                        } else {
                                          await settingsBox.put(
                                              "fixedSize", "false");
                                          await WindowManager.instance
                                              .setResizable(true);
                                        }
                                        setState(() {
                                          Config.fixedSize =
                                              val! ? "true" : "false";
                                          fixedSize = val;
                                        });
                                      }),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Text(
                                    "Fixed Size",
                                    style: GoogleFonts.poppins(fontSize: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    //Spacer(),
                    /* CustomButton(
                        onPress: () async {
                          ScaffoldMessenger.of(context).clearMaterialBanners();
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
                          if (settingsBox.get("attributeName") != "clipboard" &&
                              !isUpdated) {
                            isUpdated = true;
                            await settingsBox.put("attributeName", "clipboard");
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
                              ScaffoldMessenger.of(context).showMaterialBanner(
                                banner(
                                    "Settings Updated Succesfully", isUpdated),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showMaterialBanner(
                                banner("No Changes", isUpdated),
                              );
                            }
                          }
                        },
                        buttonText: "Update",
                        long: true),
                    Spacer(), */
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
