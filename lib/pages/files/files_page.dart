import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:clipfile/components/files_container.dart';
import 'package:clipfile/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/providers/file_provider.dart';

/// The page representing the file storage interface.
class FilesPage extends StatefulWidget {
  final bool isDev;
  const FilesPage({super.key, this.isDev = false});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final config = Config();

  // Kept for initial load logic if needed
  late Future? fileList;

  @override
  void initState() {
    super.initState();
    fileList = config.listFiles(context);
  }

  /// Deletes a file and updates the provider.
  Future<void> onDelete(String fileID) async {
    try {
      await config.deleteData(fileID);
      if (mounted) {
        final updater = context.read<FileProvider>();
        await updater.update();
      }
    } on AppwriteException catch (e) {
      if (mounted) {
        _showErrorDialog("Error Deleting File", e.message!);
      }
    }
  }

  /// Downloads a file.
  Stream<Uint8List> onDownload(String fileID, String fileName) {
    var file = config.downloadData(fileID);
    return file;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            "Files",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (Platform.isWindows)
              IconButton(
                  onPressed: () async {
                    setState(() {
                      if (mounted) {
                        context.read<FileProvider>().update();
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                  )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const SettingsPage()));
                },
                icon: const Icon(Icons.settings_outlined),
                iconSize: 25,
                color: Colors.white,
              ),
            ),
          ],
          centerTitle: false,
          backgroundColor: Theme.of(context).secondaryHeaderColor,
        ),
        body: FilesContainer(
          onDelete: onDelete,
          onDownload: onDownload,
        ));
  }
}
