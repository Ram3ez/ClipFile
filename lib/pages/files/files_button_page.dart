import "dart:io";

import "package:appwrite/appwrite.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:clipfile/components/custom_button.dart";
import "package:clipfile/config.dart";
import "package:clipfile/providers/file_provider.dart";

class FilesButton extends StatefulWidget {
  const FilesButton({super.key});

  @override
  State<FilesButton> createState() => _FilesButtonState();
}

class _FilesButtonState extends State<FilesButton> {
  final config = Config();
  late Future fileList;

  @override
  void initState() {
    super.initState();
    fileList = config.listFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomButton(
          onPress: () async {
            HapticFeedback.heavyImpact();
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result != null) {
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: Durations.extralong4,
                      content: Text("Uploading File"),
                    ),
                  );
                }
                await config.insertData(result.files.single.path!);
                if (context.mounted) {
                  final updater = context.read<FileProvider>();
                  updater.update();
                }
              } on AppwriteException catch (e) {
                if (context.mounted) {
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Error Uploading File"),
                          content: Text(e.message!),
                          actions: [
                            MaterialButton(
                              child: Text("Ok"),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            )
                          ],
                        );
                      });
                }
              }
            }
          },
          buttonText: "Single-File",
          long: false,
        ),
        CustomButton(
          onPress: () async {
            HapticFeedback.heavyImpact();
            FilePickerResult? result =
                await FilePicker.platform.pickFiles(allowMultiple: true);
            if (result != null) {
              try {
                List<File> files =
                    result.paths.map((path) => File(path!)).toList();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: Durations.extralong4,
                      content: Text("Uploading Files"),
                    ),
                  );
                }
                for (var file in files) {
                  await config.insertData(file.path);
                }
                if (context.mounted) {
                  final updater = context.read<FileProvider>();
                  updater.update();
                }
              } on AppwriteException catch (e) {
                if (context.mounted) {
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Error Uploading File"),
                          content: Text(e.message!),
                          actions: [
                            MaterialButton(
                              child: Text("Ok"),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            )
                          ],
                        );
                      });
                }
              }
            }
          },
          buttonText: "Multi-File",
          long: false,
        ),
      ],
    );
  }
}
