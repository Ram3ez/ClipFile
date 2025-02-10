import 'package:flutter/material.dart';
import 'package:clipfile/config.dart';

class FileProvider extends ChangeNotifier {
  static late Future? _fileList;

  Future? get fileList => _fileList;

  FileProvider._();

  factory FileProvider() {
    _fileList = Config().listFiles();
    return FileProvider._();
  }

  void update() async {
    _fileList = Config().listFiles();

    notifyListeners();
  }
}
