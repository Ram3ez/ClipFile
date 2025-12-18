import 'package:clipfile/components/custom_button.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/main.dart';
import 'package:clipfile/pages/Authentication/login_page.dart';
import 'package:clipfile/providers/isdev_provider.dart';
import 'package:clipfile/secrets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

/// A page that allows the user to choose between Logging in or entering Developer Mode.
class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool _showLogin = false;
  bool _devMode = false;

  final Box<String> settingsBox = Hive.box("settings");

  @override
  Widget build(BuildContext context) {
    _devMode = context.watch<IsdevProvider>().isDev;

    if (_showLogin) {
      _initializeLoginConfig();
      return LoginPage();
    } else if (_devMode) {
      settingsBox.put("isDev", _devMode.toString());
      return const MainApp();
    }

    return _buildSelectionScreen(context);
  }

  void _initializeLoginConfig() {
    settingsBox.put("documentID", "");
    settingsBox.put("bucketID", "");

    Config.documentID = "";
    Config.bucketID = "";

    settingsBox.put("endpoint", Secrets.endpoint);
    settingsBox.put("projectID", Secrets.projectID);
    settingsBox.put("databaseID", Secrets.databaseID);
    settingsBox.put("collectionID", Secrets.collectionID);
    settingsBox.put("attributeName", Secrets.attributeName);

    Config.endpoint = Secrets.endpoint;
    Config.projectID = Secrets.projectID;
    Config.databaseID = Secrets.databaseID;
    Config.collectionID = Secrets.collectionID;
    Config.attributeName = Secrets.attributeName;

    Config(); // Initialize config instance
  }

  Widget _buildSelectionScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: CustomButton(
                onPress: () => setState(() => _showLogin = true),
                buttonText: "Login",
                long: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: CustomButton(
                onPress: () {
                  _devMode = true;
                  context.read<IsdevProvider>().update(true);
                },
                buttonText: "Developer Mode",
                long: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
