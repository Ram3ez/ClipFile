import 'package:appwrite/appwrite.dart';
import 'package:clipfile/components/files_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/providers/file_provider.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final config = Config();
  late Future fileList;

  @override
  void initState() {
    super.initState();
    fileList = config.listFiles();
  }

  void onDelete(String fileID) async {
    try {
      await config.deleteData(fileID);
      if (mounted) {
        final updater = context.read<FileProvider>();
        updater.update();
      }
    } on AppwriteException catch (e) {
      if (mounted) {
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

  Stream<Uint8List> onDownload(String fileID, String fileName) {
    var file = config.downloadData(fileID);
    return file;
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
        centerTitle: false,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Consumer<FileProvider>(
            builder: (context, state, child) => FilesContainer(
              future: state.fileList,
              onDelete: onDelete,
              onDownload: onDownload,
            ),
          ),
        ],
      ),
    );
  }
}
