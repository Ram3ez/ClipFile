import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clipfile/config.dart';

/// A provider that manages the "Local Only" mode setting.
class LocalOnlyProvider extends ChangeNotifier {
  static late bool _isLocal;

  bool get isLocal => _isLocal;
  static Box<String> settingsBox = Hive.box("settings");

  LocalOnlyProvider._();

  /// Factory constructor initializes the state from local storage.
  factory LocalOnlyProvider() {
    _isLocal = settingsBox.get("isLocal") == "true";
    return LocalOnlyProvider._();
  }

  /// Updates the Local Only mode setting and persists it.
  Future<void> update(bool isLocal) async {
    _isLocal = isLocal;
    try {
      await settingsBox.put("isLocal", isLocal.toString());
      Config.isLocal = isLocal;

      // Re-initialize config (will skip Appwrite if local)
      Config().init();
    } catch (e) {
      debugPrint("Failed to save isLocal setting: $e");
      rethrow;
    }

    notifyListeners();
  }
}
