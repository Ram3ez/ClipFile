import 'dart:io';

import 'package:clipfile/components/clipboard_container.dart';
import 'package:clipfile/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:clipfile/providers/clip_data_provider.dart';
import 'package:clipfile/config.dart';

/// The main page for displaying and interacting with clipboard content.
class ClipboardPage extends StatefulWidget {
  final bool isDev;
  const ClipboardPage({super.key, this.isDev = false});

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final config = Config();

  // Future kept for initial load, though Provider might handle it.
  late Future<String> clipData;

  @override
  void initState() {
    super.initState();
    clipData = config.getData(context, widget.isDev);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          "ClipBoard",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (Platform.isWindows)
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              iconSize: 25,
              color: Colors.white,
            ),
          ),
        ],
        centerTitle: false,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      body: Consumer<ClipDataProvider>(
        builder: (context, state, child) => ClipboardContainer(
          future: state.clipData,
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    var data = await Config().getData(context);
    if (mounted) {
      context.read<ClipDataProvider>().update(data);
    }
  }
}
