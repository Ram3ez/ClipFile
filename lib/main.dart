import 'package:clipfile/config.dart';
import 'package:clipfile/pages/settings_page.dart';
import 'package:clipfile/secrets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:clipfile/providers/clip_data_provider.dart';
import 'package:clipfile/providers/file_provider.dart';
import 'package:clipfile/pages/clipboard/clipboard_button_page.dart';
import 'package:clipfile/pages/clipboard/clipboard_page.dart';
import 'package:clipfile/pages/files/files_button_page.dart';
import 'package:clipfile/pages/files/files_page.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Box<String> _ = await Hive.openBox("settings");
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await WindowManager.instance.setAlwaysOnTop(true);
    await WindowManager.instance.setSize(const Size(370, 730));
    await WindowManager.instance.setMinimumSize(const Size(370, 730));
    await WindowManager.instance.setMaximumSize(const Size(370, 730));
  }

  if (Platform.isAndroid || Platform.isIOS) {
    FilePicker.platform.clearTemporaryFiles();
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,

    home: MainApp(), //MainApp(),
    theme: ThemeData(
      useMaterial3: true,
      primaryColor: Color.fromRGBO(142, 157, 169, 1),
      secondaryHeaderColor: Color.fromRGBO(54, 64, 79, 1),
    ),
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static PageController pageController = PageController(
    initialPage: 0,
  );

  static PageController pageController2 = PageController(
    initialPage: 0,
  );

  final pageView = PageView(
    controller: pageController,
    onPageChanged: (value) {
      pageController2.jumpTo(pageController.offset);
    },
    children: [
      ClipboardPage(),
      FilesPage(),
    ],
  );

  final bottomView = PageView(
    controller: pageController2,
    onPageChanged: (value) {
      pageController.jumpTo(pageController2.offset);
    },
    children: [
      ClipButton(),
      FilesButton(),
    ],
  );

  void initHive() async {
    Box<String> settingsBox = Hive.box("settings");
    if (settingsBox.isEmpty) {
      print("Empty");
      settingsBox.put("endpoint", Secrets.endpoint);
      settingsBox.put("projectID", Secrets.projectID);
      settingsBox.put("databaseID", Secrets.databaseID);
      settingsBox.put("documentID", Secrets.documentID);
      settingsBox.put("collectionID", Secrets.collectionID);
      settingsBox.put("attributeName", Secrets.attributeName);
      settingsBox.put("bucketID", Secrets.bucketID);
    }
  }

  @override
  void initState() {
    super.initState();
    initHive();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Config.bucketID == "" ||
          Config.collectionID == "" ||
          Config.documentID == "" ||
          Config.databaseID == "" ||
          Config.projectID == "" ||
          Config.endpoint == "" ||
          Config.attributeName == "") {
        Config().serverSettingErrorDialog(context, "Please Set Server Details");
      }
    });
    if (Platform.isIOS || Platform.isAndroid) {
      final QuickActions quickActions = const QuickActions();
      quickActions.initialize((shortcutType) {
        setState(() {
          if (shortcutType == 'action_main') {
            pageController.animateToPage(0,
                duration: Duration(milliseconds: 500), curve: Curves.easeIn);
            pageController2.animateToPage(0,
                duration: Duration(milliseconds: 500), curve: Curves.easeIn);
          } else if (shortcutType == "action_sec") {
            pageController.animateToPage(1,
                duration: Duration(milliseconds: 500), curve: Curves.easeIn);
            pageController2.animateToPage(1,
                duration: Duration(milliseconds: 500), curve: Curves.easeIn);
          }
        });
      });
      quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'action_main', localizedTitle: 'ClipBoard'),
        const ShortcutItem(
          type: 'action_sec',
          localizedTitle: 'Files',
        )
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    //var settingsBox = Hive.box("settings");

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ClipDataProvider()),
          ChangeNotifierProvider(create: (context) => FileProvider()),
        ],
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                color: Theme.of(context).primaryColor,
              ))),
              height: MediaQuery.of(context).size.height * 0.76,
              child: pageView,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                ),
                color: Theme.of(context).primaryColor,
              ),
              height: MediaQuery.of(context).size.height * 0.05,
              child: SmoothPageIndicator(
                controller: pageController,
                count: 2,
                onDotClicked: (index) {
                  pageController.animateToPage(index,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeIn);
                  pageController2.animateToPage(index,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeIn);
                },
                effect: ExpandingDotsEffect(
                  dotColor: Colors.white,
                  activeDotColor: Theme.of(context).secondaryHeaderColor,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
              child: Scaffold(
                backgroundColor: Theme.of(context).primaryColor,
                body: bottomView,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
