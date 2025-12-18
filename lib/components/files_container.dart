import 'package:appwrite/models.dart' hide Row;
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

/// A widget that displays a list of files with drag-and-drop support.
class FilesContainer extends StatefulWidget {
  const FilesContainer({
    super.key,
    required this.onDelete,
    required this.onDownload,
  });

  final Future<void> Function(String)? onDelete;
  final Stream<Uint8List> Function(String, String)? onDownload;

  @override
  State<FilesContainer> createState() => _FilesContainerState();
}

class _FilesContainerState extends State<FilesContainer> {
  /// Parses file data into a structured record for display.
  ({
    String name,
    String date,
    String time,
    double size,
    String id,
    bool isKB,
    IconData icon
  }) _parseFileData(FileList fileList, int index) {
    final file = fileList.files[index];
    final String fileName = file.name;
    double sizeVal = file.sizeOriginal / 1024;

    final DateTime fileDateTime = DateTime.parse(file.$updatedAt).toLocal();
    final bool isAM = fileDateTime.hour < 12;
    final int hour = fileDateTime.hour > 12
        ? fileDateTime.hour - 12
        : (fileDateTime.hour == 0 ? 12 : fileDateTime.hour);

    final bool isKB = sizeVal < 1000;
    if (!isKB) {
      sizeVal = sizeVal / 1024;
    }

    final String fileTime =
        "$hour:${fileDateTime.minute.toString().padLeft(2, "0")} ${isAM ? "AM" : "PM"}";
    final String fileDate =
        "${fileDateTime.day}/${fileDateTime.month}/${fileDateTime.year}";

    return (
      name: fileName,
      date: fileDate,
      time: fileTime,
      size: sizeVal,
      id: file.$id,
      isKB: isKB,
      icon: _getFileIcon(fileName),
    );
  }

  IconData _getFileIcon(String fileName) {
    if (!fileName.contains(".")) return Icons.insert_drive_file_outlined;

    final ext = fileName.split('.').last.toLowerCase();

    return switch (ext) {
      "jpg" || "heic" || "jpeg" || "png" => Icons.image_outlined,
      "mov" || "mp4" || "mkv" => Icons.movie_creation_outlined,
      "txt" => Icons.text_snippet_outlined,
      "apk" || "aab" => Icons.android_outlined,
      "ipa" => Icons.apple_outlined,
      "exe" || "msix" => Icons.window_sharp,
      "ppt" || "docx" || "xlsx" => Icons.file_copy,
      "pdf" => Icons.picture_as_pdf,
      _ => Icons.question_mark,
    };
  }

  @override
  Widget build(BuildContext context) {
    final double widthThreshold = MediaQuery.sizeOf(context).width * 0.07;
    int charLimit = widthThreshold.toInt();

    return DropRegion(
      formats: Formats.standardFormats,
      onDropOver: (DropOverEvent event) async {
        if (event.session.allowedOperations.length == 1) {
          return DropOperation.forbidden;
        }
        return DropOperation.copy;
      },
      onPerformDrop: (PerformDropEvent event) async {
        await _handleDrop(event);
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(
            color: Theme.of(context).secondaryHeaderColor,
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.all(23),
          child: Consumer<FileProvider>(
            builder: (context, state, child) => FutureBuilder<FileList?>(
              future: state.fileList,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return _buildFileList(snapshot.data!, charLimit);
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDrop(PerformDropEvent event) async {
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
        duration: const Duration(hours: 2), // Keep visible until hidden
      ));
    }

    for (var item in items) {
      var reader = item.dataReader!;
      reader.getFile(null, (file) async {
        var fileData = await file.readAll();
        if (!mounted) return;

        await Config().insertData(
          bytes: fileData,
          name: file.fileName,
          context: context,
        );

        if (mounted) {
          context.read<FileProvider>().update();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
    }
  }

  Widget _buildFileList(FileList files, int charLimit) {
    // Sort by date descending
    files.files.sort((a, b) => b.$updatedAt.compareTo(a.$updatedAt));

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LiquidPullToRefresh(
        animSpeedFactor: 2,
        showChildOpacityTransition: true,
        color: Theme.of(context).primaryColor,
        onRefresh: () async {
          if (mounted) {
            await context.read<FileProvider>().update();
          }
        },
        child: ListView.separated(
          itemCount: files.total,
          key: UniqueKey(), // Forces rebuild when list changes
          cacheExtent: 0,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final fileData = _parseFileData(files, index);
            return _buildFileItem(fileData, charLimit);
          },
        ),
      ),
    );
  }

  Widget _buildFileItem(
      ({
        String name,
        String date,
        String time,
        double size,
        String id,
        bool isKB,
        IconData icon
      }) file,
      int charLimit) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: DismissTile(
        onDelete: widget.onDelete,
        onDownload: widget.onDownload,
        fileID: file.id,
        fileName: file.name,
        child: DragItemWidget(
          dragItemProvider: (request) async =>
              _createDragItem(file.name, file.id),
          allowedOperations: () => [DropOperation.copy],
          canAddItemToExistingSession: true,
          child: DraggableWidget(
            child: InkWell(
              onTap: () {
                HapticFeedback.heavyImpact();
                ImagePreview.imagePreview(context, file.id, file.name);
              },
              child: _buildFileItemContent(file, charLimit),
            ),
          ),
        ),
      ),
    );
  }

  Future<DragItem?> _createDragItem(String name, String id) async {
    final item = DragItem(suggestedName: name);
    if (!item.virtualFileSupported) return null;

    item.addVirtualFile(
        format: Formats.zip,
        provider: (sinkProvider, progress) async {
          final downFile = await Config().downloadDataFuture(id);
          final sink =
              sinkProvider(fileSize: downFile.length); // Use actual size
          sink.add(downFile);
          sink.close();
        });
    return item;
  }

  Widget _buildFileItemContent(
      ({
        String name,
        String date,
        String time,
        double size,
        String id,
        bool isKB,
        IconData icon
      }) file,
      int charLimit) {
    final displayName = file.name.length > charLimit
        ? '${file.name.substring(0, charLimit - 3)}...'
        : file.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      height: MediaQuery.of(context).size.height * 0.11,
      child: Row(
        children: [
          Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                backgroundBlendMode: BlendMode.softLight,
              ),
              child: Icon(
                file.icon,
                color: Theme.of(context).secondaryHeaderColor,
              )),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                Text(
                  "${file.date} ${file.time}",
                  style: GoogleFonts.poppins(color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          RotatedBox(
            quarterTurns: 1,
            child: Text(
              "${file.isKB ? file.size.toStringAsFixed(1) : file.size.toStringAsFixed(2)} ${file.isKB ? "KB" : "MB"}",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color.fromRGBO(0, 0, 0, 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
