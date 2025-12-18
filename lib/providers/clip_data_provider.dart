import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:clipfile/config.dart';

/// A provider class that manages the specialized "Clip Data" (text content)
/// synchronized with the Appwrite backend.
class ClipDataProvider extends ChangeNotifier {
  // Static to maintain state across re-initializations (view updates)
  static late Future<String> _clipData;

  Future<String> get clipData => _clipData;

  ClipDataProvider._();

  /// Factory constructor to initialize the data provider.
  factory ClipDataProvider(bool isDev) {
    _clipData = Config().getData(null, isDev);
    return ClipDataProvider._();
  }

  /// Updates the clipboard data locally and on the server.
  ///
  /// performs an optimistic update locally.
  Future<void> update(String text) async {
    // Optimistic local update
    _clipData = Future.value(text);
    notifyListeners();

    try {
      await Config().updateData(text);
    } on AppwriteException {
      // If update fails, we might want to revert or handle error,
      // but original code just rethrows.
      rethrow;
    }
  }
}
