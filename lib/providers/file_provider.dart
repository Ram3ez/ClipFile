import 'package:appwrite/models.dart' hide File;
import 'package:flutter/material.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/services/discovery_service.dart';
import 'package:clipfile/services/transfer_manager.dart';
import 'package:clipfile/services/transfer_server.dart';
import 'dart:io';

/// A provider that manages the list of files fetched from Appwrite storage.
class FileProvider extends ChangeNotifier {
  Future<FileList?>? _fileList;

  Future<FileList?>? get fileList => _fileList;

  // Hybrid Transfer Services
  final DiscoveryService _discoveryService = DiscoveryService();

  // State for discovered peers (not fully wired to UI yet)
  List<Map<String, dynamic>> discoveredPeers = [];

  FileProvider(bool isDev) {
    _fileList = Config().listFiles(null, isDev);
  }

  /// Initialize Hybrid services
  Future<void> initHybridServices() async {
    await _discoveryService.init();

    // Start scanning for peers
    _discoveryService.startScanning();
  }

  /// Sends a file using the hybrid manager.
  Future<void> sendFile(File file) async {
    // TODO: Select target peer from UI.
    // For now, we default to Relay since we don't have a Peer Picker UI yet.
    // To test hybrid, we would need a discovered peer IP.

    await TransferManager()
        .sendFile(file: file); // Defaults to Relay if IP not provided
    await update(); // Refresh list to show upload if it went via Relay
  }

  /// Refreshes the list of files from the server.
  Future<void> update() async {
    _fileList = Config().listFiles();
    await _fileList;
    notifyListeners();
  }
}
