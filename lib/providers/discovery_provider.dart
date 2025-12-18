import 'dart:async';

import 'package:clipfile/services/transfer_server.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clipfile/services/discovery_service.dart';

class DiscoveryProvider extends ChangeNotifier {
  final DiscoveryService _service = DiscoveryService();

  bool get isScanning =>
      _service.isScanning; // Need to expose getter in service or track here
  bool get isAdvertising =>
      _service.isAdvertising; // Need to expose getter in service or track here

  List<Map<String, dynamic>> _peers = [];
  List<Map<String, dynamic>> get peers => _peers;

  final TransferServer _transferServer = TransferServer();

  // Stream for transfer notifications (for popups)
  final _transferReceivedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTransferReceived =>
      _transferReceivedController.stream;

  Stream<Map<String, dynamic>> get onProgress => _transferServer.onProgress;

  DiscoveryProvider() {
    _init();
  }

  Future<void> _init() async {
    await _service.init();

    // Start local server and get port
    final port = await _transferServer.start();

    // Auto-start advertising with the server port
    await _service.startAdvertising(port: port);

    _transferServer.onTransferComplete.listen((data) async {
      if (data['success'] == true) {
        if (data['type'] == 'text') {
          print('Auto-updating clipboard with: ${data['text']}');
          await Clipboard.setData(ClipboardData(text: data['text']));
          _transferReceivedController.add(data);
        } else {
          print('File received: ${data['filename']}');
          _transferReceivedController.add(data);
        }
      }
    });

    notifyListeners();

    _service.peers.listen((peer) {
      // Basic dedup
      final index = _peers.indexWhere(
          (p) => p['id'] == peer['id'] || p['name'] == peer['name']);
      if (index != -1) {
        _peers[index] = peer;
      } else {
        _peers.add(peer);
      }
      notifyListeners();
    });
  }

  void clearPeers() {
    _peers.clear();
    notifyListeners();
  }

  Future<void> startScanning() async {
    await _service.startScanning();
    notifyListeners();
  }

  Future<void> stopScanning() async {
    await _service.stopScanning();
    notifyListeners();
  }

  Future<void> startAdvertising() async {
    // We already auto-start in _init with the port, but this allows manual restart
    await _service.startAdvertising(port: _transferServer.port);
    notifyListeners();
  }

  Future<void> stopAdvertising() async {
    await _service.stopAdvertising();
    notifyListeners();
  }
}
