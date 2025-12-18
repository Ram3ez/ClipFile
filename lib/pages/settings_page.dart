import 'dart:io';
import 'package:clipfile/components/custom_banner.dart';
import 'package:clipfile/components/custom_button.dart';
import 'package:clipfile/components/custom_text_field.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/providers/auth_provider.dart';
import 'package:clipfile/providers/isdev_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:clipfile/providers/local_only_provider.dart';
import 'package:window_manager/window_manager.dart';

/// The settings page for configuring app preferences and Appwrite connection details.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Map<String, TextEditingController> _controllers = {};
  final Box<String> settingsBox = Hive.box("settings");
  final updater = ShorebirdUpdater();

  bool onTop = Config.alwaysOnTop == "false" ? false : true;
  bool fixedSize = Config.fixedSize == "true" ? true : false;
  bool isLocal = Config.isLocal;
  String userName = "";

  @override
  void initState() {
    super.initState();
    _getUserName();
    _initControllers();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _getUserName() async {
    try {
      userName = (await context.read<AuthProvider>().user)?.name ?? "";
    } catch (_) {
      userName = "";
    }
    if (mounted) setState(() {});
  }

  void _initControllers() {
    _controllers['endpoint'] = TextEditingController();
    _controllers['projectID'] = TextEditingController();
    _controllers['databaseID'] = TextEditingController();
    _controllers['documentID'] = TextEditingController();
    _controllers['collectionID'] = TextEditingController();
    _controllers['attributeName'] = TextEditingController();
    _controllers['bucketID'] = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    bool isDev = context.watch<IsdevProvider>().isDev;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
                Navigator.of(context).pop();
              },
              color: Colors.white,
              iconSize: 30,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: !isDev ? _buildUserView(context) : _buildDevView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildUserView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Current User: $userName",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        if (Platform.isWindows) ...[
          _buildCheckboxOption(
            context,
            "Always on Top",
            onTop,
            (val) async {
              await settingsBox.put("onTop", val.toString());
              await WindowManager.instance.setAlwaysOnTop(val);
              setState(() {
                Config.alwaysOnTop = val.toString();
                onTop = val;
              });
            },
          ),
          const SizedBox(height: 5),
          _buildCheckboxOption(
            context,
            "Fixed Size",
            fixedSize,
            (val) async {
              await settingsBox.put("fixedSize", val.toString());
              if (val) {
                await WindowManager.instance.setSize(const Size(400, 730));
                await WindowManager.instance.setResizable(false);
              } else {
                await WindowManager.instance.setResizable(true);
              }
              setState(() {
                Config.fixedSize = val.toString();
                fixedSize = val;
              });
            },
          ),
          const SizedBox(height: 20),
        ],
        if (userName.isEmpty) ...[
          const SizedBox(height: 5),
          _buildCheckboxOption(
            context,
            "Local Only Mode",
            isLocal,
            (val) async {
              await context.read<LocalOnlyProvider>().update(val);
              setState(() {
                isLocal = val;
              });
            },
          ),
          const SizedBox(height: 20),
        ],
        if (updater.isAvailable) ...[
          _buildUpdateButton(context),
          const SizedBox(height: 20),
        ],
        CustomButton(
          onPress: () async {
            if (isLocal) {
              // OptionsPage watches LocalOnlyProvider and will rebuild to show selection screen
              await context.read<LocalOnlyProvider>().update(false);
              if (context.mounted) Navigator.of(context).pop();
            } else {
              _handleLogout(context);
            }
          },
          buttonText: isLocal ? "Exit Local Only Mode" : "Log Out",
          long: true,
        ),
      ],
    );
  }

  Widget _buildDevView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Platform.isWindows ? 15 : 30),
              _buildSettingsField(
                  "ENDPOINT", "endpoint", "https://cloud.appwrite.io/v1"),
              _buildSettingsField("PROJECT ID", "projectID", ""),
              _buildSettingsField("DATABASE ID", "databaseID", ""),
              _buildSettingsField("DOCUMENT ID", "documentID", ""),
              _buildSettingsField("COLLECTION ID", "collectionID", ""),
              _buildSettingsField(
                  "ATTRIBUTE NAME", "attributeName", "clipboard"),
              _buildSettingsField("BUCKET ID", "bucketID", ""),
              if (Platform.isWindows) ...[
                _buildCheckboxOption(context, "Always on Top", onTop,
                    (val) async {
                  await settingsBox.put("onTop", val.toString());
                  await WindowManager.instance.setAlwaysOnTop(val);
                  setState(() => onTop = val);
                  Config.alwaysOnTop = val.toString();
                }),
                _buildCheckboxOption(context, "Fixed Size", fixedSize,
                    (val) async {
                  await settingsBox.put("fixedSize", val.toString());
                  if (val) {
                    await WindowManager.instance.setSize(const Size(400, 730));
                    await WindowManager.instance.setResizable(false);
                  } else {
                    await WindowManager.instance.setResizable(true);
                  }
                  setState(() => fixedSize = val);
                  Config.fixedSize = val.toString();
                }),
              ],
              if (userName.isEmpty) ...[
                _buildCheckboxOption(context, "Local Only Mode", isLocal,
                    (val) async {
                  await context.read<LocalOnlyProvider>().update(val);
                  setState(() => isLocal = val);
                }),
              ],
              const Spacer(),
              if (updater.isAvailable) _buildUpdateButton(context),
              if (updater.isAvailable) const Spacer(),
              CustomButton(
                onPress: () async {
                  context.read<IsdevProvider>().update(false);
                  await Future.delayed(const Duration(milliseconds: 400));
                  if (context.mounted) Navigator.of(context).pop();
                },
                buttonText: "Exit Dev Mode",
                long: true,
              ),
              const SizedBox(height: 10),
              if (updater.isAvailable) const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsField(String label, String key, String defaultVal) {
    return CustomTextField(
      label: label,
      hint: settingsBox.get(key) ?? defaultVal,
      controller: _controllers[key]!,
      onChanged: () async {
        if (_controllers[key]!.text.isNotEmpty) {
          await settingsBox.put(key, _controllers[key]!.text);
          // Manually update config and reinit client
          switch (key) {
            case "endpoint":
              Config.endpoint = _controllers[key]!.text;
              break;
            case "projectID":
              Config.projectID = _controllers[key]!.text;
              break;
            case "databaseID":
              Config.databaseID = _controllers[key]!.text;
              break;
            case "documentID":
              Config.documentID = _controllers[key]!.text;
              break;
            case "collectionID":
              Config.collectionID = _controllers[key]!.text;
              break;
            case "attributeName":
              Config.attributeName = _controllers[key]!.text;
              break;
            case "bucketID":
              Config.bucketID = _controllers[key]!.text;
              break;
          }
          Config().init(); // Force re-init of client
        } else {
          await settingsBox.put(key, defaultVal.isNotEmpty ? defaultVal : "");
        }
        _controllers[key]!.clear();
        setState(() {});
      },
    );
  }

  Widget _buildCheckboxOption(BuildContext context, String label, bool value,
      Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(4),
      ),
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              activeColor: Theme.of(context).secondaryHeaderColor,
              value: value,
              onChanged: (val) => onChanged(val ?? false),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(BuildContext context) {
    return CustomButton(
      onPress: () async => _handleUpdate(context),
      buttonText: "Check For Updates",
      long: true,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthProvider>().logout(context);
    final keysToDelete = [
      "documentID",
      "collectionID",
      "projectID",
      "bucketID",
      "attributeName",
      "endpoint",
      "databaseID"
    ];

    settingsBox.put("documentID", "");
    settingsBox.put("bucketID", "");
    settingsBox.deleteAll(keysToDelete);

    Config.bucketID = "";
    Config.documentID = "";
    Config.collectionID = "";
    Config.databaseID = "";
    Config.projectID = "";

    await Future.delayed(const Duration(milliseconds: 400));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _handleUpdate(BuildContext context) async {
    // ... Implementation of update logic from original file ...
    final status = await updater.checkForUpdate();
    final currentPatch = await updater.readNextPatch();

    if (!context.mounted) return;

    if (status == UpdateStatus.outdated) {
      _showUpdateBanner(context, "Downloading.... ", loading: true);
      try {
        await updater.update();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        ScaffoldMessenger.of(context).showMaterialBanner(
            CustomBanner.customBanner("Updated Successfully", context, true));
      } on UpdateException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    } else {
      _showUpdateBanner(
          context,
          currentPatch != null
              ? "Already on latest Patch: ${currentPatch.number}"
              : "No Patches found");
    }
  }

  void _showUpdateBanner(BuildContext context, String message,
      {bool loading = false}) {
    ScaffoldMessenger.of(context)
        .showMaterialBanner(MaterialBanner(content: Text(message), actions: [
      if (loading)
        const Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: SizedBox(
              height: 14, width: 14, child: CircularProgressIndicator()),
        )
      else
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
          icon: const Icon(Icons.close),
        )
    ]));
  }
}
