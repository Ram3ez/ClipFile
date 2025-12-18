import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart'; // Added this import

/// A local HTTP server used for high-speed LAN file transfers.
///
/// It listens for POST requests containing file streams and saves them locally.
class TransferServer {
  HttpServer? _server;
  int? _portInternal;
  int? get port => _portInternal;

  final _transferController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTransferComplete =>
      _transferController.stream;

  final _progressController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onProgress => _progressController.stream;

  TransferServer();

  /// Starts the local HTTP server.
  /// Returns the port it is listening on.
  Future<int> start() async {
    final router = Router();

    // Define endpoints
    router.post('/upload', _handleUpload); // Changed to tear-off
    router.post('/upload-text', _handleTextUpload); // Changed to tear-off

    final handler =
        Pipeline().addMiddleware(logRequests()).addHandler(router.call);

    // Listen on any available network interface (0.0.0.0)
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    _portInternal = _server!.port;

    if (kDebugMode) {
      debugPrint('TransferServer running on port $_portInternal');
    }

    return _portInternal!;
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  /// Handles the file upload request.
  /// Expects a raw binary stream or multipart (simplified to raw for this proof-of-concept).
  Future<Response> _handleUpload(Request request) async {
    try {
      final filename =
          request.headers['x-filename'] ?? 'received_file_${const Uuid().v4()}';

      // Determine save directory
      Directory? saveDir;
      if (Platform.isWindows) {
        saveDir = await getDownloadsDirectory();
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }

      if (saveDir == null) {
        debugPrint("Error: Could not determine save directory");
        return Response.internalServerError(body: "Save directory not found");
      }

      // Ensure directory exists
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Construct file path safely
      final filePath = "${saveDir.path}${Platform.pathSeparator}$filename";
      final file = File(filePath);

      if (kDebugMode) {
        debugPrint('Receiving file: $filename -> $filePath');
      }

      // Efficiently pipe the request stream to the file
      final stopwatch = Stopwatch()..start();
      int totalBytesNum = 0;
      final totalToReceive = request.contentLength ?? 0;

      final sink = file.openWrite();
      await sink.addStream(request.read().map((data) {
        totalBytesNum += data.length;

        // Report progress
        if (totalToReceive > 0) {
          _progressController.add({
            "filename": filename,
            "progress": totalBytesNum / totalToReceive,
            "received": totalBytesNum,
            "total": totalToReceive,
          });
        }

        return data;
      }));
      await sink.close();
      stopwatch.stop();

      final durationSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      final speedMBps = durationSeconds > 0
          ? (totalBytesNum / (1024 * 1024)) / durationSeconds
          : totalBytesNum / (1024 * 1024);

      if (kDebugMode) {
        debugPrint(
            'File saved successfully to: ${file.path} (${(totalBytesNum / 1024).toStringAsFixed(2)} KB, ${speedMBps.toStringAsFixed(2)} MB/s)');
      }

      _transferController.add({
        "filename": filename,
        "path": file.path,
        "success": true,
        "type": "file",
        "size": totalBytesNum,
        "speed": speedMBps,
      });

      return Response.ok('File received successfully');
    } catch (e, stack) {
      debugPrint("Upload failed with error: $e");
      debugPrint("Stack trace: $stack");
      _transferController
          .add({"filename": "unknown", "success": false, "type": "file"});
      return Response.internalServerError(body: "Upload failed: $e");
    }
  }

  Future<Response> _handleTextUpload(Request request) async {
    try {
      final text = await request.readAsString();

      if (kDebugMode) {
        debugPrint('Text received: $text');
      }

      // In a real app, we might update the ClipDataProvider via a global key or stream.
      // For now, let's just log and trigger success callback.
      _transferController.add({"text": text, "success": true, "type": "text"});

      return Response.ok('Text received');
    } catch (e) {
      debugPrint("Text upload failed: $e");
      return Response.internalServerError(body: "Failed to receive text");
    }
  }
}
