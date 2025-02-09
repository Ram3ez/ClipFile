import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:clipfile/config.dart';

class ClipDataProvider extends ChangeNotifier {
  static late Future<String> _clipData;

  Future<String> get clipData => _clipData;

  ClipDataProvider._();

  factory ClipDataProvider() {
    _clipData = Config().getData();
    return ClipDataProvider._();
  }

  void update(String text) async {
    _clipData = Future.value(text);
    var data = await _clipData;
    try {
      await Config().updateData(data);
    } on AppwriteException {
      rethrow;
    }

    notifyListeners();
  }
}
