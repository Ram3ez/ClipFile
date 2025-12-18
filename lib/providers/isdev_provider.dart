import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A provider that manages the "Developer Mode" setting.
///
/// Persists the setting using Hive.
class IsdevProvider extends ChangeNotifier {
  static late bool _isDev;

  bool get isDev => _isDev;
  static Box<String> settingsBox = Hive.box("settings");

  IsdevProvider._();

  /// Factory constructor initializes the state from local storage.
  factory IsdevProvider() {
    _isDev = settingsBox.get("isDev") == "true";
    return IsdevProvider._();
  }

  /// Updates the developer mode setting and persists it.
  Future<void> update(bool isDev) async {
    _isDev = isDev;
    try {
      await settingsBox.put("isDev", isDev.toString());
    } catch (e) {
      debugPrint("Failed to save isDev setting: $e");
      rethrow;
    }

    notifyListeners();
  }
}
