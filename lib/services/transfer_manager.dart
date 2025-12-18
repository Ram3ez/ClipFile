import 'dart:io';

import 'package:clipfile/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart' hide File;

/// Manages the file transfer logic, selecting the best available channel (LAN or Relay).
class TransferManager {
  final Dio _dio = Dio();

  // Singleton pattern for easy access
  static final TransferManager _instance = TransferManager._internal();
  factory TransferManager() => _instance;
  TransferManager._internal();

  /// Attempts to send a file to a target device.
  ///
  /// [file] The file to send.
  /// [targetIp] The local IP of the target device (discovered via BLE).
  /// [targetPort] The port the target's TransferServer is listening on.
  /// [useRelay] Force relay usage or fallback preference.
  Future<bool> sendFile({
    required File file,
    String? targetIp,
    int? targetPort,
  }) async {
    bool uploadSuccess = false;

    // Lane 1: Try Local LAN Transfer if connection info is available
    if (targetIp != null && targetPort != null) {
      if (kDebugMode)
        print("Attempting LAN transfer to $targetIp:$targetPort...");
      uploadSuccess = await _sendViaLan(file, targetIp, targetPort);
    }

    // Lane 2: Fallback to Appwrite Relay
    if (!uploadSuccess) {
      if (kDebugMode)
        print(
            "LAN transfer failed or not available. Switching to Appwrite Relay...");
      uploadSuccess = await _sendViaRelay(file);
    }

    return uploadSuccess;
  }

  /// Tries to send file via HTTP POST to the local server.
  Future<bool> _sendViaLan(File file, String ip, int port) async {
    try {
      String fileName = file.path.split(Platform.pathSeparator).last;

      // Create FormData
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      // Simple implementation: Stream the file directly as body or use FormData
      // Our server expects raw stream for one endpoint, but let's stick to standard POST
      // Adjusting server to read stream is efficient, but Dio sends headers.
      // For the server we wrote: `request.read().pipe(sink)` reads the *entire body* as the file.
      // So sending raw bytes is best.

      final length = await file.length();

      await _dio.post('http://$ip:$port/upload',
          data: file.openRead(),
          options: Options(
            headers: {
              Headers.contentLengthHeader: length, // Set content-length
              'x-filename': fileName, // Custom header for filename
            },
            contentType: 'application/octet-stream', // Binary stream
          ), onSendProgress: (sent, total) {
        if (kDebugMode && total > 0) {
          print("LAN Progress: ${(sent / total * 100).toStringAsFixed(1)}%");
        }
      });

      return true;
    } catch (e) {
      print("LAN Transfer Error: $e");
      return false;
    }
  }

  /// Fallback: Upload to Appwrite Storage.
  Future<bool> _sendViaRelay(File file) async {
    try {
      String fileName = file.path.split(Platform.pathSeparator).last;

      // Use existing Config logic
      var result = await Config().insertData(
        path: file.path,
        name: fileName,
        // context is null here, handled by logs/toasts ideally, or passed down
      );

      return result != null;
    } catch (e) {
      print("Relay Transfer Error: $e");
      return false;
    }
  }

  Future<bool> sendText({
    required String text,
    String? targetIp,
    int? targetPort,
  }) async {
    bool uploadSuccess = false;

    if (targetIp != null && targetPort != null) {
      try {
        await _dio.post('http://$targetIp:$targetPort/upload-text',
            data: text, options: Options(contentType: 'text/plain'));
        uploadSuccess = true;
      } catch (e) {
        print("LAN Text Transfer Error: $e");
      }
    }

    if (!uploadSuccess) {
      try {
        await Config().updateData(text);
        uploadSuccess = true;
      } catch (e) {
        print("Relay Text Transfer Error: $e");
      }
    }

    return uploadSuccess;
  }
}
