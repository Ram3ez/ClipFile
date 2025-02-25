import 'dart:io';

import 'package:clipfile/components/clipboard_container.dart';
import 'package:clipfile/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:clipfile/providers/clip_data_provider.dart';
import 'package:clipfile/config.dart';

// ignore: must_be_immutable
class ClipboardPage extends StatefulWidget {
  ClipboardPage({super.key, this.isDev = false});

  late bool isDev;

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final config = Config();
  late Future<String> clipData;

  @override
  void initState() {
    super.initState();
    clipData = config.getData(context);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    /* WidgetsBinding.instance.addPersistentFrameCallback((_) {
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          content: Text("Patch Available"),
          actions: [IconButton(onPressed: () {}, icon: Icon(Icons.upgrade))]));
    }); */

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
          !Platform.isWindows
              ? SizedBox.shrink()
              : IconButton(
                  onPressed: () async {
                    var data = await Config().getData(context);
                    setState(() {
                      if (mounted) {
                        final reader = context.read<ClipDataProvider>();
                        reader.update(data);
                      }
                    });
                  },
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                  )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => SettingsPage(isDev: widget.isDev)));
              },
              icon: Icon(Icons.settings_outlined),
              iconSize: 25,
              color: Colors.white,
            ),
          ),
        ],
        centerTitle: false,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      body: /* Column(
        children: [
          SizedBox(
            height: 20,
          ), */
          Consumer<ClipDataProvider>(
        builder: (context, state, child) => ClipboardContainer(
          future: state.clipData,
        ),
      ),
      //],
      //),
    );
  }
}
