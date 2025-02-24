import "dart:io";

import "package:appwrite/appwrite.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:image_picker/image_picker.dart";
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
  late Future? fileList;

  @override
  void initState() {
    super.initState();
    fileList = config.listFiles(context);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: Platform.isWindows
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Platform.isWindows
            ? SizedBox.shrink()
            : CustomButton(
                onPress: () async {
                  HapticFeedback.heavyImpact();
                  final XFile? result = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );
                  if (result != null) {
                    try {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: LinearProgressIndicator(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).secondaryHeaderColor,
                            backgroundColor: Theme.of(context).primaryColor,
                            minHeight: 10,
                          ),
                          duration: Duration(hours: 2),
                        ));
                      }

                      await config.insertData(
                          bytes: await result.readAsBytes(), name: result.name);
                      if (context.mounted) {
                        final reader = context.read<FileProvider>();
                        reader.update();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      }
                    } on AppwriteException catch (e) {
                      if (context.mounted) {
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Error Uploading Image"),
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
                onLongPress: () async {
                  HapticFeedback.heavyImpact();
                  final List<XFile> result =
                      await ImagePicker().pickMultipleMedia();
                  if (result.isNotEmpty) {
                    try {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: LinearProgressIndicator(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).secondaryHeaderColor,
                            backgroundColor: Theme.of(context).primaryColor,
                            minHeight: 10,
                          ),
                          duration: Duration(hours: 2),
                        ));
                      }

                      for (var media in result) {
                        await config.insertData(
                            bytes: await media.readAsBytes(), name: media.name);
                      }

                      if (context.mounted) {
                        final reader = context.read<FileProvider>();
                        reader.update();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      }
                    } on AppwriteException catch (e) {
                      if (context.mounted) {
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Error Uploading Image"),
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
                buttonText: "cam/library",
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).secondaryHeaderColor,
                      backgroundColor: Theme.of(context).primaryColor,
                      minHeight: 10,
                    ),
                    duration: Duration(hours: 2),
                  ));
                }
                for (var file in files) {
                  var bytes = await file.readAsBytes();
                  var fileName = file.path.substring(
                      file.path.lastIndexOf(Platform.pathSeparator) + 1);

                  await config.insertData(bytes: bytes, name: fileName);
                }
                if (context.mounted) {
                  final reader = context.read<FileProvider>();
                  reader.update();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          buttonText: "Choose file",
          long: Platform.isWindows,
        ),
      ],
    );
  }
}
