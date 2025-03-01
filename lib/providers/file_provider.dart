import 'package:flutter/material.dart';
import 'package:clipfile/config.dart';

class FileProvider extends ChangeNotifier {
  static late Future? _fileList;

  Future? get fileList => _fileList;

  FileProvider._();

  factory FileProvider(bool isDev) {
    _fileList = Config().listFiles(null, isDev);
    return FileProvider._();
  }

  Future<void> update() async {
    _fileList = Config().listFiles();
    await _fileList;
    notifyListeners();
  }
}
