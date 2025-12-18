import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget that allows dismissing a child widget to delete or download a file.
class DismissTile extends StatelessWidget {
  const DismissTile({
    super.key,
    required this.child,
    required this.onDelete,
    required this.onDownload,
    required this.fileID,
    required this.fileName,
  });

  final Widget child;
  final void Function(String)? onDelete;
  final Stream<Uint8List> Function(String, String)? onDownload;
  final String fileID;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.6,
        DismissDirection.startToEnd: 0.6,
      },
      background: _buildBackground(
          Alignment.centerLeft, Colors.blue, Icons.download_outlined),
      secondaryBackground: _buildBackground(
          Alignment.centerRight, Colors.red, Icons.delete_outline),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(context);
        } else if (direction == DismissDirection.startToEnd) {
          return await _handleDownload(context);
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call(fileID);
        }
      },
      child: child,
    );
  }

  Widget _buildBackground(Alignment alignment, Color color, IconData icon) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color),
      child: Icon(icon, size: 30, color: Colors.white),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Delete file?", style: GoogleFonts.poppins()),
              actions: [
                MaterialButton(
                  color: Theme.of(context).secondaryHeaderColor,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Yes",
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
                MaterialButton(
                  color: Theme.of(context).secondaryHeaderColor,
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    "No",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _handleDownload(BuildContext context) async {
    if (onDownload == null) return false;

    final fileStream = onDownload!(fileID, fileName);
    Uint8List? fileData;
    bool shouldSave = false;

    // Show download progress dialog
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Download Started"),
          content: StreamBuilder<Uint8List>(
            stream: fileStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 50,
                  width: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.done) {
                fileData = snapshot.data;
                return MaterialButton(
                  color: Theme.of(context).secondaryHeaderColor,
                  textColor: Colors.white,
                  onPressed: () {
                    shouldSave = true;
                    Navigator.pop(context);
                  },
                  child: const Text("Save To Files"),
                );
              } else {
                // Close dialog on failure to avoid stuck state, or show error
                return const Text("Download Failed");
              }
            },
          ),
        );
      },
    );

    if (shouldSave && fileData != null) {
      try {
        String? path = await FilePicker.platform.saveFile(
          dialogTitle: "Choose An output",
          fileName: fileName,
          bytes: fileData,
        );

        if (path != null) {
          await File(path).writeAsBytes(fileData!);
        }
      } catch (e) {
        log("Error saving file: $e");
      }
    }

    // Always return false to prevent the tile from being dismissed (removed) from the UI after download
    return false;
  }
}
