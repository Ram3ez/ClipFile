import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clipfile/providers/discovery_provider.dart';
import 'package:clipfile/services/transfer_manager.dart';
import 'package:clipfile/pages/settings_page.dart';
import 'dart:io';

class DiscoveryPage extends StatefulWidget {
  final bool isDev;
  const DiscoveryPage({super.key, this.isDev = false});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  @override
  void initState() {
    super.initState();
    // Auto-scan on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryProvider>().startScanning();
    });
  }

  @override
  Widget build(BuildContext context) {
    final discoveryProvider = context.watch<DiscoveryProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Discovery",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              discoveryProvider.clearPeers();
              discoveryProvider.startScanning();
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
        centerTitle: false,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      body: discoveryProvider.peers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (discoveryProvider.isScanning)
                    const CircularProgressIndicator(color: Colors.white70)
                  else
                    const Icon(Icons.devices_other_rounded,
                        size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    discoveryProvider.isScanning
                        ? "Scanning for devices..."
                        : "No devices found. Start scanning.",
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: discoveryProvider.peers.length,
              itemBuilder: (context, index) {
                final peer = discoveryProvider.peers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  color: Theme.of(context).secondaryHeaderColor,
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _showSendOptions(context, peer),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(_getPlatformIcon(peer['os']),
                            color: Colors.white),
                      ),
                      title: Text(
                        peer['name'] ?? 'Unknown Device',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "${peer['type']} | ${peer['ip'] ?? peer['id']}",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white24, size: 16),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getPlatformIcon(String? os) {
    if (os == null) return Icons.devices;
    switch (os.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'windows':
        return Icons.laptop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.terminal;
      default:
        return Icons.devices;
    }
  }

  void _showSendOptions(BuildContext context, Map<String, dynamic> peer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // For custom shape/styling
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              "Send to ${peer['name']}",
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              context,
              icon: Icons.copy_rounded,
              title: "Send Clipboard Content",
              subtitle: "Instantly share your current clipboard",
              onTap: () async {
                Navigator.pop(context);
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data != null &&
                    data.text != null &&
                    data.text!.isNotEmpty) {
                  _handleSendText(peer, data.text!);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Clipboard is empty!")),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              context,
              icon: Icons.file_present_rounded,
              title: "Send a File",
              subtitle: "Select and send any file from your device",
              onTap: () async {
                Navigator.pop(context);
                _handleSendFile(peer);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        onTap: onTap,
      ),
    );
  }

  void _handleSendText(Map<String, dynamic> peer, String text) async {
    _showLoadingDialog("Sending text...");

    bool success = await TransferManager().sendText(
      text: text,
      targetIp: peer['ip'],
      targetPort: peer['port'],
    );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Sent successfully!" : "Failed to send.",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).secondaryHeaderColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
    }
  }

  void _handleSendFile(Map<String, dynamic> peer) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      _showLoadingDialog("Sending ${result.files.single.name}...");

      bool success = await TransferManager().sendFile(
        file: file,
        targetIp: peer['ip'],
        targetPort: peer['port'],
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? "File sent!" : "Failed to send file.",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
