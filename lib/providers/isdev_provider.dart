import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class IsdevProvider extends ChangeNotifier {
  static late bool _isDev;

  bool get isDev => _isDev;
  static Box<String> settingsBox = Hive.box("settings");

  IsdevProvider._();

  factory IsdevProvider() {
    _isDev = settingsBox.get("isDev") == "true" ? true : false;
    return IsdevProvider._();
  }

  void update(bool isDev) async {
    _isDev = isDev;
    try {
      await settingsBox.put("isDev", isDev.toString());
    } on AppwriteException {
      rethrow;
    }

    notifyListeners();
  }
}
