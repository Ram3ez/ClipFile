import 'package:appwrite/models.dart';
import 'package:clipfile/components/dismiss_tile.dart';
import 'package:clipfile/components/image_preview.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/providers/file_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class FilesContainer extends StatefulWidget {
  const FilesContainer({
    super.key,
    //required this.future,
    required this.onDelete,
    required this.onDownload,
  });

  //final Future future;
  final Future<void> Function(String)? onDelete;
  final Stream<Uint8List> Function(String, String)? onDownload;

  @override
  State<FilesContainer> createState() => _FilesContainerState();
}

class _FilesContainerState extends State<FilesContainer> {
  List<dynamic> init(FileList fileList, int index) {
    String fileName = fileList.files[index].name;
    double fileSize = fileList.files[index].sizeOriginal / 1024;
    bool isKB = fileSize < 1000;
    fileSize = fileSize > 1000 ? fileSize / 1024 : fileSize;

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
    return DropRegion(
      formats: Formats.standardFormats,
      onDropOver: (DropOverEvent event) async {
        if (event.session.allowedOperations.length == 1) {
          return DropOperation.forbidden;
        }
        return DropOperation.copy;
      },
      onPerformDrop: (PerformDropEvent event) async {
        var items = event.session.items;
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
        for (var item in items) {
          var reader = item.dataReader!;
          reader.getFile(null, (file) async {
            var fileData = await file.readAll();
            if (!context.mounted) return;

            await Config().insertData(
              bytes: fileData,
              name: file.fileName,
              context: context,
            );

            if (context.mounted) {
              var reader = context.read<FileProvider>();
              reader.update();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          });
        }
      },
      child: Center(
        child: Container(
          margin: EdgeInsets.all(20),
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(
            color: Theme.of(context).secondaryHeaderColor,
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.all(23),
          child: Consumer<FileProvider>(
            //child:
            builder: (context, state, child) => FutureBuilder(
              future: state.fileList, //widget.future,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var files = snapshot.data as FileList;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LiquidPullToRefresh(
                      animSpeedFactor: 2,
                      showChildOpacityTransition: true,
                      color: Theme.of(context).primaryColor,
                      onRefresh: () async {
                        if (context.mounted) {
                          final updater = context.read<FileProvider>();
                          await updater.update();
                        }
                      },
                      child: ListView.separated(
                        itemCount: files.total,
                        key: UniqueKey(),
                        cacheExtent: 0,
                        separatorBuilder: (context, index) => SizedBox(
                          height: 8,
                        ),
                        itemBuilder: (context, index) {
                          var [
                            String fileName,
                            double fileSize,
                            String fileID,
                            bool isKB,
                            IconData icon,
                          ] = init(files, index);

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            clipBehavior: Clip.antiAlias,
                            child: DismissTile(
                              onDelete: (e) async {
                                //files = FileList(total: 0, files: List.empty());
                                await widget.onDelete!(e);
                              },
                              onDownload: widget.onDownload,
                              fileID: fileID,
                              fileName: fileName,
                              child: DragItemWidget(
                                dragItemProvider: (request) async {
                                  final item = DragItem(
                                    suggestedName: fileName,
                                  );
                                  if (item.virtualFileSupported) {
                                    item.addVirtualFile(
                                        format: Formats.zip,
                                        provider:
                                            (sinkProvider, progress) async {
                                          final downFile = await Config()
                                              .downloadDataFuture(fileID);
                                          final sink =
                                              sinkProvider(fileSize: 99999999);
                                          sink.add(downFile);
                                          sink.close();
                                        });
                                    return item;
                                  }
                                  return null;
                                },
                                allowedOperations: () => [DropOperation.copy],
                                canAddItemToExistingSession: true,
                                child: DraggableWidget(
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.heavyImpact();
                                      ImagePreview.imagePreview(
                                          context, fileID, fileName);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.only(
                                          left: 12,
                                          top: 10,
                                          bottom: 10,
                                          right: 10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.11,
                                      child: Row(
                                        children: [
                                          Container(
                                              margin: EdgeInsets.only(right: 8),
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
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              fileName.length > 20
                                                  ? '${fileName.substring(0, 20)}...'
                                                  : fileName,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          RotatedBox(
                                            quarterTurns: 1,
                                            child: Text(
                                              "${isKB ? fileSize.toStringAsFixed(1) : fileSize.toStringAsFixed(2)} ${isKB ? "KB" : "MB"}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Color.fromRGBO(
                                                    0, 0, 0, 0.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
        ),
      ),
    );
  }
}
