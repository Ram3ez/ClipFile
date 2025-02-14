import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      direction: DismissDirection.horizontal,
      dismissThresholds: {
        DismissDirection.endToStart: 0.6,
        DismissDirection.startToEnd: 0.6,
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
        child: Icon(
          Icons.download_outlined,
          size: 30,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red,
        ),
        child: Icon(
          Icons.delete_outline,
          size: 30,
        ),
      ),
      key: UniqueKey(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          var delete = false;
          await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    "Delete file?",
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    MaterialButton(
                        color: Theme.of(context).secondaryHeaderColor,
                        onPressed: () {
                          Navigator.of(context).pop();
                          delete = true;
                        },
                        child: Text(
                          "Yes",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                          ),
                        )),
                    MaterialButton(
                        color: Theme.of(context).secondaryHeaderColor,
                        onPressed: () {
                          Navigator.of(context).pop();
                          delete = false;
                        },
                        child: Text(
                          "No",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                );
              });

          return Future.value(delete);
        }
        if (direction == DismissDirection.startToEnd) {
          var fileStream = onDownload!(fileID, fileName);
          Uint8List fileData = Uint8List(0);
          var download = false;
          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Download Started"),
                  content: StreamBuilder(
                      stream: fileStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.active ||
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 50,
                              maxWidth: 50,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasData &&
                            snapshot.connectionState == ConnectionState.done) {
                          fileData = snapshot.data!;

                          return MaterialButton(
                              color: Theme.of(context).secondaryHeaderColor,
                              textColor: Colors.white,
                              child: Text("Save To Files"),
                              onPressed: () {
                                Navigator.pop(context);
                                download = true;
                              });
                        } else {
                          return Text("Download Failed");
                        }
                      }),
                );
              });

          if (download) {
            String? path = await FilePicker.platform.saveFile(
              dialogTitle: "Choose An output",
              fileName: fileName,
              bytes: fileData,
            );

            try {
              if (path != null) {
                await File(path).writeAsBytes(fileData);
              }
            } catch (e) {
              log(e.toString());
            }
            return Future.value(false);
          }
        }
        return Future.value(false);
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete!(fileID);
        }
      },
      child: child,
    );
  }
}
