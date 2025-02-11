import 'package:appwrite/models.dart';
import 'package:clipfile/components/dismiss_tile.dart';
import 'package:clipfile/components/image_preview.dart';
import 'package:clipfile/providers/file_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';

class FilesContainer extends StatelessWidget {
  const FilesContainer({
    super.key,
    required this.future,
    required this.onDelete,
    required this.onDownload,
  });

  final Future future;
  final void Function(String)? onDelete;
  final Stream<Uint8List> Function(String, String)? onDownload;

  List<dynamic> init(FileList fileList, int index) {
    String fileName = fileList.files[index].name;
    double fileSize = fileList.files[index].sizeOriginal / 1024;
    bool isKB = fileSize < 1000;
    fileSize = fileSize > 1000 ? fileSize / 1024 : fileSize;
    //print(fileName + fileList.files[index].$updatedAt);

    IconData icon;
    var ext = fileName.substring(fileName.lastIndexOf(".") + 1);

    switch (ext.toLowerCase()) {
      case "jpg" || "heic" || "jpeg" || "png":
        icon = Icons.image_outlined;
        break;
      case "mov" || "mp4" || "mkv":
        icon = Icons.movie_creation_outlined;
        break;
      case "txt":
        icon = Icons.text_snippet_outlined;
        break;
      case "apk" || "aab":
        icon = Icons.android_outlined;
        break;
      case "ipa":
        icon = Icons.apple_outlined;
        break;
      case "exe" || "msix":
        icon = Icons.window_sharp;
        break;
      default:
        icon = Icons.question_mark;
        break;
    }

    return [fileName, fileSize, fileList.files[index].$id, isKB, icon];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        alignment: Alignment.topLeft,
        decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: EdgeInsets.all(23),
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var files = snapshot.data as FileList;
              return LiquidPullToRefresh(
                showChildOpacityTransition: true,
                color: Theme.of(context).secondaryHeaderColor,
                onRefresh: () async {
                  if (context.mounted) {
                    final updater = context.read<FileProvider>();
                    updater.update();
                  }
                },
                child: ListView.builder(
                  itemCount: files.total,
                  itemBuilder: (context, index) {
                    var [
                      String fileName,
                      double fileSize,
                      String fileID,
                      bool isKB,
                      IconData icon,
                    ] = init(files, index);

                    /* return Text(
                            "$fileName ${fileSize.toStringAsFixed(2)} ${isKB ? "KB" : "MB"}"); */
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          clipBehavior: Clip.antiAlias,
                          child: DismissTile(
                            onDelete: onDelete,
                            onDownload: onDownload,
                            fileID: fileID,
                            fileName: fileName,
                            child: InkWell(
                              onLongPress: () {
                                HapticFeedback.heavyImpact();
                                ImagePreview.imagePreview(
                                    context, fileID, fileName);
                              },
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: 12, top: 10, bottom: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                ),
                                height: 75,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          backgroundBlendMode:
                                              BlendMode.softLight,
                                        ),
                                        child: Icon(
                                          icon,
                                          color: Theme.of(context)
                                              .secondaryHeaderColor,
                                        )),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.55,
                                      height: 65,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          fileName,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        "${isKB ? fileSize.toStringAsFixed(1) : fileSize.toStringAsFixed(2)} ${isKB ? "KB" : "MB"}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Color.fromRGBO(0, 0, 0, 0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                      ],
                    );
                  },
                ),
              );
            }
            return ConstrainedBox(
              constraints: BoxConstraints(),
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
