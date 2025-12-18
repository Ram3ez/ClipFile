import 'dart:async';
import 'package:clipfile/pages/Authentication/options_page.dart';
import 'package:clipfile/pages/settings_page.dart';
import 'package:clipfile/providers/auth_provider.dart';
import 'package:clipfile/providers/isdev_provider.dart';
import 'package:clipfile/secrets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'package:clipfile/providers/clip_data_provider.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/providers/file_provider.dart';
import 'package:clipfile/pages/clipboard/clipboard_button_page.dart';
import 'package:clipfile/pages/clipboard/clipboard_page.dart';
import 'package:clipfile/pages/files/files_button_page.dart';
import 'package:clipfile/pages/files/files_page.dart';
import 'package:clipfile/pages/discovery_page.dart'; // [NEW]
import 'package:clipfile/pages/discovery_button_page.dart'; // [NEW]
import 'package:clipfile/providers/discovery_provider.dart'; // [NEW]
import 'package:quick_actions/quick_actions.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:universal_io/io.dart';
import 'package:window_manager/window_manager.dart';
import 'package:open_file_plus/open_file_plus.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (_) {}

  await Hive.initFlutter();

  // Initialize 'settings' box
  Box<String> box = await Hive.openBox("settings");

  // Platform-specific initialization for Windows
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    bool isAlwaysOnTop = box.get("onTop") != "false";
    await WindowManager.instance.setAlwaysOnTop(isAlwaysOnTop);

    // Default size
    await WindowManager.instance.setSize(const Size(400, 730));

    // Handle fixed size setting
    if (box.get("fixedSize") == "true") {
      await WindowManager.instance.setResizable(false);
      await WindowManager.instance.setSize(const Size(400, 730));
    }
  }

  // Initialize default settings if they don't exist
  if (box.isEmpty) {
    box.put("onTop", "true");
    box.put("fixedSize", "false");
    box.put("endpoint", Secrets.endpoint);
    box.put("projectID", Secrets.projectID);
    box.put("databaseID", Secrets.databaseID);
    box.put("documentID", Secrets.documentID);
    box.put("collectionID", Secrets.collectionID);
    box.put("attributeName", Secrets.attributeName);
    box.put("bucketID", Secrets.bucketID);
  }

  // Initialize Appwrite configuration
  Config().init();

  // Clear temporary files on mobile platforms
  if (Platform.isAndroid || Platform.isIOS) {
    FilePicker.platform.clearTemporaryFiles();
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => AuthProvider()),
      ChangeNotifierProvider(create: (context) => IsdevProvider()),
      ChangeNotifierProvider(create: (context) => DiscoveryProvider()),
      ChangeNotifierProvider(
          create: (context) => ClipDataProvider(IsdevProvider().isDev)),
      ChangeNotifierProvider(
          create: (context) => FileProvider(IsdevProvider().isDev)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OptionsPage(),
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color.fromRGBO(142, 157, 169, 1),
        secondaryHeaderColor: const Color.fromRGBO(54, 64, 79, 1),
      ),
    ),
  ));
}

/// The main application widget.
///
/// This widget handles the main navigation layout, connection monitoring,
/// and life-cycle events.
class MainApp extends StatefulWidget {
  final bool isDev;
  const MainApp({super.key, this.isDev = false});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final StreamSubscription<InternetStatus> _subscription;
  late final AppLifecycleListener _listener;
  StreamSubscription? _fileReceivedSubscription;
  StreamSubscription? _progressSubscription;

  // Page controllers for the main content and the bottom button navigation
  static final PageController contentPageController =
      PageController(initialPage: 0);
  static final PageController buttonPageController =
      PageController(initialPage: 0);

  // Syncs the bottom button buttons with the main content view
  final bottomView = PageView(
    controller: buttonPageController,
    onPageChanged: (value) {
      contentPageController.jumpTo(buttonPageController.offset);
    },
    children: const [
      ClipButton(),
      FilesButton(),
      DiscoveryButtonPage(),
    ],
  );

  /// Checks for application updates using Shorebird.
  void _checkForUpdates() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final updater = ShorebirdUpdater();
      if (!updater.isAvailable) return;

      final status = await updater.checkForUpdate();
      if (status == UpdateStatus.outdated && mounted) {
        _showUpdateDialog();
      }
    });
  }

  void _showUpdateDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "New Update Available",
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            content: Text(
              "A new patch is ready to be installed, Please go to the settings.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Ok"),
              )
            ],
          );
        });
  }

  bool disconnected = false;

  @override
  void initState() {
    super.initState();

    // Monitor internet connection status
    _subscription = InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.disconnected) {
        disconnected = true;
        _showNoInternetDialog();
      } else if (disconnected) {
        disconnected = false;
        // Ideally we dismiss the specific dialog, but pop works for now
        // if the no-internet dialog is the top-most route.
        if (mounted) Navigator.of(context).pop();
      }
    });

    _listener = AppLifecycleListener(
      onResume: _subscription.resume,
      onPause: _subscription.pause,
      onHide: _subscription.pause,
    );

    _checkForUpdates();

    if (Platform.isIOS || Platform.isAndroid) {
      _initQuickActions();
    }

    // Listen for incoming transfers via LAN
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discoveryProvider = context.read<DiscoveryProvider>();

      _fileReceivedSubscription =
          discoveryProvider.onTransferReceived.listen((data) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (data['type'] == 'text') {
            _showClipboardSyncedSnackBar(data['text']);
          } else {
            _showFileReceivedDialog(data);
          }
        }
      });

      bool isShowingProgress = false;

      _progressSubscription =
          discoveryProvider.onProgress.listen((progressData) {
        if (!mounted || isShowingProgress) return;

        isShowingProgress = true;
        final initialFilename = progressData['filename'] ?? 'File';

        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: StreamBuilder<Map<String, dynamic>>(
                  stream: discoveryProvider.onProgress,
                  initialData: progressData,
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? {};
                    final filename = data['filename'] ?? initialFilename;
                    final progress = data['progress'] as double? ?? 0.0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Receiving $filename...",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    );
                  },
                ),
                backgroundColor: Theme.of(context).secondaryHeaderColor,
                duration: const Duration(hours: 1), // Stay until hidden
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.none,
              ),
            )
            .closed
            .then((_) => isShowingProgress = false);
      });
    });
  }

  void _showFileReceivedDialog(Map<String, dynamic> data) {
    final filename = data['filename'] ?? 'Unknown File';
    final path = data['path'];
    final speed = data['speed'] as double? ?? 0.0;
    final size = data['size'] as int? ?? 0;

    final sizeStr = size > 1024 * 1024
        ? "${(size / (1024 * 1024)).toStringAsFixed(2)} MB"
        : "${(size / 1024).toStringAsFixed(2)} KB";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.file_download_done_rounded,
                color: Colors.greenAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "File Received",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filename,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.data_usage_rounded, "Size: $sizeStr"),
            _buildInfoRow(
                Icons.speed_rounded, "Rate: ${speed.toStringAsFixed(2)} MB/s"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Dismiss",
                style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          if (path != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                OpenFile.open(path);
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text("Open File",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).secondaryHeaderColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  void _showClipboardSyncedSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Clipboard Synced",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    text.length > 50 ? "${text.substring(0, 47)}..." : text,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: "Dismiss",
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  void _showNoInternetDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return const AlertDialog(
              title: Text("No Internet Connection"),
              content: Text("Please Connect to the internet"),
            );
          });
    });
  }

  void _initQuickActions() {
    final QuickActions quickActions = const QuickActions();
    quickActions.initialize((shortcutType) {
      setState(() {
        const duration = Duration(milliseconds: 500);
        const curve = Curves.easeIn;

        if (shortcutType == 'action_main') {
          contentPageController.animateToPage(0,
              duration: duration, curve: curve);
          buttonPageController.animateToPage(0,
              duration: duration, curve: curve);
        } else if (shortcutType == "action_sec") {
          contentPageController.animateToPage(1,
              duration: duration, curve: curve);
          buttonPageController.animateToPage(1,
              duration: duration, curve: curve);
        } else if (shortcutType == "action_ter") {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()));
        }
      });
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'action_main', localizedTitle: 'ClipBoard'),
      const ShortcutItem(type: 'action_sec', localizedTitle: 'Files'),
      const ShortcutItem(type: "action_ter", localizedTitle: "Settings"),
    ]);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _fileReceivedSubscription?.cancel();
    _progressSubscription?.cancel();
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Column(
        children: [
          // Main Content Area
          Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                color: Theme.of(context).primaryColor,
              ))),
              height: MediaQuery.of(context).size.height * 0.76,
              child: PageView(
                controller: contentPageController,
                onPageChanged: (value) {
                  buttonPageController.jumpTo(contentPageController.offset);
                },
                children: [
                  ClipboardPage(isDev: widget.isDev),
                  FilesPage(isDev: widget.isDev),
                  DiscoveryPage(isDev: widget.isDev),
                ],
              )),

          // Page Indicator
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColor,
              ),
              color: Theme.of(context).primaryColor,
            ),
            height: MediaQuery.of(context).size.height * 0.05,
            child: SmoothPageIndicator(
              controller: contentPageController,
              count: 3, // [UPDATED] from 2
              onDotClicked: (index) {
                const duration = Duration(milliseconds: 500);
                const curve = Curves.easeIn;
                contentPageController.animateToPage(index,
                    duration: duration, curve: curve);
                buttonPageController.animateToPage(index,
                    duration: duration, curve: curve);
              },
              effect: ExpandingDotsEffect(
                dotColor: Colors.white,
                activeDotColor: Theme.of(context).secondaryHeaderColor,
              ),
            ),
          ),

          // Bottom Action Area
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.15,
            child: Scaffold(
              backgroundColor: Theme.of(context).primaryColor,
              body: bottomView,
            ),
          ),
        ],
      ),
    );
  }
}
