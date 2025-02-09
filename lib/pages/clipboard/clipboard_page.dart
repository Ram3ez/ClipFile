import 'package:clipfile/components/clipboard_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:clipfile/providers/clip_data_provider.dart';
import 'package:clipfile/config.dart';

class ClipboardPage extends StatefulWidget {
  const ClipboardPage({super.key});

  @override
  State<ClipboardPage> createState() => _ClipboardPageState();
}

class _ClipboardPageState extends State<ClipboardPage> {
  final config = Config();
  late Future<String> clipData;

  @override
  void initState() {
    super.initState();
    clipData = config.getData();
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
        centerTitle: false,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Consumer<ClipDataProvider>(
            builder: (context, state, child) => ClipboardContainer(
              future: state.clipData,
            ),
          ),
        ],
      ),
    );
  }
}
