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

/// Buttons to upload files (camera/library or file picker).
class FilesButton extends StatefulWidget {
  const FilesButton({super.key});

  @override
  State<FilesButton> createState() => _FilesButtonState();
}

class _FilesButtonState extends State<FilesButton> {
  final config = Config();

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _buildWindowsButton();
    } else {
      return _buildMobileButtons();
    }
  }

  Widget _buildWindowsButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildFilePickerButton(long: true),
      ],
    );
  }

  Widget _buildMobileButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomButton(
          onPress: _handleCameraOrLibrary,
          onLongPress: _handleMultiMedia,
          buttonText: "cam/library",
          long: false,
        ),
        _buildFilePickerButton(long: false),
      ],
    );
  }

  Widget _buildFilePickerButton({required bool long}) {
    return CustomButton(
      onPress: _handleFilePicker,
      buttonText: "Choose file",
      long: long,
    );
  }

  Future<void> _handleCameraOrLibrary() async {
    HapticFeedback.heavyImpact();
    final XFile? result =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (result != null) {
      await _uploadFiles([result]);
    }
  }

  Future<void> _handleMultiMedia() async {
    HapticFeedback.heavyImpact();
    final List<XFile> result = await ImagePicker().pickMultipleMedia();
    if (result.isNotEmpty) {
      await _uploadFiles(result);
    }
  }

  Future<void> _handleFilePicker() async {
    HapticFeedback.heavyImpact();
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      // Convert PlatformFiles to XFiles or process directly
      // The original code used File(path) which works for mobile/desktop IO.
      // However, to reuse _uploadFiles which takes XFile, we might just process separately
      // or map them.

      _showUploadingSnackBar();

      try {
        for (var simpleFile in result.files) {
          // Ensure path is available
          if (simpleFile.path == null) continue;

          final file = File(simpleFile.path!);
          var bytes = await file.readAsBytes();
          var fileName = simpleFile.name; // FilePicker gives name

          await config.insertData(bytes: bytes, name: fileName);
        }
        _refreshProvider();
      } on AppwriteException catch (e) {
        _showErrorDialog(e.message ?? "Error uploading file");
      }
    }
  }

  Future<void> _uploadFiles(List<XFile> files) async {
    _showUploadingSnackBar();

    try {
      for (var file in files) {
        await config.insertData(
            bytes: await file.readAsBytes(), name: file.name);
      }
      _refreshProvider();
    } on AppwriteException catch (e) {
      _showErrorDialog(e.message ?? "Error uploading file");
    }
  }

  void _showUploadingSnackBar() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: LinearProgressIndicator(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).secondaryHeaderColor,
        backgroundColor: Theme.of(context).primaryColor,
        minHeight: 10,
      ),
      duration: const Duration(
          hours: 2), // Long duration, manually hidden on completion
    ));
  }

  void _refreshProvider() {
    if (context.mounted) {
      final reader = context.read<FileProvider>();
      reader.update();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void _showErrorDialog(String message) {
    if (!context.mounted) return;
    // Hide progress snackbar if error
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error Uploading"),
            content: Text(message),
            actions: [
              MaterialButton(
                child: const Text("Ok"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }
}
