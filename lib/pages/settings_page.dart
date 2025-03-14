import 'dart:io';
import 'package:clipfile/components/custom_banner.dart';
import 'package:clipfile/components/custom_button.dart';
import 'package:clipfile/components/custom_text_field.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/providers/auth_provider.dart';
import 'package:clipfile/providers/isdev_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:window_manager/window_manager.dart';

// ignore: must_be_immutable
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
  String userName = "";

  void getUserName() async {
    userName = (await context.read<AuthProvider>().user)?.name ?? "";
    setState(() {});
  }

  @override
  void initState() {
    getUserName();
    super.initState();
  }

  Widget onTopContainer(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(4),
      ),
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
                activeColor: Theme.of(context).secondaryHeaderColor,
                value: onTop,
                onChanged: (val) async {
                  if (val == true) {
                    await settingsBox.put("onTop", "true");
                    await WindowManager.instance.setAlwaysOnTop(true);
                  } else {
                    await settingsBox.put("onTop", "false");
                    await WindowManager.instance.setAlwaysOnTop(false);
                  }
                  setState(() {
                    Config.alwaysOnTop = val! ? "true" : "false";
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
    );
  }

  Widget setFixedSizeContainer(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8, left: 8, right: 8),
      padding: EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(4),
      ),
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
                activeColor: Theme.of(context).secondaryHeaderColor,
                value: fixedSize,
                onChanged: (val) async {
                  if (val == true) {
                    await settingsBox.put("fixedSize", "true");
                    await WindowManager.instance.setSize(const Size(400, 730));
                    await WindowManager.instance.setResizable(false);
                  } else {
                    await settingsBox.put("fixedSize", "false");
                    await WindowManager.instance.setResizable(true);
                  }
                  setState(() {
                    Config.fixedSize = val! ? "true" : "false";
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
    );
  }

  final updater = ShorebirdUpdater();
  @override
  Widget build(BuildContext context) {
    bool isDev = context.read<IsdevProvider>().isDev;
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
                ScaffoldMessenger.of(context).clearMaterialBanners();
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
            child: !isDev
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Current User: $userName",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Platform.isWindows
                          ? onTopContainer(context)
                          : SizedBox.shrink(),
                      Platform.isWindows
                          ? SizedBox(
                              height: 5,
                            )
                          : SizedBox.shrink(),
                      Platform.isWindows
                          ? setFixedSizeContainer(context)
                          : SizedBox.shrink(),
                      Platform.isWindows
                          ? SizedBox(
                              height: 20,
                            )
                          : SizedBox.shrink(),
                      updater.isAvailable
                          ? CustomButton(
                              onPress: () async {
                                final status = await updater.checkForUpdate();
                                final currentPatch =
                                    await updater.readNextPatch();

                                if (status == UpdateStatus.outdated &&
                                    context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showMaterialBanner(MaterialBanner(
                                          content: Text("Downloading.... "),
																					backgroundColor: Theme.of(context).primaryColor,
                                          actions: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: SizedBox(
                                            height: 14,
                                            width: 14,
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                      ]));
                                  try {
                                    await updater.update();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentMaterialBanner();
                                      ScaffoldMessenger.of(context)
                                          .showMaterialBanner(
                                              CustomBanner.customBanner(
                                                  "updated Succesfully",
                                                  context,
                                                  true));
                                    }
                                  } on UpdateException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(e.toString())));
                                    }
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showMaterialBanner(MaterialBanner(
                                      content: Text(currentPatch != null
                                          ? "Already on latest Patch: ${currentPatch.number}"
                                          : "No Patches found"),
																			backgroundColor: Theme.of(context).primaryColor,
                                      actions: [
                                        IconButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .clearMaterialBanners();
                                            },
                                            icon: Icon(Icons.close))
                                      ],
                                    ));
                                  }
                                }
                              },
                              buttonText: "Check For Updates",
                              long: true)
                          : SizedBox.shrink(),
                      updater.isAvailable
                          ? SizedBox(
                              height: 20,
                            )
                          : SizedBox.shrink(),
                      CustomButton(
                          onPress: () async {
                            await context.read<AuthProvider>().logout(context);
                            settingsBox.put("documentID", "");
                            settingsBox.put("bucketID", "");
                            settingsBox.deleteAll([
                              "documentID",
                              "collectionID",
                              "projectID",
                              "bucketID",
                              "attributeName",
                              "endpoint",
                              "databaseID",
                            ]);
                            Config.bucketID = "";
                            Config.documentID = "";
                            Config.collectionID = "";
                            Config.databaseID = "";
                            Config.projectID = "";
                            await Future.delayed(Duration(milliseconds: 400));
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          buttonText: "Log Out",
                          long: true),
                    ],
                  )
                : SingleChildScrollView(
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
                            hint:
                                settingsBox.get("attributeName") ?? "clipboard",
                            controller: attributeController,
                            onChanged: () async {
                              if (attributeController.text != "") {
                                await settingsBox.put(
                                    "attributeName", attributeController.text);
                              } else {
                                await settingsBox.put(
                                    "attributeName", "clipboard");
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
                              : onTopContainer(context),
                          !Platform.isWindows
                              ? SizedBox.shrink()
                              : setFixedSizeContainer(context),
                          Spacer(),
                          updater.isAvailable
                              ? CustomButton(
                                  onPress: () async {
                                    final status =
                                        await updater.checkForUpdate();
                                    final currentPatch =
                                        await updater.readNextPatch();

                                    if (status == UpdateStatus.outdated &&
                                        context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showMaterialBanner(MaterialBanner(
                                              content: Text("Downloading.... "),
																					backgroundColor: Theme.of(context).primaryColor,
                                              actions: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: SizedBox(
                                                height: 14,
                                                width: 14,
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                          ]));
                                      try {
                                        await updater.update();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentMaterialBanner();
                                          ScaffoldMessenger.of(context)
                                              .showMaterialBanner(
                                                  CustomBanner.customBanner(
                                                      "updated Succesfully",
                                                      context,
                                                      true));
                                        }
                                      } on UpdateException catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(e.toString())));
                                        }
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showMaterialBanner(MaterialBanner(
                                          content: Text(currentPatch != null
                                              ? "Already on latest Patch: ${currentPatch.number}"
                                              : "No Patches found"),
																					backgroundColor: Theme.of(context).primaryColor,
                                          actions: [
                                            IconButton(
                                                onPressed: () {
                                                  ScaffoldMessenger.of(context)
                                                      .clearMaterialBanners();
                                                },
                                                icon: Icon(Icons.close))
                                          ],
                                        ));
                                      }
                                    }
                                  },
                                  buttonText: "Check For Updates",
                                  long: true)
                              : SizedBox.shrink(),
                          updater.isAvailable ? Spacer() : SizedBox.shrink(),
                          CustomButton(
                              onPress: () async {
                                context.read<IsdevProvider>().update(false);
                                await Future.delayed(
                                    Duration(milliseconds: 400));
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              },
                              buttonText: "Exit Dev Mode",
                              long: true),
                          SizedBox(
                            height: 10,
                          ),
                          updater.isAvailable ? Spacer() : SizedBox.shrink(),
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
